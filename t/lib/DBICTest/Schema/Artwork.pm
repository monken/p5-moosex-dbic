package # hide from PAUSE
    DBICTest::Schema::Artwork;

use MooseX::DBIC; with 'DBICTest::Compat';

remove 'id';

has_column id => ( isa => 'Int', auto_increment => 1, primary_key => 1 );

belongs_to cd => ( isa => 'DBICTest::Schema::CD' );
#has_many images => ( isa => ResultSet['DBICTest::Schema::Image'] );
#has_many artwork_to_artist => ( isa => ResultSet['DBICTest::Schema::Artwork_to_Artist'] );
#many_to_many('artists', 'artwork_to_artist', 'artist');

sub artists {
    shift->search_related('artwork_to_artist')->search_related('artist');
}

1;
