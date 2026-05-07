package DBIO::MSSQL::DDL;
# ABSTRACT: Generate MSSQL DDL from DBIO Result classes
our $VERSION = '0.900000';

use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(_mssql_column_type _quote_ident);

use DBIO::SQL::Util qw(_quote_ident);

=head1 DESCRIPTION

C<DBIO::MSSQL::DDL> generates a MSSQL DDL script from a L<DBIO::Schema>
class hierarchy. It is the desired-state side of the test-deploy-and-
compare strategy used by L<DBIO::MSSQL::Deploy>.

    my $ddl = DBIO::MSSQL::DDL->install_ddl($schema_class_or_instance);

The output is plain SQL, suitable for executing one statement at a time
against a fresh MSSQL database. Emits C<CREATE TABLE> (inline columns,
primary key, unique, foreign keys) and C<CREATE INDEX>.

=cut

=method install_ddl

    my $ddl = DBIO::MSSQL::DDL->install_ddl($schema);

Returns the full installation DDL as a single string.

=cut

sub install_ddl {
  my ($class, $schema) = @_;

  my @stmts;
  my %seen_table;

  for my $source_name (_topo_sort_sources($schema)) {
    my $source       = $schema->source($source_name);
    my $result_class = $source->result_class;
    my $table_name   = _resolve_table_name($source->name);

    # Virtual / view source whose name is inline SQL: skip here.
    next unless defined $table_name;

    # Multiple Result classes may share one physical table.
    next if $seen_table{$table_name}++;

    my @col_defs;
    my %is_pk;
    my @pk_cols = $source->primary_columns;
    @is_pk{@pk_cols} = (1) x @pk_cols;

    for my $col_name ($source->columns) {
      my $info = $source->column_info($col_name);
      my $type = _mssql_column_type($info);

      my $def = sprintf '  %s %s', _quote_ident($col_name), $type;

      $def .= ' NOT NULL' if defined $info->{is_nullable} && !$info->{is_nullable};

      if ($info->{is_auto_increment}) {
        $def .= ' IDENTITY(1,1)';
      } elsif (defined $info->{default_value}) {
        my $dv = $info->{default_value};
        if (ref $dv eq 'SCALAR') {
          $def .= " DEFAULT $$dv";
        } else {
          $def .= " DEFAULT $dv";
        }
      }

      push @col_defs, $def;
    }

    if (@pk_cols) {
      push @col_defs, sprintf '  PRIMARY KEY (%s)',
        join(', ', map { _quote_ident($_) } @pk_cols);
    }

    if ($source->can('unique_constraints')) {
      my %uniques = $source->unique_constraints;
      for my $uname (sort keys %uniques) {
        next if $uname eq 'primary';
        my $cols = $uniques{$uname};
        push @col_defs, sprintf '  UNIQUE (%s)',
          join(', ', map { _quote_ident($_) } @$cols);
      }
    }

    push @stmts, sprintf "CREATE TABLE %s (\n%s\n);",
      _quote_ident($table_name), join(",\n", @col_defs);

    # Standalone indexes declared via mssql_indexes class method.
    if ($result_class->can('mssql_indexes')) {
      my $indexes = $result_class->mssql_indexes;
      for my $idx_name (sort keys %$indexes) {
        my $idx = $indexes->{$idx_name};
        my $unique = $idx->{unique} ? 'UNIQUE ' : '';
        my $kind = $idx->{kind} || '';
        my $kind_sql = $kind eq 'clustered' ? 'CLUSTERED' : $kind eq 'nonclustered' ? 'NONCLUSTERED' : '';
        my $columns = join ', ',
          map { _quote_ident($_) } @{ $idx->{columns} // [] };
        my $sql = sprintf 'CREATE %sINDEX %s ON %s %s(%s)',
          $unique, _quote_ident($idx_name),
          _quote_ident($table_name), $kind_sql ? "$kind_sql " : '', $columns;
        push @stmts, "$sql;";
      }
    }
  }

  return join "\n\n", @stmts;
}

sub _resolve_table_name {
  my ($name) = @_;
  return $name unless ref $name;
  return undef unless ref $name eq 'SCALAR';
  my $v = $$name;
  return undef unless defined $v;
  return $v if $v =~ /\A\w+\z/;
  return undef;
}

sub _topo_sort_sources {
  my ($schema) = @_;

  my %deps;
  my %by_table;
  my @sources = sort $schema->sources;

  for my $name (@sources) {
    my $s = $schema->source($name);
    my $t = _resolve_table_name($s->name);
    next unless defined $t;
    $by_table{$t} //= $name;
  }

  for my $name (@sources) {
    my $s = $schema->source($name);
    next unless defined _resolve_table_name($s->name);
    $deps{$name} ||= {};
    for my $rel ($s->relationships) {
      my $info = $s->relationship_info($rel);
      next unless $info && $info->{attrs}
               && $info->{attrs}{is_foreign_key_constraint};
      my $foreign = $info->{class};
      my $fs = eval { $schema->source($foreign) }
            // eval { $schema->source($foreign =~ s/.*:://r) };
      next unless $fs;
      my $ft = _resolve_table_name($fs->name);
      next unless defined $ft;
      my $owner = $by_table{$ft};
      next unless $owner;
      next if $owner eq $name;
      $deps{$name}{$owner} = 1;
    }
  }

  my @out;
  my %visited;
  my $visit;
  $visit = sub {
    my ($n) = @_;
    return if $visited{$n}++;
    for my $d (sort keys %{ $deps{$n} || {} }) {
      $visit->($d);
    }
    push @out, $n;
  };
  $visit->($_) for @sources;
  return @out;
}

sub _mssql_column_type {
  my ($info) = @_;
  my $type = $info->{data_type} // 'nvarchar';

  return $type if $type =~ /\(.+\)$/;

  my %type_map = (
    # integers
    tinyint   => 'tinyint',
    smallint  => 'smallint',
    int       => 'int',
    integer   => 'int',
    bigint    => 'bigint',
    serial    => 'int',
    bigserial => 'bigint',

    # floats / decimals
    real              => 'real',
    float             => 'float',
    double            => 'float',
    'double precision'=> 'float',
    numeric           => 'numeric',
    decimal           => 'numeric',

    # strings
    text       => 'text',
    string     => 'nvarchar',
    varchar    => 'nvarchar',
    char       => 'nchar',
    ntext      => 'ntext',

    # booleans
    boolean => 'bit',
    bool    => 'bit',

    # blobs
    blob       => 'varbinary',
    bytea      => 'varbinary',
    tinyblob   => 'varbinary',
    mediumblob => 'varbinary',
    longblob   => 'varbinary',
    binary     => 'binary',
    varbinary  => 'varbinary',

    # temporal
    date        => 'date',
    time        => 'time',
    datetime    => 'datetime',
    timestamp   => 'datetime',
    timestamptz => 'datetimeoffset',
    'timestamp with time zone' => 'datetimeoffset',
    smalldatetime => 'smalldatetime',
  );

  my $mapped = $type_map{ lc $type };
  return $mapped if $mapped;

  # Handle size for varchar/nvarchar
  if ($type =~ /varchar/i) {
    my $size = $info->{size};
    if (defined $size && $size > 0) {
      return "$type($size)";
    }
  }

  return $type;
}

1;
__END__
