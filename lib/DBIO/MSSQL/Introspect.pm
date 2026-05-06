package DBIO::MSSQL::Introspect;
# ABSTRACT: Introspect a Microsoft SQL Server database via information_schema
our $VERSION = '0.900000';

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

=seealso

=over

=item * L<DBIO::MSSQL::Deploy> - uses this class for test-deploy-and-compare

=item * L<DBIO::MSSQL::Diff> - compares two models produced by this class

=back

=cut

1;
