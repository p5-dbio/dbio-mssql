# CLAUDE.md -- DBIO::MSSQL

## Perl Rules

**MANDATORY: load the `dbio-perl-core` skill before editing any Perl code.** DBIO project conventions.

## Namespace

- `DBIO::MSSQL` — MSSQL schema component
- `DBIO::MSSQL::Storage` — MSSQL storage
- `DBIO::MSSQL::SQLMaker` — MSSQL SQL dialect
- `DBIO::MSSQL::Storage::Sybase` — Sybase-based MSSQL connection variant

## Native Deploy (test-and-compare)

`DBIO::MSSQL::Deploy` uses the same strategy as other DBIO drivers:

1. Introspect live DB via `INFORMATION_SCHEMA` + `sys.indexes`
2. Deploy desired schema to temp DB (`CREATE DATABASE _dbio_tmp_<pid>_<time>`)
3. Introspect the temp DB
4. Diff the two models via `DBIO::MSSQL::Diff`

Temp DB connections are derived by swapping the database name in the DSN.
Supports both scalar and hash `connect_info` formats.

## Introspect Sub-modules

- `DBIO::MSSQL::Introspect::Tables` — `INFORMATION_SCHEMA.TABLES`
- `DBIO::MSSQL::Introspect::Columns` — `INFORMATION_SCHEMA.COLUMNS` + PK/identity
- `DBIO::MSSQL::Introspect::Indexes` — `sys.indexes` / `sys.index_columns`
- `DBIO::MSSQL::Introspect::ForeignKeys` — `REFERENTIAL_CONSTRAINTS` + `TABLE_CONSTRAINTS`

## Diff Sub-modules

- `DBIO::MSSQL::Diff::Table` — CREATE/DROP TABLE with inline FK
- `DBIO::MSSQL::Diff::Column` — ADD/ALTER/DROP COLUMN
- `DBIO::MSSQL::Diff::Index` — CREATE/DROP INDEX (clustered/nonclustered)

## DDL

`DBIO::MSSQL::DDL->install_ddl($schema)` generates a full DDL script from DBIO classes.
Handles: table creation with inline PK/FK, unique constraints, `IDENTITY(1,1)` for auto-inc,
and standalone indexes via `mssql_indexes` class method.

## MSSQL-Specifics

### Datetime Types

| Type | Range | Precision |
|------|-------|-----------|
| `datetime` | 1753-01-01 to 9999-12-31 | 3.33ms |
| `datetime2` | 0001-01-01 to 9999-12-31 | 100ns |
| `datetimeoffset` | 0001-01-01 to 9999-12-31 | 100ns + timezone |
| `smalldatetime` | 1900-01-01 to 2079-06-06 | 1 min |

Storage uses `DBIO::MSSQL::Storage::DateTime::Format` (Strptime-based).

### MONEY

`_prep_for_execute` auto-casts bind values to MONEY via `CAST(? AS MONEY)` to avoid DBI truncation.

### Ordered Subselects

MSSQL forbids `ORDER BY` in subqueries without `TOP`. `_select_args_to_query` intercepts and wraps with `SELECT TOP <max_int>`.

### Identity / Auto-Increment

`IDENTITY(1,1)` syntax. `last_insert_id` via `SCOPE_IDENTITY()` appended to INSERT, with `_identity_method` fallback.

### Bulk Operations

No native bulk INSERT in DBIO. Use `OUTPUT` clause or direct `BULK INSERT` via `$dbh->do`.

## Storage Wiring

```perl
__PACKAGE__->datetime_parser_type('DBIO::MSSQL::Storage::DateTime::Format');
__PACKAGE__->new_guid('NEWID()');
sub dbio_deploy_class { 'DBIO::MSSQL::Deploy' }
sub deploy_setup { }   # no-op stub
```

## Testing

Offline tests use `DBIO::Test::Storage`. Integration tests require:
```bash
DBIO_TEST_MSSQL_DSN=dbi:ODBC:...
```
