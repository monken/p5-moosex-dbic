package # hide from PAUSE 
    DBICTest::Schema::Collection;

use Moose;
use MooseX::DBIC; with 'DBICTest::Compat';

remove 'id';

has_column collectionid => ( isa => 'Num', auto_increment => 1, primary_key => 1 );

has_column name => ( size => 100 );

#__PACKAGE__->has_many( collection_object => "DBICTest::Schema::CollectionObject",
#                       { "foreign.collection" => "self.collectionid" }
#                     );
#__PACKAGE__->many_to_many( objects => collection_object => "object" );
#__PACKAGE__->many_to_many( pointy_objects => collection_object => "object",
#                           { where => { "object.type" => "pointy" } }
#                         );
#__PACKAGE__->many_to_many( round_objects => collection_object => "object",
#                           { where => { "object.type" => "round" } } 
#                         );

1;
