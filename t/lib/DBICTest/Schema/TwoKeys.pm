package # hide from PAUSE
    DBICTest::Schema::TwoKeys;

use Moose;
use MooseX::DBIC;

remove 'id';

belongs_to artist => ( isa => 'DBICTest::Schema::Artist' );

belongs_to cd => ( isa => 'DBICTest::Schema::CD' ); #, undef, { is_deferrable => 0, add_fk_index => 0 } );

#has_many fourkeys_to_twokeys => ( isa => ResultSet['DBICTest::Schema::FourKeys_to_TwoKeys'] );

#__PACKAGE__->many_to_many(
#  'fourkeys', 'fourkeys_to_twokeys', 'fourkeys',
#);

1;
