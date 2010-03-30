package MyApp::Role::Hair;

use Moose::Role;

has hair_color => ( is => 'rw', isa => 'Str' );

1;