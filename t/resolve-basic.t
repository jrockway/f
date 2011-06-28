use strict;
use warnings;
use Test::More;
use Test::Fatal;

use ok 'App::f::Step::Resolve';

{
    my ($h, $v);

    is exception { ($h, $v) = App::f::Step::Resolve->detect_module('Moose') }, undef,
        'detect_module lives ok';

    ok $h, 'has Moose';
    cmp_ok $v, '>', 2, 'got a sane version';
}

my @new_steps;

my $resolve = App::f::Step::Resolve->new(
    add_step_cb   => sub { shift; push @new_steps, @_ },
    completion_cb => sub { },
    error_cb      => sub { },
    tick_cb       => sub { },
    module        => 'Moose',
);

$resolve->execute();



done_testing;
