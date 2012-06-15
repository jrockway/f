package App::f;
# ABSTRACT: f CPAN (client)
use Moose;
use namespace::autoclean;

use AnyEvent;

use App::f::Manager;
use App::f::Dist;

with 'MooseX::Runnable', 'MooseX::Getopt::Dashes';

has 'manager' => (
    traits  => ['NoGetopt'],
    is      => 'ro',
    isa     => 'App::f::Manager',
    default => sub {
        my $self = shift;
        App::f::Manager->new(
            completion_cb => sub {
                $self->handle_completion;
            },
        );
    },
    handles => [qw/add_step add_step_type has_running_steps has_completed_steps has_work/],
);

has 'on_completion' => (
    is        => 'rw',
    isa       => 'CodeRef',
    traits    => [qw/Code NoGetopt/],
    clearer   => 'clear_on_completion',
    predicate => 'has_on_completion',
    handles   => { run_on_completion => 'execute' },
);

sub BUILD {
    my $self = shift;

    $self->add_step_type( Want => {
        class => 'App::f::Step::Want',
        parameters => {
            module => { isa => 'Str', required => 1 },
        },
    });

    $self->add_step_type( Resolve => {
        class => 'App::f::Step::Resolve',
        parameters => {
            module => { isa => 'Str', required => 1 },
        },
    });

    $self->add_step_type( Unpack => {
        class => 'App::f::Step::Unpack',
        parameters => {
            dist => { isa => 'App::f::Dist', required => 1 },
        },
    });

    $self->add_step_type( Preconfigure => {
        class => 'App::f::Step::Preconfigure',
        parameters => {
            dist => { isa => 'App::f::Dist', required => 1 },
        },
    });

    $self->add_step_type( Configure => {
        class => 'App::f::Step::Configure',
        parameters => {
            dist => { isa => 'App::f::Dist', required => 1 },
        },
    });

    $self->add_step_type( Build => {
        class => 'App::f::Step::Build',
        parameters => {
            dist => { isa => 'App::f::Dist', required => 1 },
        },
    });

    $self->add_step_type( Test => {
        class => 'App::f::Step::Test',
        parameters => {
            dist => { isa => 'App::f::Dist', required => 1 },
        },
    });

    $self->add_step_type( Install => {
        class => 'App::f::Step::Install',
        parameters => {
            dist => { isa => 'App::f::Dist', required => 1 },
        },
    });

    $self->add_step_type( Installed => {
        class => 'App::f::Step::Installed',
        parameters => {
            module => { isa => 'Str', required => 1 },
        },
    });
}

sub handle_completion {
    my $self = shift;
    if($self->has_on_completion) {
        $self->run_on_completion();
    }
}

sub run {
    my ($self, @modules) = @_;

    if(!@modules){
        print "No modules to install?\n";
        return 1;
    }

    my $cv = AnyEvent->condvar;

    $self->on_completion( sub { $cv->send } );

    for my $module (@modules) {
        $self->add_step( Want => { module => $module } );
    }

    if( !$self->has_running_steps && $self->has_work ){
        print "Deadlock detected.  Exiting.\n";
        return 1;
    }

    $cv->recv;
    return 0;
}

__PACKAGE__->meta->make_immutable;
1;
