# DBIO::MSSQL::Loader TODO

Ported from DBIx::Class::Schema::Loader. Lives at `DBIO::MSSQL::Loader`.
**Status: NOT ACTIVELY DEVELOPED** — files are placeholders.

## Files

- `DBIO::MSSQL::Loader` — main MSSQL Loader
- `DBIO::MSSQL::Loader::ADO` — ADO connection variant
- `DBIO::MSSQL::Loader::ADO::Microsoft_SQL_Server` — ADO + MSSQL
- `DBIO::MSSQL::Loader::ADO::MS_Jet` — ADO + MS Jet/Access
- `DBIO::MSSQL::Loader::ODBC::ACCESS` — ODBC + MS Access
- `DBIO::MSSQL::Loader::ODBC::Microsoft_SQL_Server` — ODBC + MSSQL
- `DBIO::MSSQL::Loader::ODBC::SQL_Anywhere` — ODBC + SQL Anywhere
- `DBIO::MSSQL::Loader::SQLAnywhere` — SQL Anywhere direct
- `DBIO::MSSQL::Loader::Sybase::Microsoft_SQL_Server` — via DBD::Sybase

## TODO

- [ ] Integration with DBIO::MSSQL::Storage
- [ ] Port driver-specific loader tests from Schema::Loader
- [ ] Test with real database
- [ ] Review and update introspection queries for modern SQL Server
