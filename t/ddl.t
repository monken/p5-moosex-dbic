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
    

has_column [qw(name descr)];
has_many cds => ( isa => ResultSet['CD'] );

__PACKAGE__->meta->make_immutable;

package MySchema;
use Moose;
extends 'MooseX::DBIC::Schema';

__PACKAGE__->load_classes(qw(Artist CD));

package main;
use Scalar::Util qw(refaddr);
use Test::Exception;
 
my $schema = MySchema->connect( 'dbi:SQLite::memory:' );
$schema->deploy;

is(CD->meta->get_column('artist')->size, 10);



done_testing;

