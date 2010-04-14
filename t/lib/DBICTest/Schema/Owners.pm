package # hide from PAUSE 
    DBICTest::Schema::Owners;

use MooseX::DBIC; with 'DBICTest::Compat';

remove 'id';
has_column id => ( isa => 'Int', auto_increment => 1, primary_key => 1 );
has_column 'name';

has_many books => ( isa => ResultSet["DBICTest::Schema::BooksInLibrary"], foreign_key => "owner");

1;
