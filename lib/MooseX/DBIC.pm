package MooseX::DBIC;

use Moose;

foreach my $method ( qw(update delete) ) {
    __PACKAGE__->meta->add_method( $method => sub {
        my $self = shift;
        my $return = $self->dbic_result->$method(@_);
        return ref $return eq $self->dbic_result_class ? $self : $return;
        
    } );
}


sub insert {
    my $self = shift;
    my $row = $self->dbic_result;
    foreach my $attr( $self->meta->get_attribute_list ) {
        $row->$attr($self->$attr) if($row->can($attr));
    }
    $row->insert;
    return $self;
}

__PACKAGE__->meta->make_immutable;