package App::f::Dist;
# ABSTRACT:
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

sub download_step {
    my ($self) = @_;
    # XXX: handle various download types based on source
    return CpanDownload => ( source => $self->source );
}

sub configure_step {
    my ($self) = @_;
    return Configure => ( dist => $self );
}

sub build_step {
    my ($self) = @_;
    return Build => ( dist => $self );
}

sub test_step {
    my ($self) = @_;
    return Test => ( dist => $self );
}

sub install_step {
    my ($self) = @_;
    return Install => ( dist => $self );
}

sub get_install_steps {
    my ($self) = @_;
    return $self->download_step, $self->configure_step,
        $self->build_step, $self->test_step, $self->install_step;
}

__PACKAGE__->meta->make_immutable;
1;
