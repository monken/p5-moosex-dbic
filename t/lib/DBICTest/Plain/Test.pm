package # hide from PAUSE 
    DBICTest::Plain::Test;

use Moose;
use MooseX::DBIC; with 'DBICTest::Compat';
    

has_column id => ( is => 'rw', isa => 'Int', column_info => { data_type => 'integer', is_auto_increment => 1 } );
has_column name => ( is => 'rw', isa => 'Str' );

1;
