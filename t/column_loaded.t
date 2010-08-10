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
has_column version => ( required => 1, lazy_build => 1 );
has_many cds => ( isa => ResultSet['CD'] );

sub _build_version { 1 };

#__PACKAGE__->meta->make_immutable;

package MySchema;
use Moose;
extends 'MooseX::DBIC::Schema';

__PACKAGE__->load_classes(qw(Artist CD));

package main;
use Scalar::Util qw(refaddr);
use Test::Exception;
 
my $schema = MySchema->connect( 'dbi:SQLite::memory:' );
$schema->deploy;

my $queries = 0;
$schema->storage->debugcb(sub { print $_[1] if($ENV{DBIC_TRACE}); $queries++; });
$schema->storage->debug(1);

my $artist;

for(1..2) {
    ok($artist = $schema->resultset('Artist')->create({ name => 'Mo', descr => 'Long text', address => 'Singapore', version => 2 }));
    $artist = $schema->resultset('Artist')->search(undef, { columns => [qw(name)] })->first;
    ok(!Artist->meta->get_column('descr')->is_loaded($artist), 'descr is not loaded');
    ok(!Artist->meta->get_column('id')->is_loaded($artist), 'id is not loaded');
    ok(!Artist->meta->get_column('address')->is_loaded($artist), 'address is not loaded');
    throws_ok { is($artist->address, 'Singapore') } qr/not loaded/;
    
    $artist = $schema->resultset('Artist')->search(undef, { columns => [qw(id name)] })->first;
    ok(Artist->meta->get_column('id')->is_loaded($artist), 'id is loaded');
    is($artist->address, 'Singapore');
    ok(Artist->meta->get_column('address')->is_loaded($artist), 'address is loaded');
    is($artist->version, 2);
    is($artist->meta->get_column('descr')->get_value($artist), 'Long text');
    
    Artist->meta->make_immutable;
    
}



done_testing;

