package # hide from PAUSE 
    DBICTest::Schema::Lyrics;

use Moose;
use MooseX::DBIC;

belongs_to track => ( isa => 'DBICTest::Schema::Track' );
has_many lyric_versions => ( isa => ResultSet['DBICTest::Schema::LyricVersion'], foreign_key => 'lyric' );

1;
