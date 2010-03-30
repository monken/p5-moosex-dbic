package MooseX::DBIC;

use Moose;
use MooseX::ClassAttribute;
use MooseX::DBIC::Meta::Role::Class;
use Moose::Exporter;

Moose::Exporter->setup_import_methods( with_meta => ['has_column'] );

sub init_meta {
    shift;
    my %p = @_;
    return Moose::Util::MetaRole::apply_metaclass_roles(
        for             => $p{for_class},
        role_metaroles => {
            role => ['MooseX::DBIC::Meta::Role::Class'],
        },
    );
}

sub has_column {
    my $meta    = shift;
    my $name    = shift;
    my %options = @_;
    $options{traits} ||= [];
    push(@{$options{traits}}, 'MooseX::DBIC::Meta::Role::Attribute', 'MooseX::DBIC::Meta::Role::Attribute::Column');
    
    my $attrs = ref $name eq 'ARRAY' ? $name : [$name];
    
    foreach my $attr ( @{$attrs} ) {
        $meta->add_attribute( $attr => %options );
    }
}

1;
