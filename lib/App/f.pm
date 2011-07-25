package App::f;
# ABSTRACT: f CPAN (client)
use Moose;
use namespace::autoclean;

use MooseX::Types::Path::Class qw(Dir);
use MooseX::Types::URI qw(Uri);

use AnyEvent;

use App::f::Manager;
use App::f::Dist;

with 'MooseX::Runnable', 'MooseX::Getopt::Dashes';

has 'manager' => (
    is      => 'ro',
    isa     => 'App::f::Manager',
    default => sub {
        my $self = shift;
        App::f::Manager->new(
            completion_cb => sub {
                $self->handle_completion( 0 );
            },
            error_cb => sub {
                shift;
                $self->handle_completion( 1, @_ );
            },
        );
    },
    handles => [qw/add_step add_step_type has_running_steps
                   has_completed_steps has_work add_service/],
);

has 'on_completion' => (
    is        => 'rw',
    isa       => 'CodeRef',
    traits    => ['Code'],
    clearer   => 'clear_on_completion',
    predicate => 'has_on_completion',
    handles   => { run_on_completion => 'execute' },
);

sub add_dist_step_type {
    my ($self, $name, $args) = @_;

    my $params = delete $args->{parameters} || {};

    return $self->add_step_type( $name => {
        %$args,
        parameters => {
            dist => { isa => 'App::f::Dist', required => 1 },
            %$params,
        },
    });
}

sub BUILD {
    my $self = shift;

    $self->add_service( Bread::Board::Literal->new(
        name => 'cpan_mirror',
        value => 'http://cpan.llarian.net/',
    ));

    $self->add_service( Bread::Board::Literal->new(
        name  => 'work_directory',
        value => '/tmp/',
    ));

    $self->add_step_type( Want => {
        class => 'App::f::Step::Want',
        parameters => {
            module  => { isa => 'Str', required => 1 },
            version => { isa => 'Maybe[Str]', required => 1 },
        },
    });

    $self->add_step_type( Have => {
        class => 'App::f::Step::Have',
        parameters => {
            module  => { isa => 'Str', required => 1 },
            version => { isa => 'Maybe[Str]', required => 1 },
        },
    });

    $self->add_step( Have => {
        module  => 'perl',
        version => $],
    });

    $self->add_step_type( Resolve => {
        class => 'App::f::Step::Resolve',
        parameters => {
            module => { isa => 'Str', required => 1 },
            version => { isa => 'Maybe[Str]', required => 1 },
        },
    });

    $self->add_dist_step_type( Download => {
        class        => 'App::f::Step::Download',
        dependencies => {
            mirror => Bread::Board::Dependency->new(
                service_path => 'cpan_mirror',
            ),
            download_directory => Bread::Board::Dependency->new(
                service_path => 'work_directory',
            ),
        },
    });

    $self->add_dist_step_type( Unpack => {
        class        => 'App::f::Step::Unpack',
        dependencies => {
            unpack_directory =>  Bread::Board::Dependency->new(
                service_path => 'work_directory',
            ),
        },
    });

    $self->add_dist_step_type( Preconfigure => {
        class => 'App::f::Step::Preconfigure',
    });

    $self->add_dist_step_type( Configure => {
        class      => 'App::f::Step::Configure',
        parameters => {
            prereqs => {
                isa     => 'ArrayRef[Str]',
                default => sub { [] },
            },
        },
    });

    $self->add_dist_step_type( Build => {
        class      => 'App::f::Step::Build',
        parameters => {
            prereqs => {
                isa     => 'ArrayRef[Str]',
                default => sub { [] },
            },
        },
    });

    $self->add_dist_step_type( Test => {
        class => 'App::f::Step::Test',
    });

    $self->add_dist_step_type( Install => {
        class => 'App::f::Step::Install',
    });

    $self->add_step_type( Installed => {
        class => 'App::f::Step::Installed',
        parameters => {
            module => { isa => 'Str', required => 1 },
        },
    });

    # perl is already installed :)
    $self->manager->add_state('perl:install' => version->parse($]));
}

sub handle_completion {
    my ($self, $is_error, $msg) = @_;

    if($is_error){
        print "Error: $msg.\n  Exiting.\n";
        exit 1;
    }

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
        $self->add_step( Want => { module => $module, version => undef } );
    }

    $cv->recv;
    return 0;
}

__PACKAGE__->meta->make_immutable;
1;
