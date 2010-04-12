package # hide from PAUSE 
    DBICTest::Schema::TypedObject;

use MooseX::DBIC; with 'DBICTest::Compat';

table 'typed_object';

remove 'id';

has_column objectid => ( isa => 'Int', auto_increment => 1, primary_key => 1 );

has_column [qw(type value)];

has_many collection_object => ( isa => ResultSet["DBICTest::Schema::CollectionObject"], foreign_key => 'object' );

#__PACKAGE__->many_to_many( collections => collection_object => "collection" );

1;
