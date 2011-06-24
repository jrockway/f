package App::f::Resolve;
# ABSTRACT: step to translate from user input to a concrete dist name to install
use Moose;
use namespace::autoclean;

use 5.014;

with 'App::f::Step';

has 'input' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub execute {
    my ($self, $manager, $deps, $completion) = @_;

    my $module = $self->input;
    my $dist = App::f::Dist->new(
        name    => ($module =~ s/::/-/gr),
        version => undef,
        source  => "cpan://$module",
    );

    return $dist->get_install_steps;
}

__PACKAGE__->meta->make_immutable;
1;
