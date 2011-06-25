package App::f::Manager;
# ABSTRACT: class to run the tasks at the right time
use Moose;
use namespace::autoclean;

use MooseX::Types::Set::Object;

use Bread::Board;
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

sub handle_add_step {
    my ($self, $calling_step, $name, $args) = @_;
    my $step = $self->build_object( $name, $args );
    $self->add_step( $step );
    return $step;
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

    $self->dispatch;
}

sub handle_progress {
    my ($self, $step, @rest) = @_;
    print "progress: @rest\n";
}

sub handle_error {
    my ($self, $step, @rest) = @_;
    print "error: @rest\n";
}

sub add_step {
    my ($self, $step) = @_;
    my $exists = first { $step->equals($_) } $self->get_worklist;
    $self->add_work($step) unless $exists;
    $self->dispatch;
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

    $self->delete_work($step);

    return $step->execute(\%deps);
}

sub build_object {
    my ($self, $class, $args) = @_;
    my @params = defined $args ? ( parameters => $args ) : () ;
    return $self->resolve_service( $class, @params );
}

sub dispatch {
    my $self = shift;
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
