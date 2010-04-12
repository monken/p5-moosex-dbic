package # hide from PAUSE 
    DBICTest::Schema::CD_to_Producer;

use MooseX::DBIC; with 'DBICTest::Compat';

remove 'id';

has_column attribute => ( isa => 'Int' );

belongs_to cd => ( isa => 'DBICTest::Schema::CD' );

belongs_to producer => ( isa => 'DBICTest::Schema::Producer' );
#  { on_delete => undef, on_update => undef },


1;
