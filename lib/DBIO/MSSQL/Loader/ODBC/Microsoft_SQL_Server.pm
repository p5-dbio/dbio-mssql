package DBIO::MSSQL::Loader::ODBC::Microsoft_SQL_Server;
# ABSTRACT: MSSQL via ODBC introspection

use strict;
use warnings;
use base qw/
    DBIO::Loader::ODBC
    DBIO::MSSQL::Loader
/;
use mro 'c3';


=head1 NAME

DBIO::MSSQL::Loader::ODBC::Microsoft_SQL_Server - ODBC wrapper for
L<DBIO::MSSQL::Loader>

=head1 DESCRIPTION

Proxy for L<DBIO::MSSQL::Loader> when using L<DBD::ODBC>.

See L<DBIO::Loader::Base> for usage information.

=head1 SEE ALSO

L<DBIO::MSSQL::Loader>,
L<DBIO::Loader>, L<DBIO::Loader::Base>,
L<DBIO::Loader::DBI>

=head1 AUTHORS

See L<DBIO::Loader/AUTHORS>.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
