package MooseX::DBIC::Result;

use Moose;
use MooseX::DBIC;

has_column id => (
    isa         => 'Str',
    required    => 1,
    is          => 'rw',
    builder  => '_build_id',
    column_info => { data_type => 'character', size => 10 }
);

sub _build_id  {
    my @chars = ( 'A' .. 'N', 'P' .. 'Z', 0 .. 9 );
    my $id;
    $id .= $chars[ int( rand(@chars) ) ] for ( 1 .. 10 );
    return $id;
}

foreach my $method (qw(delete)) {
    __PACKAGE__->meta->add_method(
        $method => sub {
            my $self   = shift;
            my $return = $self->dbic_result->$method(@_);
            return ref $return eq $self->dbic_result_class ? $self : $return;

        }
    );
}

foreach my $method (qw(insert update)) {
    __PACKAGE__->meta->add_method(
        $method => sub {

            my $self = shift;
            my $row  = $self->dbic_result;
            foreach my $attr ( $self->meta->get_attribute_list, 'id' ) {
                $row->$attr( $self->$attr ) if ( $row->can($attr) );
            }
            $row->$method;
            return $self;

        }
    );
}

__PACKAGE__->meta->make_immutable;
