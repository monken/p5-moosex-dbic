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

my $model;

{
    ok($model = $schema->resultset('CD')->create({ 
        year => 1999,
        title => 'the rabbits',
        single_track => { title => 'foo' }
    }));
}

{
    ok(my $genre = $schema->resultset('Genre')->create({ 
        name => 'Rock', 
        model_cd => $model,
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



done_testing;

