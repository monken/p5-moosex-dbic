use lib qw(../p5-moosex-attribute-deflator/lib);

use Test::More;
use SQL::Translator;

package CD;
use Moose;
use MooseX::DBIC;
with 'MooseX::DBIC::Result';
has_column title => ( is => 'rw', isa => 'Str' );
belongs_to artist => ( is => 'rw', isa => 'Artist', predicate => 'has_artist' );

package Artist;
use Moose;
use MooseX::DBIC;
use MooseX::DBIC::Types q(:all);
with 'MooseX::DBIC::Result';

has_column name => ( is => 'rw', isa => 'Str' );
has_many cds => ( is => 'rw', isa => ResultSet['CD'] );

package MySchema;
use Moose;
extends 'MooseX::DBIC::Schema';

__PACKAGE__->load_classes(qw(Artist CD));

package main;

use Scalar::Util qw(refaddr);

my $schema = MySchema->connect( 'dbi:SQLite::memory:' );

$schema->deploy;

my $artist;

 {
    ok($artist = $schema->resultset('Artist')->create({ name => 'Mo'}));
    isa_ok($artist, 'Artist');
    ok($artist->in_storage, 'Artist is in storage');
    ok(my $cds = $artist->cds);
    isa_ok($cds, 'DBIx::Class::ResultSet');
    ok(my $cd = $artist->create_related('cds' => { title => 'CD1' } ));
    ok($cd = $artist->create_related('cds' => { title => 'CD2' } ));
    isa_ok($cd, 'CD');
    is($cd->artist->id, $artist->id);
}

{
    ok(my $cd = $schema->resultset('CD')->create({ title => 'CD3'}));
    ok(!$cd->has_artist, 'CD3 has no artist');
    ok($cd = $schema->resultset('CD')->find($cd->id), 'fetch from storage');
    ok(!$cd->has_artist, 'CD3 has still no artist');
}

{
    ok($artist = $schema->resultset('Artist')->search({ 'me.id' => $artist->id}, {prefetch => 'cds'})->first);
    ok($artist->in_storage, 'Artist is in storage');
    ok(my $cds = $artist->cds);
    is($cds->all, 2, 'Got 2 CDs');
    #ok($cds->first->in_storage, 'CD is in storage');
    is(refaddr $cds->first->artist, refaddr $artist, 'CD\'s artist is the same as $artist');
    
}

{
    ok(my $artist = $schema->resultset('Artist')->first, 'Look up artist');
    ok($artist->in_storage, 'Artist is in storage');
    is($artist->search_related('cds')->all, 2, 'Get cds via search_related');
    is($artist->cds->all, 2, 'Got 2 CDs via accessor');
}

{
    ok(my $cd = $schema->resultset('CD')->search({ title => 'CD1'},{prefetch => 'artist' })->first);
}

done_testing;

