package App::f::Step::Want;
# ABSTRACT: indicate the desire to install a module
use Moose;
use namespace::autoclean;

use App::f::Util qw(is_newer_than);

with 'App::f::Step';

has 'module' => ( is => 'ro', isa => 'Str', required => 1 );
has 'version' => ( is => 'ro', isa => 'Maybe[Str]', required => 1 );

sub execute {
    my $self = shift;
    $self->tick( message => 'Want '. $self->module. ' '. ($self->version || '<undef>') );

    if( $self->module ne 'perl' ){
        $self->add_step( Resolve => { module => $self->module, version => $self->version } );
    }

    $self->add_step( Installed => { module => $self->module } );
    $self->done({ $self->module . ':want' => 1 });
}

sub equals {
    my ($self, $other) = @_;

    return unless $other->isa( __PACKAGE__ );
    return unless $self->module eq $other->module;


    # return unless # versions parse ok
    #     eval { version->parse($self->version) } &&
    #                eval { version->parse($other->version) } && 1;
    # return !is_newer_than($other, $self);

    return 1;
}

__PACKAGE__->meta->make_immutable;
1;
