package App::f::Step::Download;
# ABSTRACT: download stuff from CPAN (and elsewhere)
use Moose;
use namespace::autoclean;

use MooseX::Types::Path::Class 'Dir';
use MooseX::Types::URI 'Uri';

use AnyEvent::HTTP;
use File::Slurp qw(write_file);

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
    http_get $uri, sub {
        my ($data, $headers) = @_;
        $self->tick( message => sprintf(
            'Downloaded %s (%d) to %s',
            $uri,
            length $data,
            $file,
        ));
        write_file( $file->stringify, $data );
        $cb->( $file );
    };
}

sub execute {
    my ($self, $deps) = @_;
    my $dist = $self->dist;

    (my $cpan_path = $dist->source) =~ s|^cpan://||;
    my $uri = join '/', $self->mirror, 'authors', 'id', $cpan_path;

    my $target = $self->download_directory->file($cpan_path);
    $target->parent->mkpath;

    $self->download($uri, $target, sub {
        $self->done({ $self->named_dep('download') => $target });
    });

    return;
}

with 'App::f::Step::WithDist';

__PACKAGE__->meta->make_immutable;

1;
