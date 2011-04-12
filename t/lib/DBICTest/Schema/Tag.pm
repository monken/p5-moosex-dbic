package # hide from PAUSE 
    DBICTest::Schema::Tag;

use Moose;
use MooseX::DBIC;

remove 'id';

has_column tagid => ( isa => 'Int', auto_increment => 1, primary_key => 1 );

has_column tag => ( size => 100 );

belongs_to cd => ( isa => 'DBICTest::Schema::CD' );


1;
