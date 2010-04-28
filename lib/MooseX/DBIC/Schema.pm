package MooseX::DBIC::Schema;
use Carp;
use Moose 1.01;
use MooseX::ClassAttribute;
use Moose::Util::MetaRole;
use MooseX::DBIC::Types q(:all);
use MooseX::Attribute::Deflator::Moose;
use MooseX::Attribute::Deflator::Structured;
use MooseX::DBIC::Util ();
use Data::Dumper;


$Data::Dumper::Maxdepth = 3;
$Data::Dumper::Indent = 1;
$Carp::Verbose = 1;

extends 'DBIx::Class::Schema';

class_has result_source_class => ( is => 'rw', isa => 'Str', lazy_build => 1 );

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

sub _build_result_source_class {
    my ($self) = @_;
    return 'DBIx::Class::ResultSource::Table';
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
    
    my $warn;
    eval {
        Class::MOP::load_class(join('::', $schema, $class));
        $moniker = $class;
        $class = join('::', $schema, $class);
    } or do { $warn = $@; } and eval {
        
        Class::MOP::load_class($class);
    } or do {
        die $warn || $@;
    };
    
    $schema->add_loaded_class($class);
    
    unless($class->isa('Moose::Object')) {
        warn $moniker, ' isa DBIx::Class';
        $schema->next::method($moniker);
        return $schema->load_classes(@defer);
    }
    
    my $result = $class->does('MooseX::DBIC::Role::Result') ? $class : $schema->create_result_class($moniker);
    
    # TODO: use a class attribute for this
    #unless($class eq 'Moose::Object') {
        $result->moniker($moniker);
        #$class->meta->make_immutable($class->meta->immutable_options);
    #}
    $schema->load_classes(@defer);
    
    my $source = $schema->create_result_source( $class, $result );
    
    $schema->class_mappings->{$result} = $moniker;
    $schema->register_source( $moniker => $source );
}


sub create_result_class {
    my ( $schema, $class ) = @_;

    my $result =  $schema . '::' . $class ;
    
    my $result_metaclass = $class->meta->create_anon_class(
        superclasses => [ $class->meta->meta->name ],
        roles => [qw(MooseX::DBIC::Meta::Role::Class MooseX::ClassAttribute::Trait::Class)],
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
        roles => ['MooseX::DBIC::Role::Result'],
        cache        => 1,
    );

    foreach my $attr ( $class->meta->get_attribute_list ) {
        my $attribute           = $class->meta->get_attribute($attr);
        my $attribute_metaclass = Moose::Meta::Class->create_anon_class(
            superclasses => [ $attribute->meta->name ],
            roles        => ['MooseX::DBIC::Meta::Role::Column','MooseX::Attribute::Deflator::Meta::Role::Attribute'],
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

sub create_result_source {
    my ( $schema, $class, $moose ) = @_;
    Class::MOP::load_class($class);
    Class::MOP::load_class($schema->result_source_class);

    my $source = $schema->result_source_class->new({name => $moose->table_name, result_class => $moose});
    

    foreach my $attr ( $moose->meta->get_attribute_list ) {
        my $attribute = $moose->meta->find_attribute_by_name($attr);
        next
          unless (
            $attribute->does('MooseX::DBIC::Meta::Role::Attribute')
          );
        $attribute->apply_to_result_source($source);
    }
    
    my $resultset = $class . '::Set';
    eval {
        Class::MOP::load_class($resultset);
        $source->resultset_class($resultset);
    } or do { warn $@ if($@ !~ /^Can't locate/) };
    
    return $source;
}

1;