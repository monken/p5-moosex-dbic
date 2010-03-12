package MooseX::DBIC::Meta::Role::Method::Accessor;

use Moose::Role;

sub _inline_store {
    my ($self, $instance, $value) = @_;
    my $slot_name = $self->associated_attribute->slots;
    return sprintf q[%s->dbic_result->{_column_data}->{"%s"} = %s], $instance, quotemeta($slot_name), $value;
}

sub _inline_get {
    my ($self, $instance) = @_;
    my $slot_name = $self->associated_attribute->slots;
    return sprintf q[%s->dbic_result->{_column_data}->{"%s"}], $instance, quotemeta($slot_name);
}

sub _generate_clearer_method {
    my ($self, $instance) = @_;
    my $slot_name = $self->associated_attribute->slots;
    warn $slot_name;
    my ( $code, $e ) = $self->_eval_closure(
        {},
        'sub {'
        . 'delete $_[0]->dbic_result->{_column_data}->{"' . quotemeta($slot_name) . '"};'
        . '}'
    );
    confess "Could not generate inline clearer because : $e" if $e;

    return $code;
}

sub _generate_predicate_method_inline {
    my ($self, $instance) = @_;
    my $slot_name = $self->associated_attribute->slots;
    warn $slot_name;
    my ( $code, $e ) = $self->_eval_closure(
        {},
        'sub {'
        . 'exists $_[0]->dbic_result->{_column_data}->{"' . quotemeta($slot_name) . '"};'
        . '}'
    );
    confess "Could not generate inline clearer because : $e" if $e;

    return $code;
}

1;