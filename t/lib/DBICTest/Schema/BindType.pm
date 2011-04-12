package # hide from PAUSE 
    DBICTest::Schema::BindType;

use Moose;
use MooseX::DBIC; with 'DBICTest::Compat';

table 'bindtype_test';
remove 'id';
has_column id => ( isa => 'Int', auto_increment => 1, primary_key => 1 );

has_column bytea => ( data_type => 'bytea' );
has_column blob => ( data_type => 'blob' );
has_column clob => ( data_type => 'clob' );


1;
