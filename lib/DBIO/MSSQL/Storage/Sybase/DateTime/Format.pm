package DBIO::MSSQL::Storage::Sybase::DateTime::Format;
# ABSTRACT: DateTime parser for MSSQL via DBD::Sybase

use strict;
use warnings;

our $VERSION = '0.001';

my $datetime_parse_format  = '%Y-%m-%dT%H:%M:%S.%3NZ';
my $datetime_format_format = '%Y-%m-%d %H:%M:%S.%3N'; # %F %T

my ($datetime_parser, $datetime_formatter);

sub parse_datetime {
  shift;
  require DateTime::Format::Strptime;
  $datetime_parser ||= DateTime::Format::Strptime->new(
    pattern  => $datetime_parse_format,
    on_error => 'croak',
  );
  return $datetime_parser->parse_datetime(shift);
}

sub format_datetime {
  shift;
  require DateTime::Format::Strptime;
  $datetime_formatter ||= DateTime::Format::Strptime->new(
    pattern  => $datetime_format_format,
    on_error => 'croak',
  );
  return $datetime_formatter->format_datetime(shift);
}

1;