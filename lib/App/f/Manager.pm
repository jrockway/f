package App::f::Manager;
# ABSTRACT: class to run the tasks at the right time
use Moose;
use namespace::autoclean;

use MooseX::Types::Set::Object;

use Bread::Board;
use App::f::Breadboard::Service::Step;
use List::Util qw(first reduce);
use Params::Util qw(_HASH);
use Set::Object qw(set);
use Scalar::Util qw(weaken);

has 'work' => (
    is      => 'ro',
    isa     => 'Set::Object',
    default => sub { set },
    handles => {
        get_worklist => 'members',
        add_work     => 'insert',
        delete_work  => 'delete',
        has_work     => 'size',
    },
);

has 'running' => (
    is      => 'ro',
    isa     => 'Set::Object',
    default => sub { set },
    handles => {
        get_running_steps   => 'members',
        insert_running_step => 'insert',
        remove_running_step => 'delete',
        has_running_steps   => 'size',
    },
);

has 'completed' => (
    is      => 'ro',
    isa     => 'Set::Object',
    default => sub { set },
    handles => {
        get_completed_steps   => 'members',
        insert_completed_step => 'insert',
        has_completed_steps   => 'size',
    },
);

# TODO: perhaps have the concept of "error results" so that we can
# cancel any steps that depend on erroneous data
has 'state' => (
    is      => 'ro',
    isa     => 'HashRef',
    traits  => ['Hash'],
    default => sub { +{} },
    handles => {
        has_state_for => 'exists',
        state_for     => 'get',
        add_state     => 'set',
    },
);

has 'breadboard' => (
    is      => 'ro',
    isa     => 'Bread::Board::Container',
    builder => 'build_breadboard',
    handles => {
        resolve_service => [ qw/resolve service/ ],
        add_service     => 'add_service',
    },
);

has 'completion_cb' => (
    is       => 'ro',
    isa      => 'CodeRef',
    traits   => ['Code'],
    required => 1,
    handles  => {
        finish => 'execute_method',
    },
);

sub handle_add_step {
    my ($self, $calling_step, $name, $args) = @_;
    return $self->add_step( $name, $args );
}

sub handle_success {
    my ($self, $step, $result) = @_;

    confess "result from step '$step' should be a hashref, not $result"
        unless _HASH($result);

    for my $key (keys %$result){
        # XXX: logger?
        warn "step $step is overwriting state $key.  this is bad."
            if $self->has_state_for($key);

        $self->add_state($key, $result->{$key});
    }

    $self->remove_running_step($step);
    $self->insert_completed_step($step);
    $self->dispatch;
}

sub handle_progress {
    my ($self, $step, @rest) = @_;
    print "progress: @rest\n";
}

sub handle_error {
    my ($self, $step, @rest) = @_;
    print "error: @rest\n";

    $self->remove_running_step($step);
    $self->insert_completed_step($step);
    $self->dispatch;
}

sub add_step_type {
    my ($self, $name, $def) = @_;

    my $step = App::f::Breadboard::Service::Step->new(
        name => $name,
        %$def,
    );

    $self->add_service($step);

    return $step;
}

sub add_step {
    my ($self, $step, $arg) = @_;

    if(!blessed $step){
        $step = $self->build_step( $step, $arg );
    }

    my $exists = first { $step->equals($_) } (
        $self->get_worklist, $self->get_running_steps, $self->get_completed_steps,
    );

    $self->add_work($step) unless $exists;
    $self->dispatch;

    return $step;
}

sub ready_to_execute {
    my ($self, $step) = @_;
    return reduce { $a && $b } 1, 1, map { $self->has_state_for($_) } $step->dependencies;
}

sub execute_step {
    my ($self, $step) = @_;
    my @deps = $step->dependencies;
    my %deps;

    for my $dep (@deps){
        confess "internal error: trying to run step '$step' without required dependency '$dep' having been satisfied"
            unless $self->has_state_for($dep);

        $deps{$dep} = $self->state_for($dep);
    }

    $self->insert_running_step($step);
    $self->delete_work($step);

    return $step->execute(\%deps);
}

sub build_step {
    my ($self, $class, $args) = @_;
    my @params = defined $args ? ( parameters => $args ) : () ;
    return $self->resolve_service( $class, @params );
}

sub dispatch {
    my $self = shift;

    if( !$self->has_work ) {
        $self->finish;
        return;
    }

    my @ready = grep { $self->ready_to_execute($_) } $self->get_worklist;
    $self->execute_step($_) for @ready;
    return;
}

sub build_breadboard {
    my ($self) = @_;

    weaken $self;
    return container 'f' => as {
        service 'manager' => $self;

        my %method_map = (
            tick_cb       => 'handle_progress',
            completion_cb => 'handle_success',
            error_cb      => 'handle_error',
            add_step_cb   => 'handle_add_step',
        );

        for my $service (keys %method_map) {
            my $method = $method_map{$service};
            service $service => (
                dependencies => { manager => depends_on('manager') },
                block        => sub {
                    my $s = shift;
                    my $self = $s->param('manager');
                    return sub { $self->$method( @_ ) };
                },
            );
        }
    };
}

__PACKAGE__->meta->make_immutable;
1;
