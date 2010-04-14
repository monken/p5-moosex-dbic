package # hide from PAUSE 
    DBICTest::Schema::SelfRef;

use MooseX::DBIC; with 'DBICTest::Compat';

table 'self_ref';
remove 'id';
has_column id => ( isa => 'Int', auto_increment => 1, primary_key => 1 );

has_column 'name';

has_many aliases => ( isa => ResultSet['DBICTest::Schema::SelfRefAlias'], foreign_key => 'self_ref' );

1;
