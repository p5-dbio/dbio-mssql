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

## Requirements

- Perl 5.36+
- DBD::MSSQL or DBD::ODBC
- DBIO core

## Testing

    prove -l t/

Requires a running MSSQL instance. Set C<DBIO_TEST_MSSQL_DSN>,
C<DBIO_TEST_MSSQL_USER>, and C<DBIO_TEST_MSSQL_PASS>.

For ODBC connections, set C<DBIO_TEST_MSSQL_ODBC_DSN>,
C<DBIO_TEST_MSSQL_ODBC_USER>, and C<DBIO_TEST_MSSQL_ODBC_PASS>.

## See Also

L<DBIO::Introspect::Base>, L<DBIO::Diff::Base>
