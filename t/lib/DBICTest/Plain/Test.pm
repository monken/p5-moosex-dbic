package # hide from PAUSE 
    DBICTest::Plain::Test;

use Moose;
use MooseX::DBIC;
    

has_column id => ( is => 'rw', isa => 'Num', column_info => { data_type => 'integer', is_auto_increment => 1 } );
has_column name => ( is => 'rw', isa => 'Str' );

1;
