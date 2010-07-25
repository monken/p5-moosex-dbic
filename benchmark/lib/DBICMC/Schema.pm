package DBIC::Schema::Author;
use base 'DBIx::Class';
use DBIx::Class::MooseColumns;

__PACKAGE__->load_components('InflateColumn::DateTime', 'InflateColumn::Serializer', 'Core');

__PACKAGE__->table('author');

has id => (
    isa => 'Int',
    is  => 'rw',
    add_column => {
      is_auto_increment => 1,
    },
);

has name => ( isa => 'Str', is => 'rw' );

__PACKAGE__->set_primary_key('id');

__PACKAGE__->has_many( releases => 'DBICMC::Schema::Release', 'author' );

package DBICMC::Schema::Distribution;
use base 'DBIx::Class';
use DBIx::Class::MooseColumns;

__PACKAGE__->load_components('InflateColumn::DateTime', 'InflateColumn::Serializer', 'Core');

__PACKAGE__->table('distribution');

has id => (
    isa => 'Int',
    is  => 'rw',
    add_column => {
      is_auto_increment => 1,
    },
);

has name => ( isa => 'Str', is => 'rw' );

__PACKAGE__->set_primary_key('id');

__PACKAGE__->has_many( releases => 'DBICMC::Schema::Release', 'author' );



package DBICMC::Schema::Release;
use base 'DBIx::Class';
use DBIx::Class::MooseColumns;

__PACKAGE__->load_components('InflateColumn::DateTime', 'InflateColumn::Serializer', 'Core');


__PACKAGE__->table('release');
has id => (
    isa => 'Int',
    is  => 'rw',
    add_column => {
      is_auto_increment => 1,
    },
);

has uploaded => ( isa => 'DateTime', is => 'rw' );

has uploaded => ( isa => 'HashRef', is => 'rw' );

has author => ( isa => 'Int', is => 'rw' );

has distribution => ( isa => 'Int', is => 'rw' );


__PACKAGE__->belongs_to( author => 'DBICMC::Schema::Author' );
__PACKAGE__->belongs_to( distribution => 'DBICMC::Schema::Distribution' );

__PACKAGE__->set_primary_key('id');


package DBICMC::Schema;
use base 'DBIx::Class::Schema';

__PACKAGE__->load_classes('Release', 'Author', 'Distribution');

1;