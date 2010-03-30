use lib qw(../p5-moosex-attribute-deflator/lib);

use Test::More;

package CD;
use Moose;
use MooseX::DBIC;
with 'MooseX::DBIC::Result';
has_column title => ( is => 'rw', isa => 'Str' );
has_column artist => ( is => 'rw', isa => 'Str' );

package Artist;
use Moose;
use MooseX::DBIC;
use MooseX::DBIC::Types q(:all);
with 'MooseX::DBIC::Result';

has_column name => ( is => 'rw', isa => 'Str' );
has_many cds => ( is => 'rw', isa => ResultSet['CD'] );

package MySchema;
use Moose;
extends 'MooseX::DBIC::Schema';

__PACKAGE__->load_classes(qw(Artist CD));

package main;

my $schema = MySchema->connect( 'dbi:SQLite::memory:' );

$schema->deploy;


 {
    ok(my $artist = $schema->resultset('Artist')->create({ name => 'Mo'}));
    ok(my $cds = $artist->cds);
    isa_ok($cds, 'DBIx::Class::ResultSet');
}

{
    ok(my $artist = $schema->resultset('Artist')->search(undef, {prefetch => 'cds'})->first);
    ok(my $cds = $artist->cds);
    $cds->all;
}

done_testing;

