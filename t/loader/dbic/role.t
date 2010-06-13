use Test::More;
package DBICUser;
use base 'DBIx::Class::Core';
__PACKAGE__->table('foo');

package Schema;
use Moose;
extends 'MooseX::DBIC::Schema';

use Test::Exception;

with 'MooseX::DBIC::Loader::DBIC' => {
    classes => [qw(DBICUser)],
    target_namespace => 'Schema'
};

lives_ok { __PACKAGE__->load_classes(qw(Schema::DBICUser)) } '';

package main;

ok(my $schema = Schema->connect('dbi:SQLite::memory:'));

done_testing;
