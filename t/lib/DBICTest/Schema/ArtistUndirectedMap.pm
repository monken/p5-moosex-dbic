package # hide from PAUSE 
    DBICTest::Schema::ArtistUndirectedMap;

use Moose;
use MooseX::DBIC; with 'DBICTest::Compat';

remove 'id';

has_column [qw(id1 id2)];

belongs_to 'artist' => ( isa => 'DBICTest::Schema::Artist' );

#belongs_to 'artist1' => ( isa => 'DBICTest::Schema::Artist', foreign_key => 'id1' );
#, { on_delete => 'RESTRICT', on_update => 'CASCADE'} );
#sbelongs_to 'artist2' => ( isa => 'DBICTest::Schema::Artist', foreign_key => 'id2' );
#, { on_delete => undef, on_update => undef} );
#has_many mapped_artists => ( isa => ResultSet['DBICTest::Schema::Artist'], foreign_key => 'artist_undirected_maps' );
#  [ {'foreign.artistid' => 'self.id1'}, {'foreign.artistid' => 'self.id2'} ],

1;
