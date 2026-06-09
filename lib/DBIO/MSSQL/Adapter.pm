package DBIO::MSSQL::Adapter;
# ABSTRACT: MSSQL base->native type resolver

use strict;
use warnings;
use Carp qw/croak/;
use base 'DBIO::Adapter::Base';

# Native MSSQL type for each portable base type. Mirrors the sibling
# drivers (DBIO::MySQL::Adapter, DBIO::PostgreSQL::Adapter): the eight
# base types are the single source of truth, resolved here.
#
# - integer promotes to bigint, as in MySQL/PostgreSQL.
# - text/blob use the unbounded (max) variants; the legacy `text`/`image`
#   types are deprecated in modern MSSQL.
# - timestamp maps to `datetime` (not datetime2) to stay aligned with
#   DBIO::MSSQL::Storage::DateTime::Format, whose %3N pattern is the
#   datetime millisecond format.
my %NATIVE = (
  integer   => 'bigint',
  text      => 'nvarchar(max)',
  boolean   => 'bit',
  double    => 'float',
  blob      => 'varbinary(max)',
  timestamp => 'datetime',
);

sub to_native {
  my ($self, $col) = @_;
  my $b = $col->{base_type};
  return 'nchar(' . ($col->{size} // 255) . ')' if $b eq 'char';
  if ($b eq 'numeric') {
    my ($p, $s) = @{$col}{qw/precision scale/};
    return (defined $p && defined $s) ? "numeric($p,$s)" : 'numeric';
  }
  return $NATIVE{$b} // croak "no MSSQL native type for base '$b'";
}

# capabilities inherited from DBIO::Adapter::Base: supports_alter_column_type => 1

1;
