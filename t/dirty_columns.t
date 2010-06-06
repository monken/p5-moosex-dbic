use Test::More;
use Test::Exception;
use strict;

use lib q(t/lib);
use DBICTest::Schema;

use Scalar::Util qw(refaddr);

my $schema = DBICTest::Schema->connect( 'dbi:SQLite::memory:' );

$schema->deploy;
my $queries = 0;
$schema->storage->debugcb(sub { print $_[1] if($ENV{DBIC_TRACE}); $queries++; });
$schema->storage->debug(1);

my $cd;

my %dirty = ( in_storage => 1, _raw_data => 1 );

{
    ok($cd = $schema->resultset('CD')->create({ 
        year => 1999,
        title => 'the rabbits',
        single_track => { title => 'foo' }
    }));
    is_deeply([$cd->meta->get_dirty_column_list($cd)], [], 'dirty columns in empty after create');
    $cd->year(2000);
    is_deeply([$cd->meta->get_dirty_column_list($cd)], ['year'], 'year column is dirty now');
    
}

{
    $cd = $schema->resultset('CD')->first;
    is_deeply([$cd->meta->get_dirty_column_list($cd)], [], 'dirty columns in empty after fetch from db');
    is($cd->single_track->title, 'foo');
    is_deeply([$cd->meta->get_dirty_column_list($cd)], [], 'dirty columns still empty after rel fetch');
    ok($cd->single_track->title('bar'), 'change title of single track');
    ok($cd->single_track->meta->is_dirty($cd->single_track), 'single_track is dirty');
    is_deeply([$cd->meta->get_dirty_column_list($cd)], [ 'single_track' ], 'cd\'s single_track is now dirty');
}

{
    ok(my $genre = $schema->resultset('Genre')->create({ 
        name => 'Rock', 
        model_cd => $cd,
        cds => [
        {
            year => 1999,
            title => 'the rabbits',
            single_track => { title => 'foo' }
        }
        ]
    }));
    isa_ok($genre, 'DBICTest::Genre');
}

{
    my $genre = $schema->resultset('Genre')->first;
    lives_ok { map { $_->create_related('tracks', { title => 'foo' }) } $genre->cds->all }; 
}

{
    my $genre = $schema->resultset('Genre')->search(undef, { prefetch => 'model_cd' })->first;
    my $rel = $genre->model_cd->meta->get_relationship('genre');
    ok(!$rel->is_column_dirty($genre->model_cd), 'Column is not dirty');
    ok(!$rel->is_relationship_dirty($genre->model_cd), 'Relationship is not dirty');
    
}



done_testing;

