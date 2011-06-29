package App::f::Step::Unpack;
# ABSTRACT: download and unpack a dist
use Moose;
use namespace::autoclean;
use MooseX::Types::Path::Class qw(Dir);

use AnyEvent::Subprocess;
use Path::Class qw(dir);

with 'App::f::Step::WithDist';

has 'unpack_directory' => (
    is       => 'ro',
    isa      => Dir,
    required => 1,
    coerce   => 1,
);

sub BUILD {
    my $self = shift;
    $self->add_named_dep('download');
}

sub execute {
    my ($self, $deps) = @_;

    my $file = $deps->{$self->named_dep('download')};

    my $unpack_to = $self->unpack_directory->subdir($self->dist_name);
    $unpack_to->rmtree; # kill artifacts
    $unpack_to->mkpath;

    my $untar = AnyEvent::Subprocess->new(
        delegates     => [
            'StandardHandles',
        ],
        code          => ['tar', 'xf', "$file", '-C', "$unpack_to"],
        on_completion => sub {
            my @dirs = grep { $_->isa('Path::Class::Dir') } $unpack_to->children;
            my $dir = shift @dirs;
            $self->tick( message => "Unpacked ". $self->dist_name. " to $dir" );
            $self->done({ $self->named_dep('unpack') => $dir });
        }
    );

    my $get_line; $get_line = sub {
        my ($h, $line, $eol) = @_;
        $self->tick( message => "tar: $line" );
        $h->push_read( line => $get_line );
    };

    my $run = $untar->run;
    $run->delegate('stderr')->handle->push_read( line => $get_line );
    $run->delegate('stdout')->handle->push_read( line => $get_line );
}

__PACKAGE__->meta->make_immutable;
1;
