package App::f::Step;
# ABSTRACT: a task to perform that takes time and has dependencies
use Moose::Role;
use namespace::autoclean;
use Set::Object qw(set);
use MooseX::Types::Set::Object;

has 'dependencies' => (
    is      => 'ro',
    isa     => 'Set::Object',
    default => sub { set },
);

has 'tick_cb' => (
    traits  => ['Code'],
    isa     => 'CodeRef',
    handles => {
        tick => 'execute',
    },
);

has 'error_cb' => (
    traits  => ['Code'],
    isa     => 'CodeRef',
    handles => {
        error => 'execute',
    },
);

# calculate and return the estimated duration in total number of calls
# to the completion callback ("ticks")
requires 'duration';

# run the job and keep the caller informed of the status.  takes args:
# manager, hashref of satisfied deps, progress callback, completion callback,
# error callback
requires 'execute';

1;
