package MooseX::DBIC::Meta::Role::Column;

use Moose::Role;
with 'MooseX::DBIC::Meta::Role::Attribute';
with 'MooseX::Attribute::Deflator::Meta::Role::Attribute';

use MooseX::DBIC::TypeMap;

my $REGISTRY = MooseX::DBIC::TypeMap->get_registry;

has column_info => ( is => 'rw', isa => 'HashRef', lazy_build => 1 )
  ;    # merging hashref?

has data_type => ( is => 'rw', isa => 'Str', lazy_build => 1 );

has size => ( is => 'rw', isa => 'Int' );

has auto_increment => ( is => 'rw', isa => 'Bool', default => 0 );

has primary_key => ( is => 'rw', isa => 'Bool', default => 0 );

has indexed => ( is => 'rw', isa => 'Bool', default => 0 );

sub _build_column_info {
    my $self = shift;
    return {
        data_type         => $self->data_type,
        is_auto_increment => $self->auto_increment,
        is_nullable       => !$self->is_required,
        size              => $self->size,
        $self->is_default_a_coderef ? () : ( default_value => $self->default )
    };
}

sub _build_data_type {
    $REGISTRY->find( shift->type_constraint->name ) || '';
}

after apply_to_result_source => sub {
    my ( $attr, $source ) = @_;

    $source->add_columns( $attr->name => $attr->column_info );

    if ( $attr->primary_key ) {
        $source->set_primary_key( $attr->name );
        $attr->associated_class->name->_primaries( $attr->name );
    }

};

sub is_dirty {
    my ( $attr, $instance, $dirty ) = @_;
    my $cols = $instance->dirty_columns || $instance->dirty_columns({});
    return $cols->{ $attr->name }++ if(defined $dirty);
    my $val = $attr->get_raw_value($instance);
    return $cols->{ $attr->name } if(!ref $val);
    my $raw = $instance->_raw_data->{$attr->name};
    return 1 if(defined $raw ^ defined $val); # either one is undefined
    return 0 if(!defined $raw && !defined $val);
    my $inflated = $attr->inflate($instance, $raw);
    return 0 if($val eq $inflated);
    my $deflated = $attr->deflate($instance);
    return 0 if($deflated eq $raw);
    return 1;
}

after set_value => sub {
    my ($attr, $instance) = @_;
    $attr->is_dirty($instance, 1);
};

sub is_loaded {
    my ( $attr, $instance ) = @_;

    return
         !$instance->in_storage
      || exists $instance->_raw_data->{ $attr->name };
}

sub load_from_storage {
    my ( $self, $instance ) = @_;
    my $pk  = $instance->meta->get_primary_key;
    Moose->throw_error('Primary key column not loaded')
        unless($pk->is_loaded($instance));
    my $name = $pk->name;
    my $row = $instance->result_source->resultset->search(
        undef,
        {
            columns      => $self->name,
            result_class => 'DBIx::Class::ResultClass::HashRefInflator'
        }
    )->find($instance->$name);
    $instance->_raw_data->{$self->name} = $row->{$self->name};
    return $row->{$self->name};
}

before get_value => sub {
    my ($self, $instance) = @_;
    return if($self->has_value($instance) || $self->is_loaded($instance));
    $self->set_raw_value($instance, $self->load_from_storage($instance));
};

after clear_value => sub { shift->is_dirty(shift, 1); };

use MooseX::DBIC::Meta::Role::Method::Accessor;
sub accessor_metaclass { 'MooseX::DBIC::Meta::Role::Method::Accessor' }


1;

__END__

=head2 is_dirty

A column is considered dirty when the associated row is not in storage
or if the column's slot has been set. See L<MooseX::DBIC::Meta::Role::Instance>. 
