use Test::More;
use SQL::Translator;

package CD;
use MooseX::DBIC;
has_column title => ( is => 'rw', isa => 'Str' );
belongs_to artist => ( is => 'rw', isa => 'Artist', predicate => 'has_artist' );

package Artist;
use MooseX::DBIC;
use MooseX::DBIC::Types q(:all);

table 'artists';

has_column name => ( is => 'rw', isa => 'Str' );
has_many cds => ( is => 'rw', isa => ResultSet['CD'], foreign_key => 'artist' );

package MySchema;
use Moose;
extends 'MooseX::DBIC::Schema';

__PACKAGE__->load_classes(qw(Artist CD));

package main;

use Test::Memory::Cycle;

my $weak;

{
  my $schema = MySchema->connect( 'dbi:SQLite::memory:' );

  $schema->deploy;

  my $s = $weak->{schema} = $schema;
  memory_cycle_ok($s, 'No cycles in schema');

  my $rs = $weak->{resultset} = $s->resultset ('Artist');
  memory_cycle_ok($rs, 'No cycles in resultset');

  my $rsrc = $weak->{resultsource} = $rs->result_source;
  memory_cycle_ok($rsrc, 'No cycles in resultsource');

  my $row1 = $weak->{row1} = $s->resultset('Artist')->create({ name => 'Nock', cds => [{title=> 'Foo'}]});
  
        warn Scalar::Util::isweak($row1->cds->first->{artist});
        #Scalar::Util::weaken($row1->cds->first->{artist});
  memory_cycle_ok($row1, 'No cycles in row1');
  
  my $row2 = $weak->{row2} = $s->resultset('CD')->create({ artist => { name => 'Nock'}, title => 'test' });
  memory_cycle_ok($row2, 'No cycles in row2');

  Scalar::Util::weaken ($_) for values %$weak;
  memory_cycle_ok($weak, 'No cycles in weak object collection');
}

for (keys %$weak) {
  ok (! $weak->{$_}, "No $_ leaks");
}


done_testing;
