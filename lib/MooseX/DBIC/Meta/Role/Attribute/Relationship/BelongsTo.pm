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
    return { 'foreign.id' => 'self.' . $fk->name };
} 

after apply_to_dbic_result_class => sub {
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