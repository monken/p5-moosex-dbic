use Test::More;
use strict;
use warnings;

package CD;
use MooseX::DBIC;
    
has_column 'title';

package MySchema;
use Moose;
extends 'MooseX::DBIC::Schema';

__PACKAGE__->load_classes(qw(CD));

package main;

my $rs = MySchema->resultset('CD');

is(CD->meta->resultset_class, 'MooseX::DBIC::Set');
isa_ok($rs, 'MooseX::DBIC::Set');
can_ok($rs, 'prefetch');

done_testing;

