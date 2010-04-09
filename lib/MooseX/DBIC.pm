package MooseX::DBIC;
# ABSTRACT: foo
use Moose ();
use MooseX::DBIC::Meta::Role::Class;
use MooseX::DBIC::Types qw(ResultSet);
use Moose::Exporter;

my ( $import, $unimport, $init_meta ) = Moose::Exporter->build_import_methods( 
  also => 'Moose', 
  with_meta => [qw(has_column has_many belongs_to has_one might_have table)],
  as_is => [qw(ResultSet)],
  metaclass_roles => [qw(MooseX::DBIC::Meta::Role::Class MooseX::ClassAttribute::Trait::Class)],
  install => [qw(import unimport init_meta)]
);

sub init_meta {
    my $package = shift;
    my %options = @_;
    Moose->init_meta(%options);
    my $meta = $package->$init_meta(%options);
    Moose::Util::ensure_all_roles($meta, qw(MooseX::DBIC::Role::Result));
    return $meta;
}

sub table {
    shift->set_class_attribute_value( 'table_name', shift);
}

sub has_column {
    shift->add_column(@_);
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
