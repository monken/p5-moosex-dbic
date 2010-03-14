package MyApp::User::Admin;
use Moose;
extends 'MyApp::User';

has level => ( is => 'rw', isa => 'Int', );

1;