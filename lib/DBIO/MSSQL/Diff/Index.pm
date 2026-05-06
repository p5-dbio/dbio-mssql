package DBIO::MSSQL::Diff::Index;
# ABSTRACT: Diff operations for MSSQL indexes
our $VERSION = '0.900000';

use strict;
use warnings;

=head1 DESCRIPTION

Index-level diff operations for MSSQL. MSSQL supports C<CREATE INDEX>,
C<DROP INDEX>, and C<CREATE INDEX ... DROP_EXISTING>.

=cut

sub new { my ($class, %args) = @_; bless \%args, $class }

sub action     { $_[0]->{action} }
sub table_name { $_[0]->{table_name} }
sub index_name { $_[0]->{index_name} }
sub index_info { $_[0]->{index_info} }

=method diff

=cut

sub diff {
  my ($class, $source, $target) = @_;
  my @ops;

  for my $table_name (sort keys %$target) {
    my $src_idxs = $source->{$table_name} // {};
    my $tgt_idxs = $target->{$table_name};

    for my $name (sort keys %$tgt_idxs) {
      my $tgt = $tgt_idxs->{$name};

      if (!exists $src_idxs->{$name}) {
        push @ops, $class->new(
          action     => 'create',
          table_name => $table_name,
          index_name => $name,
          index_info => $tgt,
        );
        next;
      }

      my $src = $src_idxs->{$name};
      my $changed = 0;
      $changed = 1 if ($src->{is_unique} // 0) != ($tgt->{is_unique} // 0);
      $changed = 1 if join(',', @{ $src->{columns} // [] })
                   ne join(',', @{ $tgt->{columns} // [] });

      if ($changed) {
        push @ops, $class->new(
          action => 'drop', table_name => $table_name,
          index_name => $name, index_info => $src,
        );
        push @ops, $class->new(
          action => 'create', table_name => $table_name,
          index_name => $name, index_info => $tgt,
        );
      }
    }
  }

  for my $table_name (sort keys %$source) {
    my $src_idxs = $source->{$table_name};
    my $tgt_idxs = $target->{$table_name} // {};
    for my $name (sort keys %$src_idxs) {
      next if exists $tgt_idxs->{$name};
      push @ops, $class->new(
        action     => 'drop',
        table_name => $table_name,
        index_name => $name,
        index_info => $src_idxs->{$name},
      );
    }
  }

  return @ops;
}

=method as_sql

=cut

sub as_sql {
  my ($self) = @_;

  if ($self->action eq 'create') {
    my $unique = $self->index_info->{is_unique} ? 'UNIQUE ' : '';
    my $kind = $self->index_info->{kind} || '';
    my $kind_sql = $kind eq 'clustered' ? 'CLUSTERED' : $kind eq 'nonclustered' ? 'NONCLUSTERED' : '';
    my $cols = join ', ',
      map { _quote_ident($_) } @{ $self->index_info->{columns} // [] };
    my $sql = sprintf 'CREATE %sINDEX %s ON %s %s%s (%s)',
      $unique,
      _quote_ident($self->index_name),
      _quote_ident($self->table_name),
      $kind_sql ? "$kind_sql " : '',
      $cols;
    return "$sql;";
  }
  return sprintf 'DROP INDEX %s ON %s;', _quote_ident($self->index_name), _quote_ident($self->table_name);
}

=method summary

=cut

sub summary {
  my ($self) = @_;
  my $prefix = $self->action eq 'create' ? '+' : '-';
  return sprintf '  %sindex: %s on %s', $prefix, $self->index_name, $self->table_name;
}

sub _quote_ident {
  my ($name) = @_;
  return $name if $name =~ /^[a-z_][a-z0-9_]*$/i;
  $name =~ s/"/""/g;
  return qq{"$name"};
}

1;
