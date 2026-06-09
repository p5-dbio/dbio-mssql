package DBIO::MSSQL;
our $VERSION = '0.900000';


# ABSTRACT: Microsoft SQL Server-specific schema management for DBIO

use strict;
use warnings;

use base 'DBIO::Base';

=head1 SYNOPSIS

    my $schema = MySchema->connect($dsn, $user, $pass);
    # Storage is automatically set to DBIO::MSSQL::Storage

=head1 DESCRIPTION

This class is a thin L<DBIO> subclass that automatically sets the storage
class to L<DBIO::MSSQL::Storage> when a connection is established. Load it
into your schema instead of the base L<DBIO> class when connecting to
Microsoft SQL Server databases.

For connections via L<DBD::Sybase> (including FreeTDS), see
L<DBIO::MSSQL::Storage::Sybase>.

=cut

sub connection {
  my ($self, @info) = @_;
  $self->storage_type('+DBIO::MSSQL::Storage');
  return $self->next::method(@info);
}

=method connection

    $schema->connection($dsn, $user, $pass, \%attrs);

Sets the storage type to L<DBIO::MSSQL::Storage> before delegating to the
parent C<connection> method.

=cut

=head1 SEE ALSO

=over

=item * L<DBIO::MSSQL::Storage> - MSSQL storage implementation

=item * L<DBIO::MSSQL::SQLMaker> - MSSQL SQL dialect

=item * L<DBIO::MSSQL::Storage::Sybase> - MSSQL via L<DBD::Sybase>

=item * L<DBIO> - Base ORM class

=back

=cut

1;
