package # hide from PAUSE
    DBICTest::Schema::LyricVersion;

use Moose;
use MooseX::DBIC;

has_column text => ( size => 100 );

belongs_to lyric => ( isa => 'DBICTest::Schema::Lyrics' );

1;
