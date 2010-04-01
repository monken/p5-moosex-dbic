package MooseX::DBIC::Meta::Role::Attribute::Relationship;

use Moose::Role;

use MooseX::DBIC::Types q(:all);


has type => ( is => 'rw', isa => Relationship, required => 1 ); # merging hashref?

has related_class => ( is => 'rw', isa => 'Str', required => 1, lazy => 1, default => sub {
    my $self = shift;
    if($self->type eq 'HasMany') { return $self->type_constraint->type_parameter->class }
} );

after apply_to_dbic_result_class => sub {
    my ($self, $result) = @_;
    
    if($self->type eq 'BelongsTo' || $self->type eq 'HasSubclass') {
        $result->add_relationship(
            $self->name, $self->related_class->dbic_result_class, { 'foreign.id' => 'self.' . $self->name });
    } elsif($self->type eq 'HasMany') {
        $result->add_relationship(
            $self->name, $self->related_class->dbic_result_class, { 'foreign.' . $result->table => 'self.id' }, {join_type => 'LEFT'});
    }    
};

1;