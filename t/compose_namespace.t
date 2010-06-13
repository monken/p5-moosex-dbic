use Test::More;
use Test::Exception;
use SQL::Translator;

package MySchema::CD;
use MooseX::DBIC;
    
has_column 'title';
belongs_to artist => ( isa => 'MySchema::Artist', predicate => 'has_artist' );

package MySchema::Artist;
use MooseX::DBIC;
use MooseX::DBIC::Types q(:all);
    

has_column 'name';
has_many cds => ( isa => ResultSet['MySchema::CD'] );

package MySchema;
use Moose;
extends 'MooseX::DBIC::Schema';

__PACKAGE__->load_classes(qw(MySchema::Artist MySchema::CD));

package main;

use Scalar::Util qw(refaddr);

my $schema = MySchema->compose_namespace('DBIC')->connect( 'dbi:SQLite::memory:' );
$schema->deploy;

my $artist;

lives_ok {
    ok($artist = $schema->resultset('Artist')->create({ name => 'Mo' }));
    $artist = $schema->resultset('Artist')->first;
    $artist->search_related('cds')->first;
} 'related search doesn\'t throw';


my $queries = 0;
$schema->storage->debugcb(sub { print $_[1] if($ENV{DBIC_TRACE}); $queries++; });
$schema->storage->debug(1);

{
    ok($artist = $schema->resultset('Artist')->create({ name => 'Mo'}));
    isa_ok($artist, 'DBIC::Artist');
    ok($artist->in_storage, 'Artist is in storage');
    is($artist->name, 'Mo', 'Name is set');
    ok(my $cds = $artist->cds);
    isa_ok($cds, 'DBIx::Class::ResultSet');
    ok(my $cd = $artist->create_related('cds' => { title => 'CD1' } ));
    ok($cd = $artist->create_related('cds' => { title => 'CD2' } ));
    isa_ok($cd, 'DBIC::CD');
    is($cd->artist->id, $artist->id);
    is(refaddr $cd->artist, refaddr $artist);
    is($queries, 3, 'Queries Count ok');
}

{
    $queries = 0;
    ok(my $artist2 = $schema->resultset('Artist')->create({ name => 'Nock', cds => [{title=> 'Foo'},{},{}]}), 'Multi create Artist with 3 CDs');
    isa_ok($artist2, 'DBIC::Artist');
    is($artist2->cds, 3,'Artist has 3 CDs');
    is($schema->resultset('Artist')->search({name => 'Nock'})->first->cds, 3,'Artist has 3 CDs even from storage');
    is($queries, 6, 'Queries Count ok');
}

{
    $queries = 0;
    ok(my $cd = $schema->resultset('CD')->create({ title => 'CD3'}));
    ok(!$cd->has_artist, 'CD3 has no artist');
    ok($cd = $schema->resultset('CD')->find($cd->id), 'fetch from storage');
    ok(!$cd->has_artist, 'CD3 has still no artist');
    ok($cd->artist($artist), 'Set artist on CD3');
    is_deeply([$cd->meta->get_dirty_column_list($cd)], ['artist'], 'cd\'s artist column is dirty');
    ok($cd->update, 'update CD3');
    is($schema->resultset('CD')->find($cd->id)->artist->id, $artist->id, 'Artist ID set in storage');
    is($queries, 4, 'Queries Count ok');
}

{
    $queries = 0;
    ok(my $cd = $schema->resultset('CD')->create({ title => 'CD6'}));
    ok($cd = $schema->resultset('CD')->find($cd->id), 'fetch from storage');
    ok(!$cd->has_artist, 'CD6 has still no artist');
    ok($cd->artist, 'Create artist on CD6');
    ok(!$cd->artist->in_storage, 'Artist is not in storage');
    ok($cd->update, 'update CD6');
    ok($schema->resultset('CD')->find($cd->id)->artist->id, 'Artist ID set in storage');
    is($queries, 5, 'Queries Count ok');
}

{
    $queries = 0;
    ok(my $cd = $schema->resultset('CD')->create({ title => 'CD4', artist => { name => 'Rieche' } }), 'Create CD4 with new artist');
    is($schema->resultset('CD')->find($cd->id)->title, 'CD4', 'CD4 in storage');
    is($schema->resultset('CD')->find($cd->id)->artist->name, 'Rieche', 'Artist in storage');
    is($queries, 5, 'Queries Count ok');
    
}

{
    $queries = 0;
    ok($artist = $schema->resultset('Artist')->search({ 'me.id' => $artist->id}, {prefetch => 'cds'})->first);
    ok($artist->in_storage, 'Artist is in storage');
    ok(my $cds = $artist->cds);
    is($cds->all, 3, 'Got 3 CDs');
    ok($cds->first->in_storage, 'CD is in storage');
    is(refaddr $cds->first->artist, refaddr $artist, 'CD\'s artist is the same as $artist');
    is($queries, 1, 'Queries Count ok');
    
}

{
    $queries = 0;
    ok(my $artist = $schema->resultset('Artist')->find($artist->id), 'Look up artist');
    ok($artist->in_storage, 'Artist is in storage');
    is($artist->search_related('cds')->all, 3, 'Get cds via search_related');
    is($artist->cds->all, 3, 'Got 3 CDs via accessor');
    is($queries, 3, 'Queries Count ok');
}

{
    $queries = 0;
    ok($schema->resultset('CD')->search({ title => 'CD1'},{prefetch => 'artist' })->first);
    ok($schema->resultset('CD')->create({ title => 'CD5'}), 'Create CD without artist');
    ok(my $cd = $schema->resultset('CD')->search({ title => 'CD5'},{prefetch => 'artist' })->first, 'Get that CD and prefetch artist');
    is($cd->title, 'CD5');
    ok(!$cd->has_artist, 'CD has no artist');
    is(ref $cd->artist, 'DBIC::Artist', 'Lazy creation of artist');
    ok($cd->artist->id, 'Artist has an ID');
    ok($cd->update, 'Update CD');
    ok($cd->in_storage && $cd->artist->in_storage, 'CD and Artist in storage');
    is($queries, 5, 'Queries Count ok');
}


done_testing;

