package App::f::Step::Configure;
# ABSTRACT: step to configure a dist (read META.json, run Makefile.PL)
use Moose;
use namespace::autoclean;

with 'App::f::Step::WithDist';

sub BUILD {
    my $self = shift;
    $self->add_named_dep('unpack');
    $self->add_named_dep('meta');
}

sub execute {
    my ($self, $deps) = @_;
    $self->tick( message => 'configured ' . $self->dist->name );
    $self->done({ $self->named_dep('configure') => 1 });
}

__PACKAGE__->meta->make_immutable;
1;
