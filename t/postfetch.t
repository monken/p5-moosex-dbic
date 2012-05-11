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
use DateTime;

has_column 'name';
has_many cds        => ( isa => 'CD' );
might_have cover_cd => ( isa => 'CD' );

package MySchema;
use Moose;
extends 'MooseX::DBIC::Schema';

__PACKAGE__->load_classes(qw(Artist CD));

package main;

use Scalar::Util qw(refaddr);

my $schema = MySchema->connect('dbi:SQLite::memory:');
$schema->deploy;
my $queries = 0;
$schema->storage->debugcb(
    sub { diag $_[1] if ( $ENV{DBIC_TRACE} ); $queries++; } );
$schema->storage->debug(1);

{
    foreach my $i ( 0 .. 9 ) {
        ok( $schema->resultset('Artist')->create(
                {   name => "Artist$i",
                    id   => $i,
                    cds  => [
                        map { { title => "CD$_", id => $i * 3 + $_ } } 1 .. 2
                    ],
                    cover_cd => { title => "CoverCD$i", id => $i * 3 + 3 },
                }
            ),
            "Create new artist $i with 2 cds"
        );
    }

    my $cds = $schema->resultset('CD');
    is( $cds->count, 30, "30 cds" );
    is( (   grep { $_->artist->does('MooseX::DBIC::Meta::Role::ResultProxy') }
                $cds->all
        ),
        30,
        'no artists loaded'
    );
    $queries = 0;
    $cds     = $cds->postfetch('artist');

    is_deeply(
        [ map { ( "Artist$_", "Artist$_", "Artist$_" ) } ( 0 .. 9 ) ],
        [ sort map { $_->artist->name } $cds->all ],
        'all artists postfetched'
    );
    is( $queries, 2, 'two queries' );

}

{
    my $artists = $schema->resultset('Artist');
    is( $artists->count, 10, '10 artists' );
    my $artist = $artists->first;
    ok( !$artist->meta->get_relationship('cds')->get_raw_value($artist),
        'cds not loaded' );
    $queries = 0;
    $artists = $artists->postfetch('cds');
    is_deeply(
        [ 1 .. 30 ],
        [   map {
                map { $_->id }
                    $_->cds->all
                } $artists->all
        ],
        'all cds postfetched'
    );
    is( $queries, 2, 'two queries' );

    $artist = $artists->first;

    $queries = 0;
    foreach my $artist ( $schema->resultset('Artist')->postfetch('cds')->all )
    {
        is( $artist->cds->first->artist->name, $artist->name, 'cycle' );
    }
    is( $queries, 2, 'still only 2 queries' );
}

{
    my $artists = $schema->resultset('Artist');
    $queries = 0;
    my @artists = $artists->postfetch('cover_cd')->all;
    map { $_->cover_cd->title } @artists;
    is($queries, 2, 'only two queries (might_have)');
}

done_testing;

