package MooseX::DBIC;

use Moose;
use MooseX::DBIC::Meta::Role::Class;
use Moose::Exporter;

Moose::Exporter->setup_import_methods( with_meta => [qw(has_column has_many belongs_to )] );


sub init_meta {
    shift;
    my %p = @_;
    return Moose::Util::MetaRole::apply_metaclass_roles(
        for             => $p{for_class},
        role_metaroles => {
            role => [qw(MooseX::DBIC::Meta::Role::Class)],

        },
        class_metaroles => {
            class => [qw(MooseX::DBIC::Meta::Role::Class)],
        },
    );
}

sub has_column {
    my $meta    = shift;
    my $name    = shift;
    my %options = @_;
    $options{traits} ||= [];
    push(@{$options{traits}}, qw(MooseX::DBIC::Meta::Role::Attribute MooseX::DBIC::Meta::Role::Attribute::Column MooseX::Attribute::Deflator::Meta::Role::Attribute));
    
    my $attrs = ref $name eq 'ARRAY' ? $name : [$name];
    
    foreach my $attr ( @{$attrs} ) {
        $meta->add_attribute( $attr => %options );
    }
}

sub has_many {
    my $meta    = shift;
    my $name    = shift;
    my %options = (
        traits => [], 
        @_, 
        type => 'HasMany', 
        lazy => 1, 
        default => sub { my $self = shift; return $self->_build_related_resultset($self->meta->get_attribute($name)); } 
    );
    push(@{$options{traits}}, qw(MooseX::DBIC::Meta::Role::Attribute MooseX::DBIC::Meta::Role::Attribute::Relationship MooseX::Attribute::Deflator::Meta::Role::Attribute));
    
    my $attrs = ref $name eq 'ARRAY' ? $name : [$name];
    
    foreach my $attr ( @{$attrs} ) {
        $meta->add_attribute( $attr => %options );
    }
}

sub belongs_to {
    shift->add_relationship(@_, type => 'BelongsTo');    
}


1;
