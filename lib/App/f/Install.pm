package App::f::Install;
# ABSTRACT: step to install a module ("make install" or equivalent)
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
        $self->dist->named_step('build'),
        $self->dist->named_step('test'),
    );
}

sub execute {
    my ($self, $deps) = @_;

    $self->tick(
        message => 'installed ' . $self->dist->name,
    );

    $self->done(
        $self->dist->named_step('install') => 1,
    );
}

__PACKAGE__->meta->make_immutable;
1;
