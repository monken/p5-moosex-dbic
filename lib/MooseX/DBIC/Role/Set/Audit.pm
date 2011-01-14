package MooseX::DBIC::Role::Set::Audit;

use Moose::Role;

sub current {
    my $self = shift;
    return $self if($self->{attrs}->{_audit_loop});
    return $self->search( { $self->current_source_alias . '.current' => undef}, { _audit_loop => 1 } );
}

override new => sub {
    super()->current;
};

1;