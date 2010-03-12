package MyApp::User;
use Moose;

has [qw(last email)] => ( is => 'rw', isa => 'Str', );

has first => ( is => 'rw', isa => 'Str|Undef', clearer => 'clear_first', predicate => 'has_first' );

1;