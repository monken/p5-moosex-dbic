package Pad::Schema::Release::Set;
use Moose;
extends 'DBIx::Class::ResultSet';

use Path::Class::File ();
use Archive::Extract  ();
use File::Temp        ();
use CPAN::Meta        ();
use DateTime          ();
use List::Util        ();
use Module::Build::ModuleInfo ();
use File::stat ();

sub import_tarball {
    my ($self, $tarball) = @_;
    $tarball = Path::Class::File->new($tarball);
    my $ae = Archive::Extract->new( archive => $tarball );
    my $dir = Path::Class::Dir->new(File::Temp::tempdir(CLEANUP => 1));
    $ae->extract( to => $dir );
    my ($basedir) = $dir->children;
    my @children = $basedir->children;
    my @files;
    my $meta_file;
    foreach my $child (@children) {
        if(!$child->is_dir) {
            my $relative = $child->relative($basedir);
            $meta_file = $child if($relative =~ /^META\./);
            push(@files, 
                { 
                  name => $relative->as_foreign('Unix')->stringify, 
                  binary => -B $child ? 1 : 0,
                  stat => File::stat::stat($child),
                  #content => \1
                  content => \(scalar $child->slurp)
                } );
        } elsif($child->is_dir) {
            push(@children, $child->children);
        }
    }
    
    my $meta = CPAN::Meta->load_file($meta_file);
    
    my $create = { map { $_ => $meta->$_ } qw(version name license abstract release_status resources) };
    $create = {
        %$create,
        uploaded => DateTime->now,
        files => \@files,
        author => { name => $meta->author }
    };
    $create->{distribution} = $self->result_source->schema->resultset('Distribution')->search({ name => $meta->name })->first;
    $create->{distribution} ||= { name => $meta->name };

    
    my $release = $self->create($create);
    $release = $self->find($release->id);
    
    if(my $prereqs = $meta->prereqs) {
        while( my ($phase,$data) = each %$prereqs ) {
            while( my ($relationship,$v) = each %$data ) {
                while(my ($module, $version) = each %$v) {
                $release->create_related('dependencies',
                    { 
                      phase => $phase, 
                      relationship => $relationship, 
                      module_name => $module, 
                      version => $version
                    });
                }
            }
        }
    }
    if(keys %{$meta->provides} && (my $provides = $meta->provides)) {
        my @files = $release->files->all;
        while( my ($module, $data) = each %$provides ) {
            $data->{file} = List::Util::first {  $_->name eq $data->{file} } @files;
            $release->create_related('modules', { %$data, name => $module });
        }
    } elsif(my $no_index = $meta->no_index) {
        my @files = grep { $_->name =~ /\.pm$/ } $release->files->all;

        foreach my $no_dir (@{$no_index->{directory} || []}) {
            @files = grep { $_->name !~ /^\Q$no_dir\E/ } @files;
        }
        
        foreach my $no_file (@{$no_index->{file} || []}) {
            @files = grep { $_->name !~ /^\Q$no_file\E/ } @files;
        }
        
        foreach my $file (@files) {
            my $info = Module::Build::ModuleInfo->new_from_file($basedir->file($file->name));
            $release->create_related('modules', { file => $file, name => $_, version => $info->version($_) ? $info->version($_)->stringify : undef })
                for($info->packages_inside);
        }
    }
    return $release;
}

1;