package # hide from PAUSE
    DBICTest::Schema::Bookmark;

use Moose;
use MooseX::DBIC;
with 'MooseX::DBIC::Result';

has_column id => ( is => 'rw', isa => 'Num', column_info => {
        data_type => 'integer',
        is_auto_increment => 1} );

belongs_to link => ( isa => 'DBICTest::Schema::Link', is => 'rw' );

__END__
package # hide from PAUSE
    DBICTest::Schema::Bookmark;

    use base qw/DBICTest::BaseResult/;


use strict;
use warnings;

__PACKAGE__->table('bookmark');
__PACKAGE__->add_columns(
    'id' => {
        data_type => 'integer',
        is_auto_increment => 1
    },
    'link' => {
        data_type => 'integer',
        is_nullable => 1,
    },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to(link => 'DBICTest::Schema::Link', 'link', { on_delete => 'SET NULL' } );

1;
