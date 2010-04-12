package MooseX::DBIC::Meta::Role::Attribute::Relationship::BelongsTo;

use Moose::Role;
with 'MooseX::DBIC::Meta::Role::Attribute::Column';
with 'MooseX::DBIC::Meta::Role::Attribute::Relationship';

use MooseX::DBIC::Types q(:all);
use List::Util qw(first);

sub _build_foreign_key {
    shift
}
sub _build_join_condition {
    my $self = shift;
    my $fk = $self->foreign_key;
    my $pk = $self->related_class->meta->get_primary_key;
    Moose->throw_error(q(Couldn't find primary key for class ), 
                       $self->related_class, 
                       qq(. Please add a join_condition to ),
                       $self->name, q( in class ), $self->associated_class->name )
        unless($pk);
    return { 'foreign.' . $pk->name => 'self.' . $fk->name };
} 

after apply_to_result_source => sub {
    my ($self, $result) = @_;
    $result->add_relationship(
        $self->name, 
        $self->related_class, 
        $self->join_condition, 
        {join_type => $self->join_type}
    );
};

sub _build_related_class { die; }

sub _build_join_type {
    shift->is_required ? '' : 'LEFT';
}

sub reverse_relationship {
    my $self = shift;
    return first { $_->foreign_key eq $self } $self->related_class->meta->get_all_relationships;
}

sub BUILD {
    die @_;
}

sub build_options {
    my ($class, $for, $name, %options) = @_;
     return (
            is => 'rw',
            %options,
            isa => Result,
            related_class => $options{isa},
            lazy => 1,
            default => sub { my $self = shift; return $self->_build_relationship($self->meta->get_attribute($name)); } 
    );
}

1;