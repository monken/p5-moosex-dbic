
use lib qw(t/lib ../p5-moosex-attribute-deflator/lib);

use Test::More;
use MySchema;

my $schema = MySchema->connect( 'dbi:SQLite::memory:' );

my $ddl = {};

foreach my $source (map { $schema->source($_) } $schema->sources) {
    $ddl->{$source->source_name} = { map { $_ => $source->column_info($_) } $source->columns };
}

#use Data::Dumper; warn Dumper $ddl;

is_deeply($ddl, {
           "Moose::Object"      => { id => {
                                     data_type   => 'character',
                                     is_nullable => '',
                                     size        => 10
                                   } },
           "MyApp::User"        => {
                                     email  => { is_nullable => 1 },
                                     first  => { is_nullable => 1 },
                                     id     => {
                                                 data_type   => 'character',
                                                 is_nullable => '',
                                                 size        => 10
                                               },
                                     last   => { is_nullable => 1 },
                                     moose_object
                                            => { is_nullable => '' }
                                   },
           "MyApp::User::Admin" => {
                                     hair_color => { is_nullable => 1 },
                                     id         => {
                                                     data_type   => 'character',
                                                     is_nullable => '',
                                                     size        => 10
                                                   },
                                     level      => { is_nullable => 1 },
                                     myapp_user => { is_nullable => '' }
                                   }
});

done_testing;
