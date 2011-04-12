use Test::More;
use SQL::Translator;

package Label;
use Moose;
use MooseX::DBIC;

package CD;
use Moose;
use MooseX::DBIC;
    
has_column 'title';
belongs_to artist => ( isa => 'Artist', predicate => 'has_artist' );

package Artist;
use Moose;
use MooseX::DBIC;
use DateTime;
with 'Audit';
use MooseX::Attribute::Deflator;

use DateTime::Format::SQLite;
inflate 'DateTime', via { DateTime::Format::SQLite->parse_datetime( $_ ) };
deflate 'DateTime', via { "$_" };

no MooseX::Attribute::Deflator;
#with_rs 'Audit';

has_column 'name';
has_many cds => ( isa => 'CD' );
has_column created_on => ( isa => 'DateTime', default => sub { DateTime->now }, required => 1 );
belongs_to label => ();


package Artist::Set;
use Moose;
extends 'DBIx::Class::ResultSet';
with 'MooseX::DBIC::Role::Set::Audit';

package MySchema;
use Moose;
extends 'MooseX::DBIC::Schema';

__PACKAGE__->load_classes(qw(Artist Label CD));

package main;

use Scalar::Util qw(refaddr);

my $schema = MySchema->connect( 'dbi:SQLite::memory:' );
$schema->deploy;
my $queries = 0;
$schema->storage->debugcb(sub { diag $_[1] if($ENV{DBIC_TRACE}); $queries++; });
$schema->storage->debug(1);

{
    ok(my $artist = $schema->resultset('Artist')->create({ name => 'Mo', label => {} }), 'Create new artist');
    $artist->name("Peter");
    $artist->update;
    ok(!$artist->meta->get_relationship('label')->is_dirty($artist), 'Label rel is not dirty');
    ok(!$artist->meta->get_column('label')->is_dirty($artist), 'Label column is not dirty');
    
    $artist->update({ name => "Löscher" });
    $artist->created_on->add(days => 2);
    ok($artist->meta->get_column('created_on')->is_dirty($artist), 'DateTime column is dirty');
    $artist->update;
}

{
    is($schema->resultset('Artist')->all, 1, 'Default search finds one record only');
    my $artist = $schema->resultset('Artist')->first;
    is(my @revisions = $artist->versions->all, 3, 'Artist has three previous versions');
    is($revisions[0]->name, 'Löscher', 'Correct name');
    is($revisions[1]->name, 'Peter', 'Correct name');
    is($revisions[2]->name, 'Mo', 'Correct name');
    }



done_testing;

