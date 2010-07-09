package DBIC::Schema::Author;
use base 'DBIx::Class';

__PACKAGE__->load_components('InflateColumn::DateTime', 'InflateColumn::Serializer', 'Core');

__PACKAGE__->table('author');

__PACKAGE__->add_columns(
    id => {
        is_auto_increment => 1,
        data_type => 'int',
    },
    name => {},
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->has_many( releases => 'DBIC::Schema::Release', 'author' );

package DBIC::Schema::Distribution;
use base 'DBIx::Class';

__PACKAGE__->load_components('InflateColumn::DateTime', 'InflateColumn::Serializer', 'Core');

__PACKAGE__->table('distribution');

__PACKAGE__->add_columns(
    id => {
        is_auto_increment => 1,
        data_type => 'int',
    },
    name => {},
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->has_many( releases => 'DBIC::Schema::Release', 'author' );



package DBIC::Schema::Release;
use base 'DBIx::Class';

__PACKAGE__->load_components('InflateColumn::DateTime', 'InflateColumn::Serializer', 'Core');


__PACKAGE__->table('release');
__PACKAGE__->add_columns(
    id => {
        is_auto_increment => 1,
        data_type => 'int',
    },
    uploaded => {
        data_type => 'datetime'
    },
    resources => {
        data_type => 'varchar',
        serializer_class => 'JSON',
        is_nullable => 1,
        
    },
    author => {},
    distribution => {},
);

__PACKAGE__->belongs_to( author => 'DBIC::Schema::Author' );
__PACKAGE__->belongs_to( distribution => 'DBIC::Schema::Distribution' );

__PACKAGE__->set_primary_key('id');


package DBIC::Schema;
use base 'DBIx::Class::Schema';

__PACKAGE__->load_classes('Release', 'Author', 'Distribution');

1;