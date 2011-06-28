package App::f::Step::Install;
# ABSTRACT: step to install a module
use Moose;
use namespace::autoclean;

with 'App::f::Step::WithDist';

sub BUILD {
    my $self = shift;
    $self->add_named_dep('unpack');
    $self->add_named_dep('build');
    $self->add_named_dep('test');
}

sub execute {
    my ($self, $deps) = @_;

    $self->tick( message => 'Installed '. $self->dist_name );

    my @module_deps = map { ("$_:install" => $self->dist) } qw/Moose/;
    $self->done({
        $self->named_dep('install') => 1,    # installed dist
        @module_deps,
    });
}

__PACKAGE__->meta->make_immutable;
1;
