package # hide from PAUSE 
    DBICTest::Schema::Employee;

    use Moose;
use MooseX::DBIC; with 'DBICTest::Compat';

# __PACKAGE__->load_components(qw( Ordered ));

remove 'id';
has_column employee_id => ( isa => 'Int', auto_increment => 1, primary_key => 1 );

has_column [qw(position group_id group_id_2 group_id_3)] => ( isa => 'Int' );

has_column 'name';

# __PACKAGE__->position_column('position');

#__PACKAGE__->add_unique_constraint(position_group => [ qw/position group_id/ ]);

# __PACKAGE__->mk_classdata('field_name_for', {
#     employee_id => 'primary key',
#     position    => 'list position',
#     group_id    => 'collection column',
#     name        => 'employee name',
# });

belongs_to secretkey => ( isa => 'DBICTest::Schema::Encoded', join_type => 'left' );

1;
