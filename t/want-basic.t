use strict;
use warnings;
use Test::More;
use Test::Fatal;

use ok 'App::f::Step::Want';

{
    my ($h, $v);

    is exception { ($h, $v) = App::f::Step::Want->detect_module('Moose') }, undef,
        'detect_module lives ok';

    ok $h, 'has Moose';
    cmp_ok $v, '>', 2, 'got a sane version';
}

my @new_steps;

my $want = App::f::Step::Want->new(
    add_step_cb   => sub { shift; push @new_steps, @_ },
    completion_cb => sub { },
    error_cb      => sub { },
    tick_cb       => sub { },
    module        => 'Moose',
    version       => 'undef',
);

$want->execute();

ok @new_steps, 'got some new steps';

done_testing;
