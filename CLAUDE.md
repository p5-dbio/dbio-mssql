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

**UNIQUEIDENTIFIER (GUID) columns that look like auto-increment are NOT real IDENTITY
columns** — they're populated by `NEWID()` via `DBIO::Storage::DBI::UniqueIdentifier::_prefetch_autovalues`.
`_prep_for_execute` inspects `data_type` for `uniqueidentifier`/`guid` and locally
suppresses `_autoinc_supplied_for_op` so the parent `IdentityInsert` wrapper is
skipped. Otherwise MSSQL rejects `SET IDENTITY_INSERT` with
"Table '...' does not have the identity property". The trailing
`SELECT SCOPE_IDENTITY()` is also skipped for GUID-typed autoinc (no real
IDENTITY column to retrieve from).

Note: non-PK GUID columns need `auto_nextval => 1` in the schema
(NOT `is_auto_increment => 1`) for `_prefetch_autovalues` to populate them.
PK GUIDs are populated unconditionally.

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
DBIO_TEST_MSSQL_ODBC_DSN='dbi:ODBC:DSN=mssql-dev'   # DBD::ODBC + FreeTDS
DBIO_TEST_MSSQL_DSN='dbi:Sybase:...'                 # DBD::Sybase (t/10, t/20)
DBIO_TEST_MSSQL_ODBC_USER=sa
DBIO_TEST_MSSQL_ODBC_PASS='...'
```

`t/10-mssql.t` and `t/20-mssql-core.t` need DBD::Sybase (DBD::ODBC+FreeTDS won't
work for those). DBD::Sybase is not installed by default; track via the
`dbio-mssql` karr ticket on DBD::Sybase install.

### Rebless target

DBIO core's `DBIO::Storage::DBI::ODBC->_rebless` calls
`_determine_connector_driver('ODBC')`, which looks up `SQL_DBMS_NAME` in the
default connector registry. For MSSQL the registry maps
`Microsoft_SQL_Server` -> `DBIO::MSSQL::Storage::Sybase`. So both DBD::ODBC
and DBD::Sybase connections end up reblessed to `DBIO::MSSQL::Storage::Sybase`
on first connect.

### `on_connect_call` options

`t/11` + `t/21` ship with `on_connect_call` options for
`use_dynamic_cursors` / `use_mars` / `use_server_cursors` (DBD::Sybase
specific). When running against DBD::ODBC+FreeTDS the test pre-skips these
with a `can("connect_call_$_")` check and `last SKIP` to abort the iteration
cleanly (otherwise the iteration continues to `dbh_do` and exits 255).

### Live test status (2026-06-09, MSSQL 2022 in k3s `mssql-dev`)

| Test | Result | Notes |
|------|--------|-------|
| t/00-load.t | PASS | offline |
| t/40-sqlmaker-mssql-torture.t | PASS | offline |
| t/50-diff.t | PASS | offline |
| t/52-introspect-contract.t | PASS | offline |
| t/11-mssql-odbc.t | 124/125 | GUID `auto_nextval` fail (dbio core ArtistGUID fix via karr #1) |
| t/21-mssql-odbc-core.t | 124/125 | same |
| t/30-datetime-mssql.t | FAIL | `DBIO::Test::Schema::EventSmallDT` missing (dbio core port via karr #2) |
| t/10-mssql.t | SKIP | needs DBD::Sybase |
| t/20-mssql-core.t | SKIP | needs DBD::Sybase |
