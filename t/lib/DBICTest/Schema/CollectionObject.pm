package # hide from PAUSE 
    DBICTest::Schema::CollectionObject;

use Moose;
use MooseX::DBIC;

remove 'id';

belongs_to collection => (isa => "DBICTest::Schema::Collection" );
belongs_to object => ( isa => "DBICTest::Schema::TypedObject" );

1;
