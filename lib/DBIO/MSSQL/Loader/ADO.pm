package DBIO::MSSQL::Loader::ADO;
# ABSTRACT: ADO-based introspection base class

use strict;
use warnings;
use base 'DBIO::Loader::DBI';
use mro 'c3';


=head1 NAME

DBIO::MSSQL::Loader::ADO - L<DBD::ADO> proxy

=head1 DESCRIPTION

Reblesses into an C<::ADO::> class when connecting via L<DBD::ADO>.

See L<DBIO::Loader::Base> for usage information.

=cut

sub _rebless {
    my $self = shift;

    return if ref $self ne __PACKAGE__;

    my $dbh  = $self->schema->storage->dbh;
    my $dbtype = eval { $dbh->get_info(17) };
    unless ( $@ ) {
        # Translate the backend name into a perl identifier
        $dbtype =~ s/\W/_/gi;
        my $class = "DBIO::MSSQL::Loader::ADO::${dbtype}";
        if ($self->load_optional_class($class) && !$self->isa($class)) {
            bless $self, $class;
            $self->_rebless;
        }
    }
}

sub _filter_tables {
    my $self = shift;

    local $^W = 0; # turn off exception printing from Win32::OLE

    $self->next::method(@_);
}

=head1 SEE ALSO

L<DBIO::MSSQL::Loader::ADO::Microsoft_SQL_Server>,
L<DBIO::MSSQL::Loader::ADO::MS_Jet>,
L<DBIO::Loader>, L<DBIO::Loader::Base>,
L<DBIO::Loader::DBI>

=head1 AUTHORS

See L<DBIO::Loader/AUTHORS>.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
