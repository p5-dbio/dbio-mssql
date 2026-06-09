use strict;
use warnings;
use Test::More;

use_ok 'DBIO::MSSQL::Diff::Table';
use_ok 'DBIO::MSSQL::Diff::Column';
use_ok 'DBIO::MSSQL::Diff::Index';
use_ok 'DBIO::MSSQL::Diff';

# --- Diff::Table create with columns + PK + FK + identity ---
{
  my @ops = DBIO::MSSQL::Diff::Table->diff(
    {},
    { book => { table_name => 'book' } },
    {
      book => [
        { column_name => 'id',        data_type => 'int',     is_pk => 1, is_identity => 1, not_null => 1 },
        { column_name => 'author_id', data_type => 'int',     not_null => 1 },
        { column_name => 'title',     data_type => 'varchar', size => 255, not_null => 1 },
      ],
    },
    {
      book => [
        { from_columns => ['author_id'], to_table => 'author', to_columns => ['id'] },
      ],
    },
  );
  is(scalar @ops, 1, 'one create op');
  is($ops[0]->action, 'create', 'create action');
  my $sql = $ops[0]->as_sql;
  like($sql, qr/CREATE TABLE book \(/,                'CREATE TABLE');
  like($sql, qr/id int NOT NULL IDENTITY\(1,1\)/,     'inline identity');
  like($sql, qr/title nvarchar\(255\) NOT NULL/,      'varchar maps to sized nvarchar');
  like($sql, qr/PRIMARY KEY \(id\)/,                  'inline PK');
  like($sql, qr/FOREIGN KEY \(author_id\) REFERENCES author\(id\)/, 'inline FK');
  is($ops[0]->summary, '+ table: book', 'create summary');
}

# --- Diff::Table drop ---
{
  my @ops = DBIO::MSSQL::Diff::Table->diff(
    { gone => { table_name => 'gone' } }, {},
  );
  is(scalar @ops, 1, 'one drop op');
  is($ops[0]->action, 'drop', 'drop action');
  is($ops[0]->as_sql, 'DROP TABLE gone;', 'drop SQL');
  is($ops[0]->summary, '- table: gone', 'drop summary');
}

# --- Diff::Column add ---
{
  my @ops = DBIO::MSSQL::Diff::Column->diff(
    { t => [ { column_name => 'id', data_type => 'int' } ] },
    {
      t => [
        { column_name => 'id',    data_type => 'int' },
        { column_name => 'extra', data_type => 'varchar', size => 50, not_null => 1 },
      ],
    },
    { t => {} }, { t => {} },
  );
  is(scalar @ops, 1, 'one add op');
  is($ops[0]->action, 'add', 'add action');
  is($ops[0]->as_sql, 'ALTER TABLE t ADD extra nvarchar(50) NOT NULL;', 'add SQL');
}

# --- Diff::Column alter (type changed) ---
{
  my @ops = DBIO::MSSQL::Diff::Column->diff(
    { t => [ { column_name => 'a', data_type => 'int' } ] },
    { t => [ { column_name => 'a', data_type => 'bigint' } ] },
    { t => {} }, { t => {} },
  );
  is(scalar @ops, 1, 'one alter op');
  is($ops[0]->action, 'alter', 'alter action');
  like($ops[0]->as_sql, qr/ALTER TABLE t ALTER COLUMN a bigint;/, 'alter type SQL');
}

# --- Diff::Column alter (nullability changed) ---
{
  my @ops = DBIO::MSSQL::Diff::Column->diff(
    { t => [ { column_name => 'a', data_type => 'int', not_null => 0 } ] },
    { t => [ { column_name => 'a', data_type => 'int', not_null => 1 } ] },
    { t => {} }, { t => {} },
  );
  is($ops[0]->action, 'alter', 'alter action');
  like($ops[0]->as_sql, qr/ALTER TABLE t ALTER COLUMN a NOT NULL;/, 'alter NOT NULL SQL');
}

# --- Diff::Column drop ---
{
  my @ops = DBIO::MSSQL::Diff::Column->diff(
    { t => [
      { column_name => 'id',  data_type => 'int' },
      { column_name => 'old', data_type => 'text' },
    ] },
    { t => [ { column_name => 'id', data_type => 'int' } ] },
    { t => {} }, { t => {} },
  );
  is(scalar @ops, 1, 'one drop op');
  is($ops[0]->action, 'drop', 'drop action');
  is($ops[0]->as_sql, 'ALTER TABLE t DROP COLUMN old;', 'drop SQL');
}

# --- Diff::Index create (unique, nonclustered) ---
{
  my @ops = DBIO::MSSQL::Diff::Index->diff(
    { t => {} },
    { t => { idx_email => { is_unique => 1, kind => 'nonclustered', columns => ['email'] } } },
  );
  is(scalar @ops, 1, 'one create op');
  is($ops[0]->action, 'create', 'create action');
  is($ops[0]->as_sql,
    'CREATE UNIQUE INDEX idx_email ON t NONCLUSTERED (email);',
    'create index SQL');
  is($ops[0]->summary, '  +index: idx_email on t', 'create index summary');
}

# --- Diff::Index drop ---
{
  my @ops = DBIO::MSSQL::Diff::Index->diff(
    { t => { idx_old => { columns => ['x'] } } },
    { t => {} },
  );
  is(scalar @ops, 1, 'one drop op');
  is($ops[0]->action, 'drop', 'drop action');
  is($ops[0]->as_sql, 'DROP INDEX idx_old ON t;', 'drop index SQL');
}

# --- Diff::Index recreate on column change (drop + create) ---
{
  my @ops = DBIO::MSSQL::Diff::Index->diff(
    { t => { idx => { is_unique => 0, columns => ['a'] } } },
    { t => { idx => { is_unique => 0, columns => ['a', 'b'] } } },
  );
  is(scalar @ops, 2, 'two ops (drop + create)');
  is($ops[0]->action, 'drop',   'first is drop');
  is($ops[1]->action, 'create', 'second is create');
  like($ops[1]->as_sql, qr/\(a, b\)/, 'recreated with new columns');
}

# --- Full Diff orchestrator: source vs target model ---
{
  my $source = {
    tables  => { keep => { table_name => 'keep' }, drop_me => { table_name => 'drop_me' } },
    columns => { keep => [ { column_name => 'id', data_type => 'int' } ] },
    indexes => {},
  };
  my $target = {
    tables  => { keep => { table_name => 'keep' }, new_tbl => { table_name => 'new_tbl' } },
    columns => {
      keep    => [
        { column_name => 'id',  data_type => 'int' },
        { column_name => 'name', data_type => 'varchar', size => 100, not_null => 1 },
      ],
      new_tbl => [ { column_name => 'id', data_type => 'int', is_pk => 1, not_null => 1 } ],
    },
    foreign_keys => {},
    indexes => { keep => { idx_name => { columns => ['name'] } } },
  };

  my $diff = DBIO::MSSQL::Diff->new(source => $source, target => $target);
  ok($diff->has_changes, 'has changes');

  my $sql = $diff->as_sql;
  like($sql, qr/CREATE TABLE new_tbl/,           'creates new table');
  like($sql, qr/DROP TABLE drop_me;/,            'drops removed table');
  like($sql, qr/ALTER TABLE keep ADD name/,      'adds column to kept table');
  like($sql, qr/CREATE INDEX idx_name ON keep/,  'creates index');

  my $summary = $diff->summary;
  like($summary, qr/\+ table: new_tbl/, 'summary lists new table');
  like($summary, qr/- table: drop_me/, 'summary lists dropped table');
}

# --- Empty diff: identical models, no changes ---
{
  my $model = { tables => {}, columns => {}, indexes => {}, foreign_keys => {} };
  my $diff = DBIO::MSSQL::Diff->new(source => $model, target => $model);
  ok(!$diff->has_changes, 'no changes for identical empty models');
  is($diff->as_sql,  '', 'empty SQL');
}

done_testing;
