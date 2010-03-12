package MyApp::User;
use Moose;

has [qw(first last email)] => ( is => 'rw', isa => 'Str', );

1;