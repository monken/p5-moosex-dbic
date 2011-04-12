use Test::More;
use SQL::Translator;

package CD;
use Moose;
use MooseX::DBIC;
    
has_column 'title';
belongs_to artist => ( isa => 'Artist', predicate => 'has_artist' );

package Artist;
use Moose;
use MooseX::DBIC;
use MooseX::DBIC::Types q(:all);
    

has_column 'name';
has_many cds => ( isa => ResultSet['CD'] );

package MySchema;
use Moose;
extends 'MooseX::DBIC::Schema';

__PACKAGE__->load_classes(qw(Artist CD));

package main;

use Scalar::Util qw(refaddr);

my $schema = MySchema->clone->compose_namespace('DBIC')->connect( 'dbi:SQLite::memory:' );
$schema->register_source('DBIC::'.$_ => $schema->source($_)) for(qw(Artist CD));
$schema->deploy;
my $queries = 0;
$schema->storage->debugcb(sub { print $_[1] if($ENV{DBIC_TRACE}); $queries++; });
$schema->storage->debug(1);

my $artist;

{
    ok($artist = $schema->resultset('DBIC::Artist')->create({ name => 'Mo' }));
    $artist = $schema->resultset('DBIC::Artist')->first;
    $artist->search_related('cds')->first;
}



done_testing;

