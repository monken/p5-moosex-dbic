package MooseX::DBIC::Meta::Role::Attribute;

use Moose::Role;

after trigger => sub {
    warn "set";
};


1;