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
        class_metaroles => {
            class => ['MooseX::DBIC::Meta::Role::Class'],
        },
    );
}

sub has_column {
    my $meta    = shift;
    my $name    = shift;
    my %options = @_;

    my $attrs = ref $name eq 'ARRAY' ? $name : [$name];

    foreach my $attr ( @{$attrs} ) {
        my $attr = $meta->column_attribute_metaclass->new( $attr, %options );
        $meta->add_attribute( $attr );
    }
}

1;
