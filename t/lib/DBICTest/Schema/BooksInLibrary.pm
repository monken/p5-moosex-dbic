package # hide from PAUSE 
    DBICTest::Schema::BooksInLibrary;

use Moose;
use MooseX::DBIC; with 'DBICTest::Compat';

table 'books';
remove 'id';
has_column id => ( isa => 'Int', auto_increment => 1, primary_key => 1 );


has_column [qw(source title)] => (size => 100 );
has_column owner => ( isa => 'Int', required => 1 );
has_column price => ( isa => 'Int' );

#__PACKAGE__->resultset_attributes({where => { source => "Library" } });

belongs_to owner => ( isa => 'DBICTest::Schema::Owners' );

1;
