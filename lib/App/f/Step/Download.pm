package App::f::Step::Download;

use Moose;
use LWP::Simple;
use MooseX::Types::Path::Class 'Dir';
use MooseX::Types::URI 'Uri';
use namespace::autoclean;

has mirror => (
    is       => 'ro',
    isa      => Uri,
    coerce   => 1,
    required => 1,
);

has download_directory => (
    is       => 'ro',
    isa      => Dir,
    coerce   => 1,
    required => 1,
);

sub download {
    my ($self, $uri, $file, $cb) = @_;

    my $pid = fork;

    if (!$pid) {
        mirror($uri, $file);
        exit 0;
    }

    my $done = AnyEvent->condvar;
    my $c = AnyEvent->child(
        pid => $pid,
        cb  => sub {
            $self->error('download failed with status ' . $_[1])
                if $_[1] != 0;
            $done->send;
        },
    );

    $done->recv;
    $cb->();
}

sub duration { 1 }

sub execute {
    my ($self, $deps) = @_;
    my $dist = $deps->{distribution};

    (my $cpan_path = $dist->source) =~ s|^cpan://||;
    my $uri = join '/', $self->mirror, 'authors', 'id', $cpan_path;

    my $target = $self->download_directory->file($cpan_path);
    $target->parent->mkpath;

    $self->download($uri, $target, sub {
        $self->done({ file => $target });
    });
}

with 'App::f::Step';

__PACKAGE__->meta->make_immutable;

1;
