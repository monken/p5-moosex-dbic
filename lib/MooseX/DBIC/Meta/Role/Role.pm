package MooseX::DBIC::Meta::Role::Role;

use Moose::Role;
with 'MooseX::DBIC::Meta::Role::Class';
sub composition_class_roles { die;'MooseX::DBIC::Meta::Role::CompositeRole' }

1;