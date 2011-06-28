package App::f::Step::Want;
# ABSTRACT: indicate the desire to install a module
use Moose;
use namespace::autoclean;

with 'App::f::Step';

has 'module' => ( is => 'ro', isa => 'Str', required => 1 );

sub execute {
    my $self = shift;
    print "want " . $self->module. "\n";
    $self->add_step( Installed => { module => $self->module } );
    $self->add_step( Resolve   => { module => $self->module } );
    $self->done({ $self->module . ':want' => 1 });
}

__PACKAGE__->meta->make_immutable;
1;
