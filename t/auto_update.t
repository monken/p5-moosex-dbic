use Test::More;
use Test::Exception;
use SQL::Translator;

package Artwork;
use MooseX::DBIC;
with 'AutoUpdate';
    
has_column 'image';
has_column lazy => ( lazy_build => 1 );

sub _build_lazy {
    return 'lazy';
}


package MySchema;
use Moose;
extends 'MooseX::DBIC::Schema';

__PACKAGE__->load_classes(qw(Artwork));

package main;

my $schema = MySchema->connect( 'dbi:SQLite::memory:' );

$schema->deploy;
my $queries = 0;
$schema->storage->debugcb(sub { print $_[1] if($ENV{DBIC_TRACE}); $queries++; });
$schema->storage->debug(1);

{
    $queries = 0;
    ok(my $artwork = $schema->resultset('Artwork')->create({ image => 'nice' }), 'Create Artwork');
    $artwork->image('peter');
}

is($queries, 2);

is($schema->resultset('Artwork')->first->image, 'peter');

{
    $queries = 0;
    ok(my $artwork = $schema->resultset('Artwork')->first);
    $artwork->lazy;
}

is($queries, 2);

is($schema->resultset('Artwork')->first->lazy, 'lazy');

throws_ok {
    $queries = 0;
    my $artwork = $schema->resultset('Artwork')->first;
    $artwork->image('hans');
    die 'died';
} qr/died/, 'died';
is($queries, 2, 'updates even if exception is thrown in block');


done_testing;

