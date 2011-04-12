use Test::More;
use SQL::Translator;

use Data::Dumper;

BEGIN{$Data::Dumper::Maxdepth = 3;
$Data::Dumper::Indent = 1;
}

package CD;
use Moose;
use MooseX::DBIC;
    
has_column 'title';
belongs_to artist => ( lazy => 1 );
might_have cover => ( lazy => 1 );
might_have cover2 => ( isa => 'CD::Cover', foreign_key => 'cd2', lazy => 1 );

package Artist;
use Moose;
use MooseX::DBIC;

has_column 'name';
has_many cds => ( isa => 'CD' );

package CD::Cover;
use Moose;
use MooseX::DBIC;

has_column 'name';
belongs_to 'cd' => ( isa => 'CD', lazy => 1 );
belongs_to 'cd2' => ( isa => 'CD', lazy => 1 );
has_one 'cd3' => ( isa => 'CD', foreign_key => 'cover', lazy => 1 );


package main;

{
    ok(my $rel = CD->meta->get_relationship('artist'), 'get belongs_to relationship artist');
    is($rel->accessor, 'artist', 'is => rw');
    ok($rel->has_read_method && $rel->has_write_method, 'has reader and writer');
    ok($rel->is_lazy, 'is lazy');
    is($rel->related_class, 'Artist', 'related class is Artist');
    is($rel->foreign_key, $rel, 'foreign key is artist in Artist');
}

{
    ok(my $rel = CD->meta->get_relationship('cover'), 'get might_have relationship cover');
    is($rel->accessor, 'cover', 'is => rw');
    ok($rel->has_read_method && $rel->has_write_method, 'has reader and writer');
    ok($rel->is_lazy, 'is lazy');
    is($rel->related_class, 'CD::Cover', 'related class is CD::Cover');
    is($rel->foreign_key, CD::Cover->meta->get_relationship('cd'), 'foreign key is cd in CD::Cover');
}

{
    ok(my $rel = CD->meta->get_relationship('cover2'), 'get might_have relationship cover2');
    is($rel->related_class, 'CD::Cover', 'related class is CD::Cover');
    is($rel->foreign_key, CD::Cover->meta->get_relationship('cd2'), 'foreign key is cd2 in CD::Cover');
}

{
    ok(my $rel = CD::Cover->meta->get_relationship('cd3'), 'get has_one relationship cd3');
    is($rel->related_class, 'CD', 'related class is CD');
    is($rel->foreign_key, CD->meta->get_relationship('cover'), 'foreign key is cover in CD');
    ok($rel->is_required, 'has_one rels are required');
}

done_testing;

