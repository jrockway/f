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
my $s = App::f::Step::Download->new({
    download_directory => $out,
    mirror             => 'http://search.cpan.org/CPAN/',
    add_step_cb        => sub { },
    completion_cb      => sub { shift; $cv->send(@_) },
    error_cb           => sub { shift; $cv->croak(\@_) },
    tick_cb            => sub { },
});

my $dist = App::f::Dist->new(
    name    => 'Moose',
    version => '2.0010',
    source  => 'cpan://D/DO/DOY/Moose-2.0010.tar.gz'
);

$s->execute({ distribution => $dist });

my $res = try {
    $cv->recv;
}
catch {
    croak $_;
};

ok -f $res->{file};
is -s $res->{file}, 661633;

done_testing;
