package # hide from PAUSE 
    DBICTest::Schema::LinerNotes;

use MooseX::DBIC;

remove 'id';

has_column liner_id => ( isa => 'Int', auto_increment => 1, primary_key => 1 );

has_column notes => ( size => 100 );

belongs_to cd => ( isa => 'DBICTest::Schema::CD' );

1;
