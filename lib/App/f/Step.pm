package App::f::Step;
# ABSTRACT: a task to perform that takes time and has dependencies
use Moose::Role;
use namespace::autoclean;
use Set::Object qw(set);
use MooseX::Types::Set::Object;

has '_dependencies' => (
    is      => 'ro',
    isa     => 'Set::Object',
    default => sub { set },
    handles => {
        add_dependency   => 'insert',
        dependencies     => 'members',
        has_dependencies => 'count',
    },
);

has 'add_step_cb' => (
    traits   => ['Code'],
    isa      => 'CodeRef',
    required => 1,
    handles  => {
        add_step => 'execute_method',
    },
);

has 'tick_cb' => (
    traits   => ['Code'],
    isa      => 'CodeRef',
    required => 1,
    handles  => {
        tick => 'execute_method',
    },
);

has 'completion_cb' => (
    traits   => ['Code'],
    isa      => 'CodeRef',
    required => 1,
    handles  => {
        done => 'execute_method',
    },
);

has 'error_cb' => (
    traits   => ['Code'],
    isa      => 'CodeRef',
    required => 1,
    handles  => {
        error => 'execute_method',
    },
);

# run the job and keep the caller informed of the status.  takes args:
# hashref of satisfied deps
requires 'execute';

# given another step, returns true if this step is identical.  note
# that if $a->equals($b) then $b->equals($a).  violating this
# condition may result in serious injury.
#
# defaults to nothing being equal to anything else.

sub equals {
    my ($self, $other) = @_;
    return;
}

1;
