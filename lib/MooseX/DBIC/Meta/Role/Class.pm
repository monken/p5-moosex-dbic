package MooseX::DBIC::Meta::Role::Class;

use Moose::Role;
use MooseX::ClassAttribute;

class_has column_attribute_metaclass => ( is => 'rw', isa => 'Str', lazy_build => 1 );

sub _build_column_attribute_metaclass {

    return Moose::Meta::Class->create_anon_class(
        superclasses => ['Moose::Meta::Attribute'],
        roles        => [
            qw(MooseX::DBIC::Meta::Role::Attribute MooseX::DBIC::Meta::Role::Attribute::Column)
        ],
        cache => 1,
    )->name;
}

1;