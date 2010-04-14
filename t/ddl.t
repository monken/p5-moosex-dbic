use lib qw(t/lib);
use Test::More;
use MySchema;

my $schema = MySchema->connect('dbi:SQLite::memory:');

my $ddl = {};

foreach my $source ( map { $schema->source($_) } $schema->sources ) {
    $ddl->{ $source->source_name } =
      { map { $_ => $source->column_info($_) } $source->columns };
}

is_deeply(
    $ddl,
    {
        'MyApp::User::Admin' => {
            'level' => {
                'is_auto_increment' => undef,
                'data_type'         => 'INTEGER',
                'default_value'     => undef,
                'is_nullable'       => 1,
                'size'              => undef
            },
            'myapp_user' => {
                'is_auto_increment' => 0,
                'data_type'         => 'CHARACTER',
                'is_nullable'       => '',
                'size'              => undef
            },
            'id' => {
                'is_auto_increment' => 0,
                'data_type'         => 'VARCHAR',
                'default_value'     => undef,
                'is_nullable'       => '',
                'size'              => 10
            },
            'hair_color' => {
                'is_auto_increment' => undef,
                'data_type'         => 'VARCHAR',
                'default_value'     => undef,
                'is_nullable'       => 1,
                'size'              => undef
            }
        },
        'MyApp::User' => {
            'email' => {
                'is_auto_increment' => undef,
                'data_type'         => 'VARCHAR',
                'default_value'     => undef,
                'is_nullable'       => 1,
                'size'              => undef
            },
            'first' => {
                'is_auto_increment' => undef,
                'data_type'         => 'VARCHAR',
                'default_value'     => undef,
                'is_nullable'       => 1,
                'size'              => undef
            },
            'moose_object' => {
                'is_auto_increment' => 0,
                'data_type'         => 'CHARACTER',
                'is_nullable'       => '',
                'size'              => undef
            },
            'last' => {
                'is_auto_increment' => undef,
                'data_type'         => 'VARCHAR',
                'default_value'     => undef,
                'is_nullable'       => 1,
                'size'              => undef
            },
            'id' => {
                'is_auto_increment' => 0,
                'data_type'         => 'VARCHAR',
                'default_value'     => undef,
                'is_nullable'       => '',
                'size'              => 10
            }
        },
        'Moose::Object' => {
            'id' => {
                'is_auto_increment' => 0,
                'data_type'         => 'VARCHAR',
                'default_value'     => undef,
                'is_nullable'       => '',
                'size'              => 10
            }
        }
    }
);

done_testing;
