package # hide from PAUSE 
    DBICTest::Schema::Image;

use MooseX::DBIC;

has_column name => (size => 100 );
has_column data => ( isa => 'Str', data_type => 'blob' );
belongs_to artwork => ( isa => 'DBICTest::Schema::Artwork' );

1;
