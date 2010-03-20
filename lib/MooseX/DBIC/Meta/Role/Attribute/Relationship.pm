package MooseX::DBIC::Meta::Role::Attribute::Relationship;

use Moose::Role;
with 'MooseX::DBIC::Meta::Role::Attribute::Column';

use Moose::Util::TypeConstraints;

subtype 'Relationship',
    from 'Str',
    via { my $type = $_; grep { $_ eq $type } qw(HasOne HasMany BelongsTo ManyToMany); };

no Moose::Util::TypeConstraints;



has type => ( is => 'rw', isa => 'Relationship', required => 1 ); # merging hashref?

has related_source => ( is => 'rw', isa => 'Str', required => 1 );

after apply_to_dbic_result_class => sub {
    my ($self, $result) = @_;
    
    if($self->type eq 'HasOne') {
        $result->add_relationship(
            $self->name, $self->related_source, { 'foreign.id' => 'self.' . $self->name });
    }
    
};

1;