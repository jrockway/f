package App::f::Step::Test;
# ABSTRACT: step to test a dist ("make test" or equivalent)
use Moose;
use namespace::autoclean;

with 'App::f::Step::WithDist';

sub BUILD {
    my $self = shift;
    $self->add_named_dep('unpack');
    $self->add_named_dep('build');
}

sub execute {
    my ($self, $deps) = @_;
    $self->tick( message => "Testing ". $self->dist_name );
    $self->done({ $self->named_dep('test') => 1 });
}

__PACKAGE__->meta->make_immutable;
1;
