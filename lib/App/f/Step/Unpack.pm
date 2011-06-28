package App::f::Step::Unpack;
# ABSTRACT: download and unpack a dist
use Moose;
use namespace::autoclean;

use Path::Class qw(dir);

with 'App::f::Step::WithDist';

sub execute {
    my ($self, $deps) = @_;
    $self->done({ $self->named_dep('unpack') => dir('/tmp') });
}

__PACKAGE__->meta->make_immutable;
1;
