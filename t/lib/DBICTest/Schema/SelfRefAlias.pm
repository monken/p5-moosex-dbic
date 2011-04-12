package # hide from PAUSE 
    DBICTest::Schema::SelfRefAlias;

    
use Moose;
use MooseX::DBIC; with 'DBICTest::Compat';

table 'self_ref_alias';
remove 'id';
has_column id => ( isa => 'Int', auto_increment => 1, primary_key => 1 );

belongs_to self_ref => ( isa => 'DBICTest::Schema::SelfRef' );
belongs_to alias => ( isa => 'DBICTest::Schema::SelfRef' );

1;
