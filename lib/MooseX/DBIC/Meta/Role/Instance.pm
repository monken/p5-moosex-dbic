package MooseX::DBIC::Meta::Role::Instance;

use Moose::Role;

override inline_set_slot_value => sub {
    my ($self, $instance, $slot_name, $value) = @_;
    $instance . '->{dirty_columns}->{'. $slot_name .'}++;' . $/ . super;
};


1;