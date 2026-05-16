package DBIO::MSSQL::Storage::DateTime::Format;
# ABSTRACT: DateTime parser for MSSQL datetime and smalldatetime columns

use strict;
use warnings;

our $VERSION = '0.001';

my $datetime_format      = '%Y-%m-%d %H:%M:%S.%3N'; # %F %T
my $smalldatetime_format = '%Y-%m-%d %H:%M:%S';

my ($datetime_parser, $smalldatetime_parser);

sub parse_datetime {
  shift;
  require DateTime::Format::Strptime;
  $datetime_parser ||= DateTime::Format::Strptime->new(
    pattern  => $datetime_format,
    on_error => 'croak',
  );
  return $datetime_parser->parse_datetime(shift);
}

sub format_datetime {
  shift;
  require DateTime::Format::Strptime;
  $datetime_parser ||= DateTime::Format::Strptime->new(
    pattern  => $datetime_format,
    on_error => 'croak',
  );
  return $datetime_parser->format_datetime(shift);
}

sub parse_smalldatetime {
  shift;
  require DateTime::Format::Strptime;
  $smalldatetime_parser ||= DateTime::Format::Strptime->new(
    pattern  => $smalldatetime_format,
    on_error => 'croak',
  );
  return $smalldatetime_parser->parse_datetime(shift);
}

sub format_smalldatetime {
  shift;
  require DateTime::Format::Strptime;
  $smalldatetime_parser ||= DateTime::Format::Strptime->new(
    pattern  => $smalldatetime_format,
    on_error => 'croak',
  );
  return $smalldatetime_parser->format_datetime(shift);
}

1;