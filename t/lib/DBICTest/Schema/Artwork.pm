package # hide from PAUSE
    DBICTest::Schema::Artwork;

use MooseX::DBIC;

belongs_to cd => ( isa => 'DBICTest::Schema::CD' );
has_many images => ( isa => ResultSet['DBICTest::Schema::Image'] );
has_many artwork_to_artist => ( isa => ResultSet['DBICTest::Schema::Artwork_to_Artist'] );
#many_to_many('artists', 'artwork_to_artist', 'artist');

1;
