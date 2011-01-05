package MooseX::DBIC::Role::Set::Audit;

use Moose::Role;

sub current {
    my $self = shift;
    $self->{attrs}->{where} = { %{$self->{attrs}->{where}||{}}, $self->current_source_alias . '.current' => undef };
    return $self;
}

override new => sub {
    my $self = super();
    return $self->current;
};

1;