use strict;
use warnings;
use Test::More;

my @modules = qw(
  DBIO::MSSQL
  DBIO::MSSQL::Storage
  DBIO::MSSQL::Storage::Sybase
  DBIO::MSSQL::SQLMaker
);

plan tests => scalar @modules;

for my $mod (@modules) {
  use_ok($mod);
}
