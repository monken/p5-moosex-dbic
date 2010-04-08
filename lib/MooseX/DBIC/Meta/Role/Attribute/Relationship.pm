package MooseX::DBIC::Meta::Role::Attribute::Relationship;

use Moose::Role;

use MooseX::DBIC::Types q(:all);
use List::Util qw(first);


has type => ( is => 'rw', isa => Relationship, required => 1 );

has related_class => ( 
    is => 'rw', 
    isa => 'Str', 
    required => 1, 
    lazy => 1, 
    builder => '_build_related_class'
);

has foreign_key => ( 
    is => 'rw', 
    isa => 'Moose::Meta::Attribute', 
    required => 1, 
    lazy => 1,
    weak_ref => 1,
    builder => '_build_foreign_key'
);

has join_condition => ( 
    is => 'rw', 
    isa => 'HashRef', 
    required => 1, 
    lazy => 1, 
    builder => '_build_join_condition'
);

has proxy_class => ( 
    is => 'rw', 
    isa => 'Moose::Meta::Class', 
    lazy => 1, 
    builder => '_build_proxy_class'
);

has join_type => (
    is => 'rw',
    isa => JoinType,
    builder => '_build_join_type',
    lazy => 1,
);

sub _build_proxy_class {
    my $attr = shift;
    MooseX::DBIC::ResultProxy->build_proxy( 
        $attr->related_class =>
            ( copy => [qw(id result_source in_storage)], builder => sub {
                my $self = shift;
                $self->result_source->schema->resultset($attr->related_class)->find($self->id);
            } )
    );
}


1;