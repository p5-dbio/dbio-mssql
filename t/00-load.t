use strict;
use warnings;
use Test::More;

my @modules = qw(
  DBIO::MSSQL
  DBIO::MSSQL::Adapter
  DBIO::MSSQL::Result
  DBIO::MSSQL::Storage
  DBIO::MSSQL::Storage::Sybase
  DBIO::MSSQL::SQLMaker
  DBIO::MSSQL::DDL
  DBIO::MSSQL::Deploy
  DBIO::MSSQL::Diff
  DBIO::MSSQL::Introspect
);

plan tests => scalar @modules;

for my $mod (@modules) {
  use_ok($mod);
}
