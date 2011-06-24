package App::f::Test;
# ABSTRACT: step to test a dist ("make test" or equivalent)
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
        $self->dist->named_step('configure'),
    );
}

sub execute {
    my ($self, $deps) = @_;

    my $dir = $deps->{ $self->dist->named_step('unpack') };

    $self->tick(
        message => join ' ', 'built', $self->dist->name, 'in', $dir,
    );

    $self->done(
        $self->dist->named_step('build') => 1,
    );
}

__PACKAGE__->meta->make_immutable;
1;
