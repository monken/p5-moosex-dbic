use Test::More;
use SQL::Translator;

package CD;
use MooseX::DBIC;
    
has_column 'title';
package MySchema;
use Moose;
extends 'MooseX::DBIC::Schema';

__PACKAGE__->load_classes(qw(CD));

package main;

use Test::Exception;
use Scalar::Util qw(refaddr);

my $schema = MySchema->connect( 'dbi:SQLite::memory:' );
$schema->deploy;

my $cd = $schema->resultset('CD')->new_result({});

isa_ok(CD->meta, 'DBIx::Class::ResultSource');

is(refaddr($cd->result_source), refaddr($cd->meta));

is(refaddr($cd->meta->schema), refaddr($schema));


done_testing;

