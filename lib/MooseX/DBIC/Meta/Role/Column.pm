package MooseX::DBIC::Meta::Role::Column;

use Moose::Role;
with 'MooseX::DBIC::Meta::Role::Attribute';

use MooseX::DBIC::TypeMap;

my $REGISTRY = MooseX::DBIC::TypeMap->get_registry;

has column_info => ( is => 'rw', isa => 'HashRef', lazy_build => 1 ); # merging hashref?

has data_type => ( is => 'rw', isa => 'Str', lazy_build => 1 );

has size => ( is => 'rw', isa => 'Int' );

has auto_increment => ( is => 'rw', isa => 'Bool', default => 0 );

has primary_key => ( is => 'rw', isa => 'Bool', default => 0 );

sub _build_dirty {
    return !shift->associated_class->in_storage;
}

sub _build_column_info {
    my $self = shift;
    return {
        data_type => $self->data_type,
        is_auto_increment => $self->auto_increment,
        is_nullable => !$self->is_required,
        size => $self->size,
        $self->is_default_a_coderef ? () : ( default_value => $self->default )
    };
}

sub _build_data_type {
    $REGISTRY->find(shift->type_constraint->name) || '';
}

after apply_to_result_source => sub {
    my ($attr, $source) = @_;
    
    $source->add_columns(
        $attr->name => $attr->column_info);
        
    if($attr->primary_key) {
        $source->set_primary_key($attr->name);
        $attr->associated_class->name->_primaries($attr->name);
    }
};

sub is_dirty {
    my ($attr, $instance) = @_;
    return $instance->dirty_columns && $instance->dirty_columns->{$attr->name};
}

sub is_loaded {
    my ($attr, $instance) = @_;
    
    return $attr->has_value($instance)
        || $attr->is_required # WRONG, a column can be required but not loaded from storage
        || !$instance->in_storage
        || ( $instance->in_storage && exists $instance->_raw_data->{$attr->name} );
}

1;

__END__

=head2 is_dirty

A column is considered dirty when the associated row is not in storage
or if the column's slot has been set. See L<MooseX::DBIC::Meta::Role::Instance>. 