package App::f::Step::Build;
# ABSTRACT: step to build a dist ("make" or equivalent)
use Moose;
use namespace::autoclean;

with 'App::f::Step::WithDist';

sub BUILD {
    my $self = shift;
    $self->add_named_dep('unpack');
    $self->add_named_dep('configure');
}

sub execute {
    my ($self, $deps) = @_;
    $self->tick( message => 'Built '. $self->dist_name );
    $self->done({ $self->named_dep('build') => 1 });
}

__PACKAGE__->meta->make_immutable;
1;
