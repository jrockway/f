package App::f::Step::Resolve;
# ABSTRACT: step to translate from user input to a concrete dist name to install
use Moose;
use namespace::autoclean;
use App::f::Dist;

use 5.014;

with 'App::f::Step';

has 'module' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub execute {
    my ($self) = @_;

    my $module = $self->module;

    my $dist = App::f::Dist->new(
        name    => ($module =~ s/::/-/gr),
        version => undef,
        source  => "cpan://$module",
    );

    $self->tick(
        message => sprintf(
            'Resolved %s to %s', $self->module, $dist->name,
        ),
    );

    $self->add_step( Unpack => {
        dist => $dist,
    });

    $self->add_step( Preconfigure => {
        dist => $dist,
    });

    $self->add_step( Configure => {
        dist => $dist,
    });

    $self->add_step( Build => {
        dist => $dist,
    });

    $self->add_step( Test => {
        dist => $dist,
    });

    $self->add_step( Install => {
        dist => $dist,
    });

    $self->done({
        $self->module . ':resolve' => $dist,
    });
}

sub detect_module {
    my ($self, $module) = @_;

    my $has = 0;

    my $version = eval {
        Class::MOP::load_class($module);
        $has = 1;
        my $meta = Class::MOP::Package->initialize($module);
        ${$meta->get_package_symbol('$VERSION')};
    };

    return ($has, $version);
}

__PACKAGE__->meta->make_immutable;
1;
