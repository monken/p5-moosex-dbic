package # hide from PAUSE 
    DBICTest::Schema::TreeLike;

use MooseX::DBIC; with 'DBICTest::Compat';
use DateTime;

table 'tree_like';
remove 'id';
has_column id => ( isa => 'Int', auto_increment => 1, primary_key => 1 );
has_column 'name';
has_column updated_on => ( isa => 'DateTime', default => sub { DateTime->now }, required => 1 );

belongs_to parent => ( isa => 'DBICTest::Schema::TreeLike' );
has_many children => ( isa => 'DBICTest::Schema::TreeLike', foreign_key => 'parent');

__PACKAGE__->meta->make_immutable;
