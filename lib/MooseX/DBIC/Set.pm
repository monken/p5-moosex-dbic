package MooseX::DBIC::Set;
use base 'DBIx::Class::ResultSet';
use DBIx::Class::ResultClass::HashRefInflator;

sub order_by {
    my ( $self, $order ) = @_;
    return $self unless $order;
    my $current = $self->{attrs}->{order_by};
    $current = [$current]
      if (    ref $current eq 'HASH'
           || ref $current eq 'SCALAR'
           || !ref $current );
    $self->throw_exception(
                       'Cannot handle order_by clause of type ' . ref $current )
      unless ( ref $current eq 'ARRAY' );
    unshift( @{$current}, ( ref $order eq 'ARRAY' ? @{$order} : $order ) );
    return $self->search( undef, { order_by => $current } );
}

sub hri {
    shift->search( undef,
                   {  result_class =>
                        'DBIx::Class::ResultClass::HashRefInflator'
                   } );
}

{
    no strict 'refs';
    foreach my $attr (
        qw(offset rows page columns prefetch where having group_by join select as)
      )
    {
        *{$attr} = sub {
            my $self = shift;
            $self->search( undef, { $attr => @_ > 1 ? [@_] : @_ } );
          }
    }

    foreach my $attr (qw(cache distinct)) {
        *{$attr} = sub {
            my $self = shift;
            $self->search( undef, { $attr => defined $_[0] ? $_[0] : 1 } );
          }
    }
}

sub for_update {
    shift->search( undef, { for => 'update' } );
}

sub for_shared {
    shift->search( undef, { for => 'shared' } );
}
1;
