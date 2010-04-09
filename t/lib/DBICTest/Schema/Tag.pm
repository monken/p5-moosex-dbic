package # hide from PAUSE 
    DBICTest::Schema::Tag;

use MooseX::DBIC;

has_column tag => ( size => 100 );

belongs_to cd => ( isa => 'DBICTest::Schema::CD' );


1;
