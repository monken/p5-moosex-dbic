package # hide from PAUSE
    DBICTest::Schema::Link;
  
use Moose;
use MooseX::DBIC;
with 'MooseX::DBIC::Result';

has_column id => ( is => 'rw', isa => 'Num', column_info => {
        data_type => 'integer',
        is_auto_increment => 1} );

has_column [qw(url title)] => ( is => 'rw', isa => 'Str', column_info => {
        data_type => 'varchar',
        size      => 100,
        is_nullable => 1,
});

1;

__END__
package # hide from PAUSE
    DBICTest::Schema::Link;

use base qw/DBICTest::BaseResult/;

use strict;
use warnings;

__PACKAGE__->table('link');
__PACKAGE__->add_columns(
    'id' => {
        data_type => 'integer',
        is_auto_increment => 1
    },
    'url' => {
        data_type => 'varchar',
        size      => 100,
        is_nullable => 1,
    },
    'title' => {
        data_type => 'varchar',
        size      => 100,
        is_nullable => 1,
    },
);
__PACKAGE__->set_primary_key('id');

__PACKAGE__->has_many ( bookmarks => 'DBICTest::Schema::Bookmark', 'link', { cascade_delete => 0 } );

use overload '""' => sub { shift->url }, fallback=> 1;

1;
