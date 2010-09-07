package MooseX::DBIC::Meta::Role::Instance;

use Moose::Role;

override inline_set_slot_value => sub {
    my ($self, $instance, $slot_name, $value) = @_;
    $self->inline_mark_dirty($instance, $slot_name) . $/ . super;
};

sub inline_mark_dirty {
    my ($self, $instance, $slot_name) = @_;
    return $instance . '->{dirty_columns}->{'. $slot_name .'}++;';
}

sub inline_mark_not_dirty {
    my ($self, $instance, $slot_name) = @_;
    return 'delete ' . $instance . '->{dirty_columns}->{'. $slot_name .'};';
}

1;