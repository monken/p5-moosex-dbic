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

sub is_column_changed {}

sub set_columns {}

sub set_column { my ($self, $col, $value) = @_; return $self->$col($value) }

sub get_inflated_columns { my $self = shift; %$self }
1;