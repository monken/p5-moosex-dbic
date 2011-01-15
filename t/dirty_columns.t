use Test::More;
use Test::Exception;
use strict;

use lib q(t/lib);
use DBICTest::Schema;
use DateTime;

use Scalar::Util qw(refaddr);

my $schema = DBICTest::Schema->connect( 'dbi:SQLite::memory:' );

$schema->deploy;
my $queries = 0;
$schema->storage->debugcb(sub { diag $_[1] if($ENV{DBIC_TRACE}); $queries++; });
$schema->storage->debug(1);

my $cd;

my %dirty = ( in_storage => 1, _raw_data => 1 );

{
    ok($cd = $schema->resultset('CD')->create({ 
        year => 1999,
        title => 'the rabbits',
        single_track => { title => 'foo' }
    }));
    is_deeply([$cd->meta->get_dirty_column_list($cd)], [], 'dirty columns in empty after create');
    $cd->year(2000);
    is_deeply([$cd->meta->get_dirty_column_list($cd)], ['year'], 'year column is dirty now');
    
}

{
    $cd = $schema->resultset('CD')->first;
    is_deeply([$cd->meta->get_dirty_column_list($cd)], [], 'dirty columns in empty after fetch from db');
    is($cd->single_track->title, 'foo');
    is_deeply([$cd->meta->get_dirty_column_list($cd)], [], 'dirty columns still empty after rel fetch');
    ok($cd->single_track->title('bar'), 'change title of single track');
    ok($cd->single_track->meta->is_dirty($cd->single_track), 'single_track is dirty');
    is_deeply([$cd->meta->get_dirty_column_list($cd)], [ 'single_track' ], 'cd\'s single_track is now dirty');
}

{
    ok(my $genre = $schema->resultset('Genre')->create({ 
        name => 'Rock', 
        model_cd => $cd,
        cds => [
        {
            year => 1999,
            title => 'the rabbits',
            single_track => { title => 'foo' }
        }
        ]
    }));
    isa_ok($genre, 'DBICTest::Genre');
}

{
    my $genre = $schema->resultset('Genre')->first;
    lives_ok { map { $_->create_related('tracks', { title => 'foo' }) } $genre->cds->all }; 
}

{
    my $genre = $schema->resultset('Genre')->search(undef, { prefetch => 'model_cd' })->first;
    my $cd = $genre->model_cd;
    my $rel = $cd->meta->get_relationship('genre');
    ok(!$rel->is_column_dirty($cd), 'Column is not dirty');
    ok(!$rel->is_relationship_dirty($cd), 'Relationship is not dirty');
    
}

{
    my $cd = $schema->resultset('CD')->search(undef, { columns => 'cdid' })->first;
    my $year = $cd->meta->get_column('year');
    ok(!$year->is_dirty($cd), 'not fetched year column is not dirty');
    is($cd->year, 1999, 'fetch year from storage');
    ok(!$year->is_dirty($cd), 'fetched year column still not dirty');
    
    my $title = $cd->meta->get_column('title');
    is($title->get_value($cd), 'the rabbits', 'fetch title via get_value');
    ok(!$title->is_dirty($cd), 'title is not dirty');
    
}


{
    my $cd = $schema->resultset('CD')->first;
    my $year = $cd->meta->get_column('year');
    $year->set_value($cd, '2000');
    ok($year->is_dirty($cd), 'year is dirty');
}

{   
    my $cd = $schema->resultset('CD')->first;
    my $year = $cd->meta->get_column('year');
    $year->set_raw_value($cd, '1998');
    ok(!$year->is_dirty($cd), 'year is not dirty');
}

{
    use DateTime;

    use DateTime::Format::Pg;
    use MooseX::Attribute::Deflator;

    inflate 'DateTime', via { DateTime::Format::Pg->parse_datetime( $_ ) };
    deflate 'DateTime', via { DateTime::Format::Pg->format_datetime($_); }; 

    no MooseX::Attribute::Deflator;

    package Artist;
    use MooseX::DBIC;
    has_column time => ( isa => 'DateTime' );

    __PACKAGE__->meta->make_immutable;

    package MySchema;
    use Moose;
    extends 'MooseX::DBIC::Schema';

    __PACKAGE__->load_classes(qw(Artist));

    package main;

    my $schema = MySchema->connect('dbi:SQLite::memory:');
    $schema->deploy;
    my $rs = $schema->resultset('Artist');
    ok( $rs->create({ time => DateTime->now  }) );

    my $artist = $rs->first;
    my $oldtime = $artist->time->clone;
    $artist->time($artist->time->set_time_zone( 'America/Chicago' ));

    ok($artist->meta->get_column('time')->deflate($artist) ne $artist->_raw_data->{time}, 'deflated values do not match');

    is($artist->time, $oldtime, 'objects compare ok');

    ok(!$artist->meta->get_column('time')->is_dirty($artist), 'column is not dirty');

}


done_testing;

