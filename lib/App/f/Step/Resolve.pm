package App::f::Step::Resolve;
# ABSTRACT: step to translate from user input to a concrete dist name to install
use Moose;
use namespace::autoclean;

use AnyEvent::HTTP;
use YAML::XS;
use File::Sorted;

use App::f::Dist;
use Try::Tiny;
use App::f::Util qw(is_newer_than);

use 5.014;

with 'App::f::Step';

has 'module' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'version' => (
    is       => 'ro',
    isa      => 'Maybe[Str]',
    required => 1,
);

sub execute {
    my ($self) = @_;

    $self->resolve_cpanmetadb( sub {
        my $dist = shift;

        $self->tick(
            message => sprintf(
                'Resolved %s to %s', $self->module, $dist->name,
            ),
        );

        $self->add_step( Download => {
            dist => $dist,
        });

        $self->add_step( Unpack => {
            dist => $dist,
        });

        $self->add_step( Preconfigure => {
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
    });

    return;
}

sub resolve_02packages {
    my $self = shift;

}

sub resolve_cpanmetadb {
    my ($self, $cb) = @_;

    my $module = $self->module;
    http_get "http://cpanmetadb.appspot.com/v1.0/package/$module", sub {
        my $res = Load($_[0]);
        my $file = $res->{distfile};

        if(!$file){
            $self->error("Could not resolve $module on cpanmetadb");
            return;
        }

        my $filename = [split m{/}, $file]->[-1];
        my $name = [split m{[.]}, $filename]->[0];
        $name =~ s/-[^-]+$//g;

        $cb->( App::f::Dist->new(
            source  => "cpan://$file",
            version => $res->{version},
            name    => $name,
        ));
    };
}

__PACKAGE__->meta->make_immutable;
1;
