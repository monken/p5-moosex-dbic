package # hide from PAUSE
    DBICTest::Schema::ArtistSubclass;

use Moose;
use MooseX::DBIC; extends 'DBICTest::Schema::Artist';

1;