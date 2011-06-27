package App::f::Dist;
# ABSTRACT: represent a dist to install
use Moose;
use namespace::autoclean;

has 'name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'version' => (
    is       => 'ro',
    isa      => 'Undef|Str',
    required => 1,
);

has 'source' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub to_id {
    my ($self) = @_;
    return $self->name;
}

sub named_step {
    my ($self, $step) = @_;
    return join ':', $self->to_id, $step;
}

__PACKAGE__->meta->make_immutable;
1;
