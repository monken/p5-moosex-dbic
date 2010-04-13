package DBICTest::Compat;

use Moose::Role;
use DateTime;
use DateTime::Format::SQLite;

use MooseX::Attribute::Deflator;

inflate 'DateTime', via { DateTime::Format::SQLite->parse_datetime( $_ ) };

no MooseX::Attribute::Deflator;

sub make_column_dirty {}

sub discard_changes {}

sub ID {}

sub is_column_changed {
    my ($self, $column) = @_;
    return {$self->get_dirty_columns}->{$column};
}

sub set_columns {
    my ($self, $cols) = @_;
    while(my($k,$v) = each %$cols) {
        $self->$k($v);
    }
}

sub set_column { my ($self, $col, $value) = @_; return $self->$col($value) }

sub get_inflated_columns { my $self = shift; %$self }

sub load_components { shift; Class::MOP::load_class('DBIx::Class::' . shift) }

sub field_name_for { return { name => 'artist name' } }

sub has_column_loaded { my $self = shift; return $self->meta->get_attribute(shift)->has_value($self) } 

1;