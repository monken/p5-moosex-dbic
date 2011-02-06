package MooseX::DBIC::Role;

use Moose::Role ();
use Moose::Exporter;

my ( $import, $unimport, $init_meta ) = Moose::Exporter->build_import_methods(
    also => 'Moose::Role',
    with_meta =>
      [qw(has_column has_many belongs_to has_one might_have table remove)],
    role_metaroles => {
        role => [
            qw(MooseX::DBIC::Meta::Role::Role MooseX::ClassAttribute::Trait::Role)
        ],
        application_to_class => ['MooseX::DBIC::Meta::Role::Application::ToClass']
    },
    install => [qw(import unimport init_meta)]
);

sub init_meta {
    my $package = shift;
    my %options = @_;
    Moose::Role->init_meta(%options);
    my $meta = $package->$init_meta(%options);
    Moose::Util::ensure_all_roles($meta, 'MooseX::DBIC::Meta::Role::Class');
    Moose::Util::ensure_all_roles($meta->application_to_class_class->meta, 'MooseX::DBIC::Meta::Role::Application::ToClass' );
    return $meta;
}

sub table {
    shift->set_class_attribute_value( 'table_name', shift);
}

sub has_column {
    shift->add_column(@_);
}

sub remove {
    shift->remove_column(shift);
}

sub has_many {
    shift->add_relationship(@_, type => 'HasMany');
}

sub belongs_to {
    shift->add_relationship(@_, type => 'BelongsTo');
}

sub might_have {
    shift->add_relationship(@_, type => 'MightHave');
}

sub has_one {
    shift->add_relationship(@_, type => 'HasOne');
}

1;