# DBIO::MSSQL

Microsoft SQL Server database driver for DBIO (fork of DBIx::Class).

## Supports

- desired-state deployment via test-deploy-and-compare (L<DBIO::MSSQL::Deploy>)
- native introspection (L<DBIO::MSSQL::Introspect>)
- native diff (L<DBIO::MSSQL::Diff>)
- native DDL generation (L<DBIO::MSSQL::DDL>)

## Usage

    package MyApp::DB;
    use base 'DBIO::Schema';
    __PACKAGE__->load_components('MSSQL');

    my $schema = MyApp::DB->connect('dbi:MSSQL:database=myapp');

DBIO core autodetects `dbi:MSSQL:` DSNs and loads this storage automatically.

## MSSQL Features

**Types**
- `INT`, `BIGINT`, `SMALLINT`, `TINYINT` — numeric types
- `VARCHAR`, `CHAR`, `NVARCHAR`, `NTEXT` — string types
- `BLOB`, `VARBINARY`, `IMAGE` — binary types
- `DATE`, `TIME`, `DATETIME`, `DATETIME2` — temporal types
- `DECIMAL`, `NUMERIC`, `MONEY` — fixed-point numeric
- `BIT` — boolean type

**Schema Support**
- `INFORMATION_SCHEMA` for standard introspection
- `sys.tables`, `sys.columns` for MSSQL-specific metadata
- Identity columns for auto-increment

**Introspection (INFORMATION_SCHEMA + sys)**
- `INFORMATION_SCHEMA.TABLES` — table metadata
- `INFORMATION_SCHEMA.COLUMNS` — column metadata
- `sys.indexes`, `sys.index_columns` — index information
- `sys.foreign_keys` — constraint information

**MSSQL-Specific**
- `OUTPUT INSERTED.*` for inserted row retrieval
- `SET IDENTITY_INSERT` for explicit identity insertion
- Window functions (`ROW_NUMBER()`, `RANK()`, etc.)
- CTEs (`WITH` clause) for complex queries

## Deploy

L<DBIO::MSSQL::Deploy> orchestrates test-deploy-and-compare:

1. Introspect live database via INFORMATION_SCHEMA (L<DBIO::MSSQL::Introspect>)
2. Deploy desired schema to a temporary database
3. Introspect the temporary database the same way
4. Diff source vs target (L<DBIO::MSSQL::Diff>)

Install (`install_ddl`) creates fresh schema. Upgrade diffs live vs. desired.

## Testing

```bash
export DBIO_TEST_MSSQL_DSN="dbi:MSSQL:database=myapp"
export DBIO_TEST_MSSQL_USER=sa
export DBIO_TEST_MSSQL_PASS=secret
prove -l t/
```

For ODBC connections:

```bash
export DBIO_TEST_MSSQL_ODBC_DSN="dbi:ODBC:Driver={SQL Server};Server=localhost;Database=myapp"
export DBIO_TEST_MSSQL_ODBC_USER=sa
export DBIO_TEST_MSSQL_ODBC_PASS=secret
prove -l t/
```

## Requirements

- Perl 5.36+
- L<DBD::MSSQL|https://metacpan.org/pod/DBD::MSSQL> or L<DBD::ODBC|https://metacpan.org/pod/DBD::ODBC>
- DBIO core

## See Also

L<DBIO::Introspect::Base>, L<DBIO::Diff::Base>, L<DBIO::Deploy>

## Repository

L<https://github.com/p5-dbio/dbio-mssql>