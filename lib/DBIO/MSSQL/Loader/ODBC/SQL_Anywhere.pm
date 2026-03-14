package DBIO::MSSQL::Loader::ODBC::SQL_Anywhere;
# ABSTRACT: SQL Anywhere via ODBC introspection

use strict;
use warnings;
use base qw/
    DBIO::Loader::ODBC
    DBIO::MSSQL::Loader::SQLAnywhere
/;
use mro 'c3';


=head1 NAME

DBIO::MSSQL::Loader::ODBC::SQL_Anywhere - ODBC wrapper for
L<DBIO::MSSQL::Loader::SQLAnywhere>

=head1 DESCRIPTION

Proxy for L<DBIO::MSSQL::Loader::SQLAnywhere> when using L<DBD::ODBC>.

See L<DBIO::Loader::Base> for usage information.

=cut

sub _columns_info_for {
    my $self = shift;

    my $result = $self->next::method(@_);

    while (my ($col, $info) = each %$result) {
        # The ODBC driver sets the default value to NULL even when it was not specified.
        if (ref $info->{default_value} && ${ $info->{default_value} } eq 'null') {
            delete $info->{default_value};
        }
    }

    return $result;
}

=head1 SEE ALSO

L<DBIO::MSSQL::Loader::SQLAnywhere>,
L<DBIO::Loader>, L<DBIO::Loader::Base>,
L<DBIO::Loader::DBI>

=head1 AUTHORS

See L<DBIO::Loader/AUTHORS>.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
# vim:et sw=4 sts=4 tw=0:
