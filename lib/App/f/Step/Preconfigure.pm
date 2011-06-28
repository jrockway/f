package App::f::Step::Preconfigure;
# ABSTRACT: read a distribution's metainformation and try to install prereqs
use Moose;
use namespace::autoclean;
use JSON qw(decode_json);
use YAML::XS qw(LoadFile);

with 'App::f::Step::WithDist';

sub BUILD {
    my $self = shift;
    $self->add_named_dep('unpack');
}

sub execute {
    my ($self, $deps) = @_;

    my $location = $deps->{$self->named_dep('unpack')};

    my $meta_json = $location->file('META.json');
    my $meta_yaml = $location->file('META.yml');

    my $meta;

    if(-e $meta_json){
        $meta = eval {
            my $json = read_file($meta_json->stringify);
            $self->tick( message => 'Found meta.json for '. $self->dist_name );
            decode_json($json);
        }
    }
    if(-e $meta_yaml && !$meta){
        $self->tick( message => 'Found meta.yml for '. $self->dist_name );
        $meta = eval { LoadFile($meta_yaml->stringify) };
    }

    $self->done({ $self->named_dep('meta') => $meta });
}

__PACKAGE__->meta->make_immutable;
1;
