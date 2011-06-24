package App::f::CpanDownload;
# ABSTRACT: step to test a dist ("make test" or equivalent)
use Moose;
use namespace::autoclean;

with 'f::Step';

has 'dist' => (
    is       => 'ro',
    isa      => 'f::Dist',
    required => 1,
);

sub execute {
    my ($self, $deps) = @_;

    $self->tick(
        message => 'unpacked ' . $self->dist->name,
    );

    $self->done(
        $self->dist->named_step('unpack') => dir('/tmp/unpack-1234'),
    );
}

__PACKAGE__->meta->make_immutable;
1;
