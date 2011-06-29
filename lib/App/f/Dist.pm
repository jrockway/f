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
    return 'dist<'. $self->name. '>';
}

sub named_dep {
    my ($self, $step) = @_;
    return join ':', $self->to_id, $step;
}

sub TO_JSON {
    return { dist => $_[0]->to_id };
}

__PACKAGE__->meta->make_immutable;
1;
