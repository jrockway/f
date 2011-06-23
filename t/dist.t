use strict;
use warnings;
use Test::More;

use ok 'App::f::Dist';

my $dist = App::f::Dist->new(
    name    => 'Foo-Bar',
    version => '0.01',
    source  => 'cpan://J/JR/JROCKWAY/Foo-Bar-0.01.tar.gz',
);

is $dist->to_id, 'Foo-Bar';
is $dist->named_step('unpack'), 'Foo-Bar:unpack';

done_testing;
