package # hide from PAUSE 
    DBICTest::Schema::Money;

use MooseX::DBIC; with 'DBICTest::Compat';

table 'money_test';
remove 'id';
has_column id => ( isa => 'Int', auto_increment => 1, primary_key => 1 );

has_column amount => ( data_type => 'money' );


1;
