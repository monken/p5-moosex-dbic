package # hide from PAUSE 
    DBICTest::Schema::TreeLike;

use MooseX::DBIC; with 'DBICTest::Compat';

table 'tree_like';
remove 'id';
has_column id => ( isa => 'Int', auto_increment => 1, primary_key => 1 );
has_column 'name';

belongs_to parent => ( isa => 'DBICTest::Schema::TreeLike' );
has_many children => ( isa => 'DBICTest::Schema::TreeLike', foreign_key => 'parent');

__PACKAGE__->meta->make_immutable;
