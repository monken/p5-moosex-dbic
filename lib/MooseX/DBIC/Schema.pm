package MooseX::DBIC::Schema;
use Carp;
use Moose;
use MooseX::ClassAttribute;
use MooseX::NonMoose;
use Moose::Util::MetaRole;

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
    my ( $schema, @load ) = @_;
    $schema = ref $schema if ( ref $schema );

    my @register_classes = ();

    foreach my $class (@load) {

        $schema->add_loaded_class($class);

        my $result_moose = $schema->create_moose_result_class($class);

        my $result_dbic =
          $schema->create_dbic_result_class( $class, $result_moose );

        $result_moose->meta->add_method(
            dbic_result_class => sub { $result_dbic }, );

        $result_moose->meta->add_attribute(
            dbic_result => ( is => 'ro', isa => $result_dbic ) );

        $result_dbic->meta->add_method(
            inflate_result => sub {
                my $self = shift->next::method(@_);
                my $moose = $result_moose->new( dbic_result => $self );
                while ( my ( $k, $v ) = each %{ $self->{_column_data} } ) {
                    $moose->$k($v) if ( defined $v );
                }
                $moose->id;    # lazy build
                return $moose;
            }
        );

        push( @register_classes, $class => $result_dbic );
    }
    $schema->register_class(@register_classes);
}

sub create_moose_result_class {
    my ( $schema, $class ) = @_;

    carp 'The name of the class cannot start with DBIC::'
      if ( $class =~ /^DBIC::/ );

    Class::MOP::load_class($class);

    ( my $table = lc($class) ) =~ s/::/_/g;
    my $result = join( '::', $schema, $class );
    Moose::Meta::Class->create(
        $result,
        superclasses => [
            'MooseX::DBIC::Result', $class->meta->isa('Moose::Meta::Role') ? () : $class
        ],
        cache => 1,
    );



    my @attributes;
    if ( $class->meta->isa('Moose::Meta::Role') ) {
        foreach my $attr ( $class->meta->get_attribute_list ) {
            $result->meta->add_attribute( $class->meta->get_attribute($attr)
                  ->attribute_for_class( $result->meta->column_attribute_metaclass ) );
        }
    }
    else {

        foreach my $attr ( $class->meta->get_all_attributes ) {
            my $attribute_metaclass = Moose::Meta::Class->create_anon_class(
                superclasses =>
                  [ $attr->meta->name, $result->meta->column_attribute_metaclass ],
                roles => ['MooseX::DBIC::Meta::Role::Attribute::Column'],
                cache => 1,
            );

            $result->meta->add_attribute(
                bless( $attr, $attribute_metaclass->name ) );
        }
    }

    for my $superclass (
        map { $_->can('name') ? $_->name : $_ }
        $class->meta->calculate_all_roles,
        $class->meta->isa('Moose::Meta::Role')
        ? ()
        : $class->meta->linearized_isa
      )
    {
        $schema->load_classes($superclass)
          unless ( $schema->is_class_loaded($superclass) );
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

    foreach my $attr ( $class->meta->get_attribute_list, 'id' ) {
        my $attribute = $moose->meta->find_attribute_by_name($attr);
        next
          unless (
            $attribute->meta->does_role(
                'MooseX::DBIC::Meta::Role::Attribute')
          );
        $attribute->apply_to_dbic_result_class($result);
        
    }
    return $result;
}

__PACKAGE__->meta->make_immutable;
