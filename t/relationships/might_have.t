use Test::More;
use SQL::Translator;

package Artwork;
use Moose;
use MooseX::DBIC;
    
has_column 'image';
belongs_to cd_cover => ( isa => 'CD', lazy => 1 );
belongs_to cd_inlay => ( isa => 'CD', lazy => 1 );

package CD;
use Moose;
use MooseX::DBIC;
    
has_column title => ( is => 'rw', isa => 'Str' );
might_have cover => ( isa => 'Artwork', predicate => 'has_cover', foreign_key => 'cd_cover', lazy => 1 );
has_one inlay => ( isa => 'Artwork', predicate => 'has_inlay', foreign_key => 'cd_inlay', lazy => 1 );


package MySchema;
use Moose;
extends 'MooseX::DBIC::Schema';

__PACKAGE__->load_classes(qw(Artwork CD));

package main;

use Scalar::Util qw(refaddr);

my $schema = MySchema->connect( 'dbi:SQLite::memory:' );

$schema->deploy;
my $queries = 0;
$schema->storage->debugcb(sub { print $_[1] if($ENV{DBIC_TRACE}); $queries++; });
$schema->storage->debug(1);

{
    ok(my $cd = $schema->resultset('CD')->new_result({ title => 'CD1' }), 'Create CD1 without cover');
    ok(!$cd->has_cover, 'CD1 has no cover');
    ok(my $rel = $cd->meta->get_relationship('cover'), 'get attribute');
    ok(!$rel->is_dirty($cd), 'not dirty');
    ok(!$rel->is_required, 'not required');
    ok(!$rel->has_value($cd), 'has no value');
    ok($cd->insert, 'insert CD1');
    ok(!$cd->has_cover, 'CD1 has still no cover');
    ok($cd->cover->id, 'Create cover');
    is($cd->cover->cd_cover->id, $cd->id, 'Cover has the CD id set'); 
    is(refaddr $cd->cover->cd_cover, refaddr $cd, 'Cover has cd object set');
    ok($cd->cover->image('nice'), 'Set image attribute');
    ok($cd->update, 'Update CD');
    ok($cd->update, 'Calling update again works');
    ok($cd->cover->in_storage, 'Cover is in storage');
    is($queries, 5, 'Queries count ok');
}

{    
    $queries = 0;
    ok(my $cd = $schema->resultset('CD')->first, 'Get CD from storage');
    TODO: { local $TODO = 'Override predicate'; ok($cd->has_cover, 'CD1 has a cover') };
    ok($cd->cover->in_storage, 'Cover is in storage');
    is($cd->cover->image, 'nice', 'Get image attribute from cover');
    is($queries, 2, 'Queries count ok');
}

{
    $queries = 0;
    ok(my $cd = $schema->resultset('CD')->create({ title => 'CD2', cover => { image => 'nice' } }), 'Create CD2 with cover');

}

{
    $queries = 0;
    ok(my $cd = $schema->resultset('CD')->create({ title => 'CD3' }) );
    ok($cd->create_related(cover => { image => 'nice' }), 'Create CD3 with cover');

}

done_testing;

