package # hide from PAUSE 
    DBICTest::Schema::LinerNotes;

use MooseX::DBIC;

has_column notes => ( size => 100 );

belongs_to cd => ( isa => 'DBICTest::Schema::CD' );

1;
