package Pad::Schema;

use Moose;
extends 'MooseX::DBIC::Schema';

use File::stat;
use DateTime::Format::SQLite;
use JSON::Any;

use MooseX::Attribute::Deflator;

inflate 'DateTime',   via { DateTime::Format::SQLite->parse_datetime( $_ ) };
deflate 'File::stat', via { JSON::Any->new->encode([@$_]) };
inflate 'File::stat', via { File::stat::populate(@{JSON::Any->new->decode($_)}) };

no MooseX::Attribute::Deflator;

use MooseX::DBIC::TypeMap;

map_type 'File::stat' => 'ArrayRef';

no MooseX::DBIC::TypeMap;

__PACKAGE__->load_classes(qw(Distribution Release Author));

__PACKAGE__->meta->make_immutable;