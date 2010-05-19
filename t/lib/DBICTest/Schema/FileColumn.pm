package 
DBICTest::Schema::FileColumn;

use MooseX::DBIC; with 'DBICTest::Compat';
use File::Temp qw/tempdir/;

table 'file_columns';

remove 'id';

has_column id => ( isa => 'Int', auto_increment => 1, primary_key => 1 );
has_column 'file';
# tempdir(CLEANUP => 1),

1;
