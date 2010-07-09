package Moose::Release;
use Moose;

has [qw(id uploaded author distribution uploaded)] => ( is => 'rw' );

__PACKAGE__->meta->make_immutable;
