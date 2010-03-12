package MooseX::DBIC::Meta::Role::Instance;

use Moose::Role;

sub inline_slot_access {
    my ($self, $instance, $slot_name) = @_;
    return sprintf q[%s->{"%s"}], $instance, quotemeta($slot_name) if($slot_name eq 'dbic_result');
    sprintf q[%s->dbic_result->%s], $instance, quotemeta($slot_name);
}

sub inline_get_slot_value {
    my ($self, $instance, $slot_name) = @_;
    $self->inline_slot_access($instance, $slot_name);
}

sub inline_set_slot_value {
    my ($self, $instance, $slot_name, $value) = @_;
    $self->inline_slot_access($instance, $slot_name) . "($value)",
}

sub inline_initialize_slot {
    my ($self, $instance, $slot_name) = @_;
    return '';
}

sub inline_deinitialize_slot {
    my ($self, $instance, $slot_name) = @_;
    "delete " . $self->inline_slot_access($instance, $slot_name);
}
sub inline_is_slot_initialized {
    my ($self, $instance, $slot_name) = @_;
    "exists " . $self->inline_slot_access($instance, $slot_name);
}

sub inline_weaken_slot_value {
    my ($self, $instance, $slot_name) = @_;
    sprintf "Scalar::Util::weaken( %s )", $self->inline_slot_access($instance, $slot_name);
}

sub inline_strengthen_slot_value {
    my ($self, $instance, $slot_name) = @_;
    $self->inline_set_slot_value($instance, $slot_name, $self->inline_slot_access($instance, $slot_name));
}

sub inline_rebless_instance_structure {
    my ($self, $instance, $class_variable) = @_;
    "bless $instance => $class_variable";
}


1;