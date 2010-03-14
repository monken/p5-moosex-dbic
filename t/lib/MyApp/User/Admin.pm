package MyApp::User::Admin;
use Moose;
extends 'MyApp::User';
with 'MyApp::Role::Hair';

has level => ( is => 'rw', isa => 'Int', );

1;