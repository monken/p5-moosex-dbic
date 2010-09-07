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
use Try::Tiny;

BEGIN{
$Data::Dumper::Maxdepth = 3;
$Data::Dumper::Indent = 1;
$Carp::Verbose = 1;
}
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
    my ( $schema, @classes ) = @_;
    while( my $class = shift @classes) {
        next if ($class =~ /^#/);
        if(ref $class eq "ARRAY") {
            unshift(@classes, @$class);
        } elsif(ref $class eq "HASH") {
            while(my($k,$v) = each %$class) {
                load_classes($k, $v);
            }
        } else {
            $schema->load_class($class);
        }
    }
}

sub load_class {
    my ( $schema, $class ) = @_;
	$schema = ref $schema if ( ref $schema );

    return unless($class);
    
    (my $moniker = $class) =~ s/^\Q$schema\E:://;
    
    my $warn = "";
    try {
        Class::MOP::load_class(join('::', $schema, $class));
        $class = join('::', $schema, $class);
    } catch {
        die $_;
    };
    
    if(!$warn) { try {
        Class::MOP::load_class($class);
    } catch {
        die $_;
    }; }
    
    $schema->add_loaded_class($class);
    
    my $result = $class;
    Moose->throw_error('Use a MooseX::DBIC::Loader to load non MooseX::DBIC class ', $moniker, '.') 
        unless($class->isa('Moose::Object') && $class->does('MooseX::DBIC::Role::Result'));
    $result->moniker($moniker);
    $result->_orig($result);
    #$schema->load_classes(@defer);
    
    my $source = $schema->create_result_source( $class, $result );
    
    $schema->class_mappings->{$result} = $moniker;
    $schema->register_source( $moniker => $source );
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
    } or do { die $@ if($@ !~ /^Can't locate/) };
    
    return $source;
}

1;