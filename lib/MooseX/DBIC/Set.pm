package MooseX::DBIC::Set;
use base 'DBIx::Class::ResultSet';

sub order_by {
    my ($self, $order) = @_;
    return $self unless $order;
    my $current = $self->{attrs}->{order_by};
    $current = [$current] if(ref $current eq 'HASH' || ref $current eq 'SCALAR' || !ref $current);
    $self->throw_exception('Cannot handle order_by clause of type ' . ref $current)
      unless(ref $current eq 'ARRAY');
    unshift(@{$current}, (ref $order eq 'ARRAY' ? @{$order} : $order));
    return $self->search(undef, { order_by => $current } );
}

sub hri {
    shift->search(undef, { result_class => 'DBIx::Class::ResultClass::HashRefInflator'});
}

{
    no strict 'refs';
foreach my $attr (qw(offset rows page columns prefetch)) {
    *{$attr} = sub {
        my $self = shift;
        shift->search(undef, $attr => @_ > 1 ? [@_] : @_);
    }
}
}
1;