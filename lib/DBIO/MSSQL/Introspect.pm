package DBIO::MSSQL::Introspect;
# ABSTRACT: Introspect a Microsoft SQL Server database via information_schema

use strict;
use warnings;

use base 'DBIO::Introspect::Base';

=head1 DESCRIPTION

C<DBIO::MSSQL::Introspect> reads the live state of a Microsoft SQL Server
database via the standard SQL C<INFORMATION_SCHEMA> views. It is the
source side of the test-deploy-and-compare strategy used by
L<DBIO::MSSQL::Deploy>.

    my $intro = DBIO::MSSQL::Introspect->new(dbh => $dbh);
    my $model = $intro->model;

Model shape mirrors L<DBIO::SQLite::Introspect>:

    {
        tables       => { $name => { ... } },
        columns      => { $table => [ { ... }, ... ] },
        indexes      => { $table => { $name => { ... } } },
        foreign_keys => { $table => [ { ... }, ... ] },
    }

=cut

use DBIO::MSSQL::Introspect::Tables;
use DBIO::MSSQL::Introspect::Columns;
use DBIO::MSSQL::Introspect::Indexes;
use DBIO::MSSQL::Introspect::ForeignKeys;

sub schema { $_[0]->{schema} // 'dbo' }

=attr schema

Schema name to introspect. Defaults to C<dbo>.

=cut

sub _build_model {
  my ($self) = @_;
  my $dbh    = $self->dbh;
  my $schema = $self->schema;

  my $tables  = DBIO::MSSQL::Introspect::Tables->fetch($dbh, $schema);
  my $columns = DBIO::MSSQL::Introspect::Columns->fetch($dbh, $schema, $tables);
  my $indexes = DBIO::MSSQL::Introspect::Indexes->fetch($dbh, $schema, $tables);
  my $fks     = DBIO::MSSQL::Introspect::ForeignKeys->fetch($dbh, $schema, $tables);

  return {
    tables       => $tables,
    columns      => $columns,
    indexes      => $indexes,
    foreign_keys => $fks,
  };
}

=head1 NORMALIZED INTROSPECTION CONTRACT

The methods below implement the L<DBIO::Introspect::Base> contract as thin
reads over the native L</model>, so this introspector can serve as a
high-fidelity source for L<DBIO::Generate> (mirrors
L<DBIO::MySQL::Introspect> / L<DBIO::PostgreSQL::Introspect>). Keys are
table names as produced by L<DBIO::MSSQL::Introspect::Tables>.

=cut

=method table_keys

=cut

sub table_keys {
  my ($self) = @_;
  return [ sort keys %{ $self->model->{tables} } ];
}

=method table_columns

=cut

sub table_columns {
  my ($self, $key) = @_;
  my $cols = $self->model->{columns}{$key} // [];
  return [ map { $_->{column_name} } @$cols ];
}

=method table_columns_info

=cut

sub table_columns_info {
  my ($self, $key) = @_;
  my $cols = $self->model->{columns}{$key} // [];
  my %info;
  for my $col (@$cols) {
    $info{ $col->{column_name} } = {
      data_type         => $col->{data_type},
      size              => $col->{size},
      is_nullable       => $col->{not_null} ? 0 : 1,
      default_value     => $col->{default_value},
      is_auto_increment => $col->{is_identity} ? 1 : 0,
    };
  }
  return \%info;
}

=method table_pk_info

=cut

sub table_pk_info {
  my ($self, $key) = @_;
  my $cols = $self->model->{columns}{$key} // [];
  return [
    map  { $_->{column_name} }
    sort { ($a->{pk_position} // 0) <=> ($b->{pk_position} // 0) }
    grep { $_->{is_pk} } @$cols
  ];
}

=method table_uniq_info

=cut

sub table_uniq_info {
  my ($self, $key) = @_;
  my $indexes = $self->model->{indexes}{$key} // {};

  # The PK is backed by a unique index; don't report it as a separate
  # unique constraint. Identify it by an exact column-set match.
  my %pk = map { $_ => 1 } @{ $self->table_pk_info($key) };
  my @pk = keys %pk;

  my @uniq;
  for my $idx_name (sort keys %$indexes) {
    my $idx = $indexes->{$idx_name};
    next unless $idx->{is_unique};
    my $cols = $idx->{columns} // [];
    next if @pk && @$cols == @pk && !grep { !$pk{$_} } @$cols;
    push @uniq, [ $idx_name => $cols ];
  }
  return \@uniq;
}

=method table_fk_info

=cut

sub table_fk_info {
  my ($self, $key) = @_;
  my $fks = $self->model->{foreign_keys}{$key} // [];
  return [
    map {
      {
        local_columns  => $_->{from_columns},
        remote_table   => $_->{to_table},
        remote_schema  => undef,
        remote_columns => $_->{to_columns},
        attrs          => {
          on_delete => $_->{on_delete},
          on_update => $_->{on_update},
        },
      }
    } @$fks
  ];
}

=method table_is_view

=cut

sub table_is_view {
  my ($self, $key) = @_;
  my $tbl = $self->model->{tables}{$key} // {};
  return ($tbl->{kind} // '') eq 'view' ? 1 : 0;
}

=seealso

=over

=item * L<DBIO::MSSQL::Deploy> - uses this class for test-deploy-and-compare

=item * L<DBIO::MSSQL::Diff> - compares two models produced by this class

=back

=cut

1;
