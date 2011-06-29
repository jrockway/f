package App::f::Step::WithDist;
# ABSTRACT: convenience role for roles that need a dist object
use Moose::Role;
use namespace::autoclean;

with 'App::f::Step';

has 'dist' => (
    is       => 'ro',
    isa      => 'App::f::Dist',
    required => 1,
    handles  => {
        dist_name => 'name',
        named_dep => 'named_dep',
    },
);

sub add_named_dep {
    my ($self, $name) = @_;
    $self->add_dependency( $self->named_dep($name) );
}

sub get_named_dep {
    my ($self, $deps, $name) = @_;
    $deps->{$self->named_dep($name)};
}

1;
