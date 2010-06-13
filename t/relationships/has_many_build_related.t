use Test::More;
use SQL::Translator;

package Index;
use MooseX::DBIC;
has_many 'artists';
belongs_to 'artist';

package Artist;
use MooseX::DBIC;
has_many 'indices' => ( isa => 'Index' );
belongs_to 'index';

package MySchema;
use Moose;
extends 'MooseX::DBIC::Schema';
use Test::Exception;
use Test::More;


lives_ok { __PACKAGE__->load_classes(qw(Artist Index)) } 'load classes';

is(Artist->meta->get_attribute('indices')->type_constraint->parent, 'MooseX::DBIC::Types::ResultSet');

done_testing;

