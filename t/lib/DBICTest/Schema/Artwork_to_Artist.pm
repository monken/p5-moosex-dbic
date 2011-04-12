package # hide from PAUSE
    DBICTest::Schema::Artwork_to_Artist;

use Moose;
use MooseX::DBIC;

belongs_to artwork => ( isa => 'DBICTest::Schema::Artwork' );
belongs_to artist => ( isa => 'DBICTest::Schema::Artist' );

1;
