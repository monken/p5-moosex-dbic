package MooseX::DBIC::Schema;
use Carp;
use Moose;
use MooseX::ClassAttribute;
use MooseX::NonMoose;
use Moose::Util::MetaRole;

extends 'DBIx::Class::Schema';

class_has result_base_class => ( is => 'rw', isa => 'Str', lazy_build => 1 );

sub _build_result_base_class {
    my ($self) = @_;
    my $result = Moose::Meta::Class->create_anon_class(
        superclasses => [qw(DBIx::Class::Core)],
        cache        => 1,
    )->name;
    $result->table('foo');
    $result->add_columns(
        id => {
            data_type => 'character',
            size      => 10,
        }
    );

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
        my $result_dbic = $schema->create_dbic_result_class($class);

        my $result_moose =
          $schema->create_moose_result_class( $class, $result_dbic );

#$result_moose->add_class_attribute( dbic_result_class => ( default => $result_dbic ) );

        $result_moose->meta->add_attribute(
            dbic_result => ( is => 'ro', isa => $result_dbic ) );

        $result_dbic->meta->add_method(
            inflate_result => sub {
                my $self = shift->next::method(@_);
                my $moose = $result_moose->new( dbic_result => $self );
                while(my($k,$v) = each %{$self->{_column_data}}) {
                    $moose->$k($v) if(defined $v);
                }
                $moose->id; # lazy build
                return $moose;
            }
        );

        # $user isa DBIx::Class::ResultSource

        $schema->register_class( $class => $result_dbic );
    }
}

sub create_moose_result_class {
    my ( $schema, $class, $result_dbic ) = @_;

    carp 'The name of the class cannot start with DBIC::'
      if ( $class =~ /^DBIC::/ );

    Class::MOP::load_class($class);

    ( my $table = lc($class) ) =~ s/::/_/g;
    my $result = join( '::', $schema, $class );

    $class->meta->meta->name->create(
        $result,
        superclasses => [ 'MooseX::DBIC', $class ],
        methods      => {
            dbic_result_class => sub { $result_dbic },
            _build_id         => sub {
                my @chars = ( 'A' .. 'N', 'P' .. 'Z', 0 .. 9 );
                my $id;
                $id .= $chars[ int( rand(@chars) ) ] for ( 1 .. 10 );
                return $id;
              }
        },
        cache => 1,
    );

    my $id_attribute =
      Moose::Meta::Attribute->new(
        id => ( isa => 'Str', required => 1, is => 'rw', lazy_build => 1 ) );

    foreach my $attr ( $class->meta->get_all_attributes, $id_attribute ) {

        #next unless($attr->has_writer);
        my $accessor_metaclass = Moose::Meta::Class->create_anon_class(
            superclasses => [ $attr->accessor_metaclass ],
            roles        => ['MooseX::DBIC::Meta::Role::Method::Accessor'],
            cache        => 1,
        );

        my $attribute_metaclass = Moose::Meta::Class->create_anon_class(
            superclasses => [ $attr->meta->name ],
            methods      => {
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
    my ( $schema, $class ) = @_;

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

    foreach my $attr ( $class->meta->get_attribute_list ) {
        $attr = $class->meta->get_attribute($attr);
        $result->add_columns(
            $attr->name => { is_nullable => !$attr->is_required } );
    }
    return $result;
}

__PACKAGE__->meta->make_immutable;
