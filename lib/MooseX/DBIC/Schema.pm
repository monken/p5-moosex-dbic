package MooseX::DBIC::Schema;
use Carp;
use Moose;
use MooseX::ClassAttribute;
use Moose::Util::MetaRole;
use MooseX::DBIC::Types q(:all);

extends 'DBIx::Class::Schema';

class_has result_base_class => ( is => 'rw', isa => 'Str', lazy_build => 1 );

class_has loaded_classes => (
    is      => 'rw',
    isa     => 'ArrayRef[Str]',
    traits  => ['Array'],
    default => sub { [] },
    handles => {
        add_loaded_class  => 'push',
        find_loaded_class => 'first',
    }
);


sub is_class_loaded {
    my $schema = shift;
    my $class  = shift;
    return $schema->find_loaded_class( sub { $_ eq $class } );
}

sub _build_result_base_class {
    my ($self) = @_;
    my $result = Moose::Meta::Class->create_anon_class(
        superclasses => [qw(DBIx::Class::Core)],
        cache        => 1,
    )->name;
    $result->table('foo');
    $result->add_columns('id');

    $result->set_primary_key(qw(id));
    return $result;
}

sub load_namespaces {
    croak 'not yet implemented';
}

sub load_classes {
    my ( $schema, $class, @defer ) = @_;
    $schema = ref $schema if ( ref $schema );

    $schema->add_loaded_class($class);

    Class::MOP::load_class($class);
    my $result_moose = $class->does('MooseX::DBIC::Result') ? $class : $schema->create_moose_result_class($class);

    my $result_dbic =
      $schema->create_dbic_result_class( $class, $result_moose );

    $result_moose->meta->add_method( dbic_result_class => sub { $result_dbic },
    );

    $schema->register_class( $class => $result_dbic );

    $result_dbic->result_class($result_moose);

    $schema->register_class( $class => $result_dbic );

    $schema->load_classes(@defer) if (@defer);

}


sub create_moose_result_class {
    my ( $schema, $class ) = @_;

    carp 'The name of the class cannot start with DBIC::'
      if ( $class =~ /^DBIC::/ );

    ( my $table = lc($class) ) =~ s/::/_/g;
    my $result = join( '::', $schema, $class );
    
    my $result_metaclass = $class->meta->create_anon_class(
        superclasses => [ $class->meta->meta->name ],
        roles => ['MooseX::DBIC::Meta::Role::Class'],
        cache        => 1,
    )->name;
    
    $result_metaclass->create(
        $result,
        superclasses => [ $class ],
        roles => ['MooseX::DBIC::Result'],
        cache        => 1,
    );

    foreach my $attr ( $class->meta->get_attribute_list ) {
        my $attribute           = $class->meta->get_attribute($attr);
        my $attribute_metaclass = Moose::Meta::Class->create_anon_class(
            superclasses => [ $attribute->meta->name ],
            roles        => ['MooseX::DBIC::Meta::Role::Attribute::Column','MooseX::Attribute::Deflator::Meta::Role::Attribute'],
            cache        => 1,
        );

        $result->meta->add_attribute(
            bless( $attribute, $attribute_metaclass->name ) );
    }

    my ( undef, $superclass ) = $class->meta->linearized_isa;

    if ($superclass) {
        $schema->load_classes($superclass)
          unless ( $schema->is_class_loaded($superclass) );
        my $related_source = join( '::', $schema, 'DBIC', $superclass );
        my $related_result = join( '::', $schema, $superclass );
        ( my $table = lc($superclass) ) =~ s/::/_/g;
        my @handles = map { $result->meta->remove_attribute($_->name); $_->name } 
                      grep { !$result->meta->has_attribute($_->name) } 
                        $related_result->meta->get_all_columns;
        my $rel = $result->meta->relationship_attribute_metaclass->new(
            $table => (
                is             => 'rw',
                isa            => Result,
                type           => 'BelongsTo',
                related_source => $related_source,
                required       => 1,
                lazy           => 1,
                handles => \@handles,
                default        => sub { my $self = shift; return $self->_build_relationship($self->meta->get_attribute($table)); }
            )
        );
        $result->meta->add_attribute($rel);
    }

    return $result;
}

sub create_dbic_result_class {
    my ( $schema, $class, $moose ) = @_;

    carp 'The name of the class cannot start with DBIC::'
      if ( $class =~ /^DBIC::/ );

    Class::MOP::load_class($class);

    ( my $table = lc($class) ) =~ s/::/_/g;
    my $result = join( '::', $schema, 'DBIC', $class );
    Moose::Meta::Class->create(
        $result,
        superclasses => [ $schema->result_base_class ],
        cache        => 1,
    );
    $result->table($table);

    foreach my $attr ( $moose->meta->get_attribute_list ) {
        #warn $attr;
        my $attribute = $moose->meta->find_attribute_by_name($attr);
        #warn $attribute;
        next
          unless (
            $attribute->does('MooseX::DBIC::Meta::Role::Attribute')
          );
        $attribute->apply_to_dbic_result_class($result);

    }
    return $result;
}

1;