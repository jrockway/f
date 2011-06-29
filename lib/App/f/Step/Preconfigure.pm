package App::f::Step::Preconfigure;
# ABSTRACT: read a distribution's metainformation and try to install prereqs
use Moose;
use namespace::autoclean;

use CPAN::Meta;

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
        $self->tick( message => 'Found meta.json for '. $self->dist_name );
        $meta = eval { CPAN::Meta->load_file($meta_json->stringify) };
    }
    if(-e $meta_yaml && !$meta){
        $self->tick( message => 'Found meta.yml for '. $self->dist_name );
        $meta = eval { CPAN::Meta->load_file($meta_yaml->stringify) };
    }

    $meta ||= CPAN::Meta->create({
        name    => $self->dist_name,
        version => $self->dist->version,
    });

    my @prereqs;
    for my $module (keys %{$meta->prereqs->{configure}{requires}}){
        my $version = $meta->prereqs->{configure}{requires}{$module};
        $self->add_step( Want => { module => $module, version => $version || 0} );
        push @prereqs, $module;
    }

    $self->add_step( Configure => {
        dist    => $self->dist,
        prereqs => \@prereqs,
    });

    $self->done({ $self->named_dep('meta') => $meta });
}

__PACKAGE__->meta->make_immutable;
1;
