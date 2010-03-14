package MooseX::DBIC::Schema;
use Carp;
use Moose;
use MooseX::ClassAttribute;
use MooseX::NonMoose;
use Moose::Util::MetaRole;

extends 'DBIx::Class::Schema';

class_has result_base_class => ( is => 'rw', isa => 'Str', lazy_build => 1 );

class_has attribute_metaclass => ( is => 'rw', isa => 'Str', lazy_build => 1 );

sub _build_attribute_metaclass {

    return Moose::Meta::Class->create_anon_class(
        superclasses => ['Moose::Meta::Attribute'],
        roles        => ['MooseX::DBIC::Meta::Role::Attribute'],
        cache        => 1,
    )->name;
}

sub _build_result_base_class {
    my ($self) = @_;
    my $result = Moose::Meta::Class->create_anon_class(
        superclasses => [qw(DBIx::Class::Core)],
        cache        => 1,
    )->name;
    $result->table('foo');
    $result->add_columns( 'id' );

    $result->set_primary_key(qw(id));
    return $result;
}

sub load_namespaces {
    croak 'not yet implemented';
}

sub load_classes {
    my ( $schema, @load ) = @_;
    $schema = ref $schema if ( ref $schema );

    foreach my $class (@load) {

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

        $schema->register_class( $class => $result_dbic );
    }
}

sub create_moose_result_class {
    my ( $schema, $class ) = @_;

    carp 'The name of the class cannot start with DBIC::'
      if ( $class =~ /^DBIC::/ );

    Class::MOP::load_class($class);

    ( my $table = lc($class) ) =~ s/::/_/g;
    my $result = join( '::', $schema, $class );

    $class->meta->meta->name->create(
        $result,
        superclasses => [ 'MooseX::DBIC', $class ],
        methods      => {
            _build_id => sub {
                my @chars = ( 'A' .. 'N', 'P' .. 'Z', 0 .. 9 );
                my $id;
                $id .= $chars[ int( rand(@chars) ) ] for ( 1 .. 10 );
                return $id;
              }
        },
        cache => 1,
    );

    my $id_attribute = $schema->attribute_metaclass->new(
        id => (
            isa         => 'Str',
            required    => 1,
            is          => 'rw',
            lazy_build  => 1,
            column_info => { data_type => 'character', size => 10 }
        )
    );

    foreach my $attr ( $class->meta->get_all_attributes, $id_attribute ) {
        my $attribute_metaclass = Moose::Meta::Class->create_anon_class(
            superclasses => [ $attr->meta->name, $schema->attribute_metaclass ],
            roles   => ['MooseX::DBIC::Meta::Role::Attribute'],
            methods => {

                #accessor_metaclass => sub { $accessor_metaclass->name }
            },
            cache => 1,
        );

        $result->meta->add_attribute(
            bless( $attr, $attribute_metaclass->name ) );
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
        my $attribute = $moose->meta->get_attribute($attr);
        $result->add_columns(
            $attribute->name => {
                is_nullable => !$attribute->is_required,
                %{ $attribute->column_info || {} }
            }
        );
    }
    return $result;
}

__PACKAGE__->meta->make_immutable;
