use strict;
use warnings;
use Test::More;

my @modules = qw(
  DBIO::MSSQL
  DBIO::MSSQL::Storage
  DBIO::MSSQL::Storage::Sybase
  DBIO::MSSQL::SQLMaker
  DBIO::MSSQL::Loader
  DBIO::MSSQL::Loader::ADO
  DBIO::MSSQL::Loader::ADO::Microsoft_SQL_Server
  DBIO::MSSQL::Loader::ADO::MS_Jet
  DBIO::MSSQL::Loader::ODBC::ACCESS
  DBIO::MSSQL::Loader::ODBC::Microsoft_SQL_Server
  DBIO::MSSQL::Loader::ODBC::SQL_Anywhere
  DBIO::MSSQL::Loader::SQLAnywhere
  DBIO::MSSQL::Loader::Sybase::Microsoft_SQL_Server
);

plan tests => scalar @modules;

for my $mod (@modules) {
  use_ok($mod);
}
