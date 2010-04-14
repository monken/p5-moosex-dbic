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
    my ($self, $source) = @_;
    
    $source->add_columns(
        $self->name => $self->column_info);
        
    if($self->primary_key) {
        $source->set_primary_key($self->name);
        $self->associated_class->name->_primaries($self->name);
    }
};

1;