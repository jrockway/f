use strict;
use warnings;
use Test::More;

use Try::Tiny;
use Devel::PartialDump 'croak';
use AnyEvent;
use FindBin;
use Path::Class;
use App::f::Dist;
use App::f::Step::Download;

my $cv = AnyEvent->condvar;

my $out = dir($FindBin::Bin, 'tmp', 'downloads');

my $dist = App::f::Dist->new(
    name    => 'Moose',
    version => '2.0010',
    source  => 'cpan://D/DO/DOY/Moose-2.0010.tar.gz'
);

my $s = App::f::Step::Download->new({
    dist               => $dist,
    download_directory => $out,
    mirror             => 'http://search.cpan.org/CPAN/',
    add_step_cb        => sub { },
    completion_cb      => sub { shift; $cv->send(@_) },
    error_cb           => sub { shift; $cv->croak(\@_) },
    tick_cb            => sub { },
});

$s->execute;

my $res = try {
    $cv->recv;
}
catch {
    croak $_;
};

ok -f $res->{'Moose:download'};
is -s $res->{'Moose:download'}, 661633;

done_testing;
