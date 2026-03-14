package DBIO::MSSQL::Loader::ADO::Microsoft_SQL_Server;
# ABSTRACT: MSSQL via ADO introspection

use strict;
use warnings;
use base qw/
    DBIO::MSSQL::Loader::ADO
    DBIO::MSSQL::Loader
/;
use mro 'c3';
use DBIO::Loader::Utils qw/sigwarn_silencer/;

use namespace::clean;


=head1 NAME

DBIO::MSSQL::Loader::ADO::Microsoft_SQL_Server - ADO wrapper for
L<DBIO::MSSQL::Loader>

=head1 DESCRIPTION

Proxy for L<DBIO::MSSQL::Loader> when using L<DBD::ADO>.

See L<DBIO::Loader::Base> for usage information.

=cut

# Silence ADO "Changed database context" warnings
sub _switch_db {
    my $self = shift;
    local $SIG{__WARN__} = sigwarn_silencer(qr/Changed database context/);
    return $self->next::method(@_);
}

=head1 SEE ALSO

L<DBIO::MSSQL::Loader::ADO>,
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
