package MooseX::DBIC::Meta::Role::Method::Constructor;

use Moose::Role;

override _generate_slot_initializer => sub {
    my $code = super();
    warn $code;
    return $code;
};

1;
