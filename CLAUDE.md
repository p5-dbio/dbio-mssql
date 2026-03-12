# CLAUDE.md -- DBIO::MSSQL

## Project Vision

Microsoft SQL Server-specific storage for DBIO (the DBIx::Class fork, see ../dbio/).

**Status**: Active development. Storage extracted from DBIO core.

## Namespace

- `DBIO::MSSQL` — MSSQL schema component
- `DBIO::MSSQL::Storage` — MSSQL storage (replaces DBIx::Class::Storage::DBI::MSSQL)
- `DBIO::MSSQL::SQLMaker` — MSSQL SQL dialect
- `DBIO::MSSQL::Storage::Sybase` — Sybase-based MSSQL connection variant

## Build System

Uses Dist::Zilla with `[@DBIO]` plugin bundle. PodWeaver with `=attr` and `=method` collectors.
