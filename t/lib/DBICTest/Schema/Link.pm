package # hide from PAUSE
    DBICTest::Schema::Link;
  
use Moose;
use MooseX::DBIC; with 'DBICTest::Compat';
    
remove 'id';
has_column id => ( isa => 'Int', auto_increment => 1, primary_key => 1 );

has_column [qw(url title)] => ( size => 100 );

has_many bookmarks => ( isa => ResultSet['DBICTest::Schema::Bookmark'], foreign_key => 'link' );

use overload '""' => sub { shift->url }, fallback=> 1;

1;
