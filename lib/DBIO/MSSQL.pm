package DBIO::MSSQL;
# ABSTRACT: Microsoft SQL Server-specific schema management for DBIO

use strict;
use warnings;

use base 'DBIO';

sub connection {
  my ($self, @info) = @_;
  $self->storage_type('+DBIO::MSSQL::Storage');
  return $self->next::method(@info);
}

1;
