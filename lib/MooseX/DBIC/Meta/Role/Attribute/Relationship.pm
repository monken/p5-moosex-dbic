package MooseX::DBIC::Meta::Role::Attribute::Relationship;

use Moose::Role;

use MooseX::DBIC::Types q(:all);
use List::Util qw(first);


has type => ( is => 'rw', isa => Relationship, required => 1 );

has related_class => ( is => 'rw', isa => 'Str', required => 1, lazy => 1, default => sub {
    my $self = shift;
    if($self->type eq 'HasMany') { return $self->type_constraint->type_parameter->class }
    else { die; return undef }
} );

has foreign_key => ( 
    is => 'rw', 
    isa => 'Moose::Meta::Attribute', 
    required => 1, 
    lazy => 1,
    default => sub {
        my $self = shift;
        if($self->type eq 'HasMany') {
            return $self->related_class->meta->get_attribute($self->associated_class->name->dbic_result_class->table);
        } else {
            return $self;
        }
    }
);

has join_condition => ( 
    is => 'rw', 
    isa => 'HashRef', 
    required => 1, 
    lazy => 1, 
    default => sub {
        my $self = shift;
        my $fk = $self->foreign_key;
        if($fk->associated_class->name eq $self->associated_class->name) {
            return { 'foreign.id' => 'self.' . $fk->name };
        } else {
            return { 'foreign.'.$fk->name => 'self.id' };
        }
    } 
);

after apply_to_dbic_result_class => sub {
    my ($self, $result) = @_;
    
    if($self->type eq 'BelongsTo' || $self->type eq 'HasSuperclass') {
        $result->add_relationship(
            $self->name, $self->related_class->dbic_result_class, $self->join_condition);
    } elsif($self->type eq 'HasMany') {
        $result->add_relationship(
            $self->name, $self->related_class->dbic_result_class, $self->join_condition, {
    accessor => 'multi',
    join_type => 'LEFT',
    cascade_delete => 1,
    cascade_copy => 1,});
    }    
};

sub get_reverse_relationships {
    my ($self) = @_;
    return grep { $_->related_class eq $self->associated_class->name } $self->related_class->meta->get_all_relationships;
}

1;