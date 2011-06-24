package App::f::Configure;
# ABSTRACT: step to configure a dist (read META.json, run Makefile.PL)
use Moose;
use namespace::autoclean;

with 'f::Step';

has 'dist' => (
    is       => 'ro',
    isa      => 'f::Dist',
    required => 1,
);

sub BUILD {
    my $self = shift;
    $self->add_dependency(
        $self->dist->named_step('unpack'),
    );
}

sub execute {
    my ($self, $deps) = @_;

    $self->tick(
        message => 'configured ' . $self->dist->name,
    );

    $self->done(
        $self->dist->named_step('configure') => { meta => '.json' },
    );
}

__PACKAGE__->meta->make_immutable;
1;
