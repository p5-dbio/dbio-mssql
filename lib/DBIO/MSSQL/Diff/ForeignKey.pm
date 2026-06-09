package DBIO::MSSQL::Diff::ForeignKey;
# ABSTRACT: Diff operations for MSSQL foreign keys

use strict;
use warnings;

use DBIO::SQL::Util qw(_quote_ident);
use DBIO::MSSQL::Diff::Util qw(is_same_fk);

=head1 DESCRIPTION

Represents a foreign key diff operation: C<ADD CONSTRAINT> or
C<DROP CONSTRAINT>. FKs on a brand-new table are created inline by
L<DBIO::MSSQL::Diff::Table>; this module handles FK changes on tables that
exist in both source and target.

FK identity is by C<constraint_name>. MSSQL has no C<ALTER> for a foreign
key, so a definition change becomes a drop-then-add pair.

=cut

sub new { my ($class, %args) = @_; bless \%args, $class }

sub action          { $_[0]->{action} }
sub table_name      { $_[0]->{table_name} }
sub constraint_name { $_[0]->{constraint_name} }
sub fk_info         { $_[0]->{fk_info} }

=method diff

    my @ops = DBIO::MSSQL::Diff::ForeignKey->diff(
        $source_fks, $target_fks, $source_tables, $target_tables,
    );

=cut

sub diff {
  my ($class, $source, $target, $source_tables, $target_tables) = @_;
  my @ops;

  for my $table_name (sort keys %$target) {
    next unless exists $source_tables->{$table_name}
             && exists $target_tables->{$table_name};

    my %src = map { $_->{constraint_name} => $_ } @{ $source->{$table_name} // [] };
    my %tgt = map { $_->{constraint_name} => $_ } @{ $target->{$table_name} // [] };

    for my $name (sort keys %tgt) {
      my $t = $tgt{$name};
      if (!exists $src{$name}) {
        push @ops, $class->new(
          action          => 'add',
          table_name      => $table_name,
          constraint_name => $name,
          fk_info         => $t,
        );
        next;
      }
      my $s = $src{$name};
      if (is_same_fk($s, $t)) {
        push @ops,
          $class->new(action => 'drop', table_name => $table_name,
            constraint_name => $name, fk_info => $s),
          $class->new(action => 'add',  table_name => $table_name,
            constraint_name => $name, fk_info => $t);
      }
    }

    for my $name (sort keys %src) {
      next if exists $tgt{$name};
      push @ops, $class->new(
        action          => 'drop',
        table_name      => $table_name,
        constraint_name => $name,
        fk_info         => $src{$name},
      );
    }
  }

  return @ops;
}

=method as_sql

=cut

sub as_sql {
  my ($self) = @_;
  my $tbl  = _quote_ident($self->table_name);
  my $name = _quote_ident($self->constraint_name);

  if ($self->action eq 'add') {
    my $info = $self->fk_info;
    my $from = join(', ', map { _quote_ident($_) } @{ $info->{from_columns} });
    my $to   = join(', ', map { _quote_ident($_) } @{ $info->{to_columns} });
    my $sql  = sprintf
      'ALTER TABLE %s ADD CONSTRAINT %s FOREIGN KEY (%s) REFERENCES %s(%s)',
      $tbl, $name, $from, _quote_ident($info->{to_table}), $to;
    $sql .= " ON DELETE $info->{on_delete}"
      if $info->{on_delete} && $info->{on_delete} ne 'NO ACTION';
    $sql .= " ON UPDATE $info->{on_update}"
      if $info->{on_update} && $info->{on_update} ne 'NO ACTION';
    return "$sql;";
  }
  return sprintf 'ALTER TABLE %s DROP CONSTRAINT %s;', $tbl, $name;
}

=method summary

=cut

sub summary {
  my ($self) = @_;
  my $prefix = $self->action eq 'add' ? '+' : '-';
  return sprintf '  %sfk: %s on %s', $prefix, $self->constraint_name, $self->table_name;
}

1;
