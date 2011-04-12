package # hide from PAUSE 
    DBICTest::Schema::Serialized;

use Moose;
use MooseX::DBIC; with 'DBICTest::Compat';

table 'books';
remove 'id';
has_column id => ( isa => 'Int', auto_increment => 1, primary_key => 1 );
has_column 'serialized';

1;
