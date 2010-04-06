package MooseX::DBIC::Schema;
use Carp;
use Moose;
use MooseX::ClassAttribute;
use Moose::Util::MetaRole;
use MooseX::DBIC::Types q(:all);
use MooseX::Attribute::Deflator::Moose;
use MooseX::Attribute::Deflator::Structured;
use Data::Dumper;

$Data::Dumper::Maxdepth = 2;
$Data::Dumper::Indent = 1;
$Carp::Verbose = 1;

BEGIN {$ENV{DBIC_TRACE}=1}

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

    return unless($class);
    
    if(ref $class eq "ARRAY") {
        unshift(@defer, @$class);
        $class = shift(@defer);
    } elsif(ref $class eq "HASH") {
        while(my($k,$v) = each %$class) {
            load_classes($k, $v);
        }
        return $schema->load_classes(@defer);
    }
    
    return $schema->load_classes(@defer) if ($class =~ /^#/);
    
    my $moniker = $class;
    
    eval {
        Class::MOP::load_class(join('::', $schema, $class));
        $moniker = $class;
        $class = join('::', $schema, $class);
    } or do {
        Class::MOP::load_class($class);
    };
    
    $schema->add_loaded_class($class);
    
    unless($class->can('meta')) { # FIXME: test for role
        $schema->next::method($moniker);
        return $schema->load_classes(@defer);
    }
        
    my $result_moose = $class->does('MooseX::DBIC::Result') ? $class : $schema->create_moose_result_class($moniker);

    if($class->does('MooseX::DBIC::Result')) {
        $class->meta->add_method( schema_class => sub { $schema } );
        
    }
    $class->meta->add_method( dbic_result_class => sub { join( '::', $schema, 'DBIC', $moniker ); } );
    $class->meta->add_method( moniker => sub {$moniker} );
    

    $schema->load_classes(@defer);
    
    
    my $result_dbic =
      $schema->create_dbic_result_class( $class, $result_moose );

    $result_dbic->result_class($result_moose);
    my $map = $schema->class_mappings;
    $map->{$result_dbic} = $moniker;
    $schema->register_source( $moniker => $result_dbic->result_source_instance );
	
	
}


sub create_moose_result_class {
    my ( $schema, $class ) = @_;

    carp 'The name of the class cannot start with DBIC::'
      if ( $class =~ /^DBIC::/ );

    ( my $table = lc($class) ) =~ s/::/_/g;
    my $result =  $schema . '::' . $class ;
    
    my $result_metaclass = $class->meta->create_anon_class(
        superclasses => [ $class->meta->meta->name ],
        roles => ['MooseX::DBIC::Meta::Role::Class'],
        cache        => 1,
    )->name;
    
    my @superclasses = map {
        $schema->load_classes($_)
          unless ( $schema->is_class_loaded($_) );
        join( '::', $schema, $_);
    } $class->meta->superclasses;
    $result_metaclass->create(
        $result,
        superclasses => [ $class, @superclasses,  ],
        roles => ['MooseX::DBIC::Result'],
        cache        => 1,
    );
    
    $result->meta->add_method( schema_class => sub { $schema } );

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

    foreach my $superclass ($class->meta->superclasses) {
        $schema->load_classes($superclass)
          unless ( $schema->is_class_loaded($superclass) );
        my $related = join( '::', $schema, $superclass);
        ( my $table = lc($superclass) ) =~ s/::/_/g;
        $result->meta->add_relationship($table => ( type => 'HasSuperclass', isa => $related));
    }

    return $result;
}

sub create_dbic_result_class {
    my ( $schema, $class, $moose ) = @_;

    carp 'The name of the class cannot start with DBIC::'
      if ( $class =~ /^DBIC::/ );

    Class::MOP::load_class($class);

    ( my $table = lc($class->moniker) ) =~ s/::/_/g;
    my $result = join( '::', $schema, 'DBIC', $class->moniker );
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