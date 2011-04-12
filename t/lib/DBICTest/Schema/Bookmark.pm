package # hide from PAUSE
    DBICTest::Schema::Bookmark;

use Moose;
use MooseX::DBIC; with 'DBICTest::Compat';

remove 'id';
has_column id => ( isa => 'Int', auto_increment => 1, primary_key => 1 );

belongs_to link => ( isa => 'DBICTest::Schema::Link' );

{ no warnings;
sub might_have {
    warn q("might_have/has_one" must not be on columns with is_nullable set to true) unless($ENV{DBIC_DONT_VALIDATE_RELS});
}
}


1;