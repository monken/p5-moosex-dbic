package # hide from PAUSE 
    DBICTest::Schema::FourKeys_to_TwoKeys;

use MooseX::DBIC;

has_column [qw(f_foo f_bar f_hello f_goodbye t_artist t_cd autopilot pilot_sequence)];

# __PACKAGE__->belongs_to('fourkeys', 'DBICTest::Schema::FourKeys', {
  # 'foreign.foo' => 'self.f_foo',
  # 'foreign.bar' => 'self.f_bar',
  # 'foreign.hello' => 'self.f_hello',
  # 'foreign.goodbye' => 'self.f_goodbye',
# });

# __PACKAGE__->belongs_to('twokeys', 'DBICTest::Schema::TwoKeys', {
  # 'foreign.artist' => 'self.t_artist',
  # 'foreign.cd' => 'self.t_cd',
# });

1;
