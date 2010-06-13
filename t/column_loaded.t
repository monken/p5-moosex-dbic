use Test::More;
use SQL::Translator;

package CD;
use MooseX::DBIC;
    
has_column 'title';
belongs_to artist => ( isa => 'Artist', predicate => 'has_artist' );

package Artist;
use MooseX::DBIC;
use MooseX::DBIC::Types q(:all);
    

has_column [qw(name descr)];
has_column address => ( required => 1 );
has_many cds => ( isa => ResultSet['CD'] );

package MySchema;
use Moose;
extends 'MooseX::DBIC::Schema';

__PACKAGE__->load_classes(qw(Artist CD));

package main;

use Test::Exception;

my $schema = MySchema->connect( 'dbi:SQLite::memory:' );
$schema->deploy;

my $queries = 0;
$schema->storage->debugcb(sub { print $_[1] if($ENV{DBIC_TRACE}); $queries++; });
$schema->storage->debug(1);

my $artist;

TODO: {
    local $TODO = 'Use LazyRequired';
    ok($artist = $schema->resultset('Artist')->create({ name => 'Mo', descr => 'Long text', address => 'Singapore' }));
    lives_ok { 
        $artist = $schema->resultset('Artist')->search(undef, { columns => [qw(name)] })->first;
        ok(!Artist->meta->get_column('descr')->is_loaded($artist));
        ok(!Artist->meta->get_column('address')->is_loaded($artist));
    } '';
}



done_testing;

