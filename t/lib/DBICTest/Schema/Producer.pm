package # hide from PAUSE 
    DBICTest::Schema::Producer;

use MooseX::DBIC; with 'DBICTest::Compat';

remove 'id';

has_column producerid => ( isa => 'Int', auto_increment => 1, primary_key => 1 );
has_column name => ( size => 100 );

has_many producer_to_cd => ( isa => ResultSet['DBICTest::Schema::CD_to_Producer'] );

#__PACKAGE__->many_to_many('cds', 'producer_to_cd', 'cd');
1;
