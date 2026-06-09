package DBIO::MSSQL::Result;
# ABSTRACT: MSSQL-specific Result component for DBIO

use strict;
use warnings;

use base 'DBIO::Core';

__PACKAGE__->mk_classdata('_mssql_indexes' => {});

=head1 DESCRIPTION

C<DBIO::MSSQL::Result> is a DBIO Result component that adds
MSSQL-native metadata to a result class: standalone indexes, including
clustered/nonclustered hints. It is the counterpart to
L<DBIO::MySQL::Result> / L<DBIO::PostgreSQL::Result> and is read by
L<DBIO::MSSQL::DDL> when generating install DDL.

Load it with:

    package MyApp::Schema::Result::User;
    use base 'DBIO::Core';
    __PACKAGE__->load_components('MSSQL::Result');

    __PACKAGE__->table('users');

    __PACKAGE__->mssql_index('idx_users_name' => {
        columns => ['name'],
    });

    __PACKAGE__->mssql_index('idx_users_email' => {
        unique  => 1,
        kind    => 'nonclustered',
        columns => ['email'],
    });

=cut

=method mssql_index

    __PACKAGE__->mssql_index('idx_users_email' => {
        unique  => 1,
        kind    => 'nonclustered',
        columns => ['email'],
    });

Get or set the definition for a named MSSQL index. The definition
hashref accepts:

=over 4

=item C<columns> - ArrayRef of column names

=item C<unique> - set to true for a UNIQUE index

=item C<kind> - C<clustered> or C<nonclustered>

=back

=cut

sub mssql_index {
  my ($class, $name, $def) = @_;
  if ($def) {
    my $indexes = { %{ $class->_mssql_indexes } };
    $indexes->{$name} = $def;
    $class->_mssql_indexes($indexes);
  }
  return $class->_mssql_indexes->{$name};
}

=method mssql_indexes

    my $all = $class->mssql_indexes;

Returns a copy of all index definitions registered on this result class.
Consumed by L<DBIO::MSSQL::DDL>.

=cut

sub mssql_indexes {
  my ($class) = @_;
  return { %{ $class->_mssql_indexes } };
}

=seealso

=over 4

=item * L<DBIO::MSSQL::DDL> - consumes C<mssql_indexes>

=item * L<DBIO::MySQL::Result> - the MySQL counterpart

=back

=cut

1;
