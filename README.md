# DBIO-MSSQL

Microsoft SQL Server driver distribution for DBIO.

## Scope

- Provides MSSQL storage behavior: `DBIO::MSSQL::Storage`
- Provides Sybase-based MSSQL connection: `DBIO::MSSQL::Storage::Sybase`
- Provides MSSQL SQLMaker: `DBIO::MSSQL::SQLMaker`
- Owns MSSQL-specific tests from the historical DBIx::Class monolithic test layout

## Migration Notes

- `DBIx::Class::Storage::DBI::MSSQL` -> `DBIO::MSSQL::Storage`
- `DBIx::Class::Storage::DBI::Sybase::Microsoft_SQL_Server` -> `DBIO::MSSQL::Storage::Sybase`
- `DBIx::Class::SQLMaker::MSSQL` -> `DBIO::MSSQL::SQLMaker`

When installed, DBIO core can autodetect MSSQL DSNs and load the storage
class through `DBIO::Storage::DBI` driver registration.

## Testing

Set environment variables for integration tests:

- `DBIOTEST_MSSQL_DSN`
- `DBIOTEST_MSSQL_USER`
- `DBIOTEST_MSSQL_PASS`

For ODBC connections:

- `DBIOTEST_MSSQL_ODBC_DSN`
- `DBIOTEST_MSSQL_ODBC_USER`
- `DBIOTEST_MSSQL_ODBC_PASS`
