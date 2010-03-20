package MySchema;
use Moose;
extends 'MooseX::DBIC::Schema';

__PACKAGE__->load_classes(qw(MyApp::User MyApp::User::Admin));

1;