package MooseX::DBIC::Meta::Role::Relationship;

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

has _foreign_key => ( 
    is => 'rw', 
    isa => 'Str',
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

has [qw(cascade_delete cascade_update)] => ( is => 'rw', isa => 'Bool', default => 0 );

around _process_options => sub {
    my ($orig, $self, $name, $options) = @_;
    $options->{isa} ||= $self->_build_related_class($name, $options->{associated_class});
        
    %$options = ( 
        is => 'rw',
        lazy => 1,
        default =>  $self->_build_builder($name),
        %$options
    );
    $self->$orig($name, $options);
    if($options->{type_constraint}
        && (my $class = MooseX::DBIC::Util::find_result_class($options->{type_constraint}))) {
            $options->{related_class} = $class;
    }
};

sub _build_builder {
    my ($s, $name) = @_;
    return sub {
        my $self = shift;
        $self->_build_relationship($self->meta->get_relationship($name));
    }
}

sub _build_related_class {
    my $self = shift;
    my ($name, $associated_class) = ref $self ? ($self->name, $self->associated_class->name) : @_;
    return MooseX::DBIC::Util::find_related_class($name, $associated_class);
}

sub _build_proxy_class {
    my $attr = shift;
    my $pk = $attr->related_class->meta->get_primary_key;
    MooseX::DBIC::ResultProxy->build_proxy( 
        $attr->related_class =>
            ( 
                copy => [$pk->get_read_method, qw(result_source in_storage)], 
                builder => \&_build_proxy_class_builder
            )
    );
}

sub _build_proxy_class_builder {
    my $self = shift;
    my $pk = $self->meta->get_primary_key;
    $self->result_source->resultset->find($pk->get_value($self));
}

sub is_dirty {
    my ($attr, $self) = @_;
    return 0 unless($attr->has_value($self));
    my $rel = $attr->get_value($self);
    return 0 if($rel->does('MooseX::DBIC::Meta::Role::ResultProxy'));
    return $rel->meta->is_dirty($rel);
}

1;