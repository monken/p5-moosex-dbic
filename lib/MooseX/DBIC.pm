package MooseX::DBIC;

use Moose;

foreach my $method ( qw(update delete insert) ) {
    __PACKAGE__->meta->add_method( $method => sub {
        my $self = shift;
        my $return = $self->dbic_result->$method(@_);
        return ref $return eq $self->dbic_result_class ? $self : $return;
        
    } );
}


__PACKAGE__->meta->make_immutable;