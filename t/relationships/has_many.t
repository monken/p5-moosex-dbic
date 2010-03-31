use lib qw(../p5-moosex-attribute-deflator/lib);

use Test::More;

package CD;
use Moose;
use MooseX::DBIC;
with 'MooseX::DBIC::Result';
has_column title => ( is => 'rw', isa => 'Str' );
belongs_to artist => ( is => 'rw', isa => 'Artist' );

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
    ok($artist->in_storage, 'Artist is in storage');
    ok(my $cds = $artist->cds);
    isa_ok($cds, 'DBIx::Class::ResultSet');
    ok(my $cd = $artist->create_related('cds' => { title => 'CD1' } ));
    is($cd->artist->id, $artist->id);
}

{
    ok(my $artist = $schema->resultset('CD')->create({ title => 'Mo'}));
}

{
    ok(my $artist = $schema->resultset('Artist')->search(undef, {prefetch => 'cds'})->first);
    ok(my $cds = $artist->cds);
    is($cds->all, 1);
}


{
    ok(my $artist = $schema->resultset('Artist')->first, 'Look up artist');
    ok($artist->in_storage, 'Artist is in storage');
    is($artist->search_related('cds')->all, 1, 'Get cds via search_related');
    is($artist->cds->all, 1, 'Get cds via accessor');
}

done_testing;

