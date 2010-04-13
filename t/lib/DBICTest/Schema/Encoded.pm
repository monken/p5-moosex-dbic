package    # hide from PAUSE
  DBICTest::Schema::Encoded;

use MooseX::DBIC;
with 'DBICTest::Compat';

remove 'id';

has_column id => (
    isa            => 'Int',
    auto_increment => 1,
    primary_key    => 1
);

has_column encoded => (
    size    => 100,
    trigger => \&encode
);

has_many keyholders => (
    isa => ResultSet ['DBICTest::Schema::Employee'],
    foreign_key => 'secretkey'
);

sub encode {
    my ( $self, $value, $old ) = @_;
    return unless $value;
    return if($self->in_storage && !defined $old);
    $value = reverse split '', $value;
    $self->meta->get_attribute('encoded')->set_raw_value( $self, $value );
}

1;
