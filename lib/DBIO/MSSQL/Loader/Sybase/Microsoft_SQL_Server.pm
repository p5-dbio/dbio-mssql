package DBIO::MSSQL::Loader::Sybase::Microsoft_SQL_Server;
# ABSTRACT: MSSQL via Sybase driver introspection

use strict;
use warnings;
use base 'DBIO::MSSQL::Loader';
use mro 'c3';


=head1 NAME

DBIO::MSSQL::Loader::Sybase::Microsoft_SQL_Server - Driver for
using Microsoft SQL Server through DBD::Sybase

=head1 DESCRIPTION

Subclasses L<DBIO::MSSQL::Loader>.

See L<DBIO::Loader> and L<DBIO::Loader::Base>.

=head1 SEE ALSO

L<DBIO::MSSQL::Loader>,
L<DBIO::MSSQL::Loader::ODBC::Microsoft_SQL_Server>,
L<DBIO::Sybase::Loader::Common>,
L<DBIO::Loader::DBI>,
L<DBIO::Loader>, L<DBIO::Loader::Base>,

=head1 AUTHORS

See L<DBIO::Loader/AUTHORS>.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
