use Test::More;
use strict;
use warnings;
use lib qw(t/lib);

package DBICTest::Schema::AAA;
use Moose;
use MooseX::DBIC;

package DBICTest::Schema;
use Moose;
extends 'MooseX::DBIC::Schema';

__PACKAGE__->load_namespaces('DBICTest::Schema');

package main;
is_deeply([sort DBICTest::Schema->sources], [
 'AAA',
 'Artist',
 'ArtistSourceName',
 'ArtistSubclass',
 'ArtistUndirectedMap',
 'Artwork',
 'Artwork_to_Artist',
 'BindType',
 'Bookmark',
 'BooksInLibrary',
 'CD',
 'CD_to_Producer',
 'Collection',
 'CollectionObject',
 'CustomSql',
 'Employee',
 'Encoded',
 'Event',
 'FileColumn',
 'FourKeys_to_TwoKeys',
 'Genre',
 'Image',
 'LinerNotes',
 'Link',
 'LyricVersion',
 'Lyrics',
 'Money',
 'Owners',
 'Producer',
 'SelfRef',
 'SelfRefAlias',
 'Serialized',
 'Tag',
 'Track',
 'TreeLike',
 'TwoKeys',
 'TypedObject',
 'Year2000CDs']);

done_testing;

