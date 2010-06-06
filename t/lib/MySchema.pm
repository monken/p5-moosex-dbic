package MySchema;
use Moose;
extends 'MooseX::DBIC::Schema';
use lib qw(t/lib);
with 'MooseX::DBIC::Loader::Moose' => {
    classes => [qw(MyApp::User MyApp::User::Admin)],
    target_namespace => 'MySchema',
};

__PACKAGE__->load_classes(qw(MySchema::MyApp::User MySchema::Moose::Object MySchema::MyApp::User::Admin));

1;