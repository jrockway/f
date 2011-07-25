package App::f::Subprocess;
# ABSTRACT: AnyEvent::Subprocess
use Moose;
use namespace::autoclean;
use Moose::Util::TypeConstraints;
use MooseX::Types::Path::Class qw(Dir);

has 'command' => (
    is       => 'ro',
    isa      => 'CodeRef|ArrayRef[Str]',
    required => 1,
);

has 'directory' => (
    is        => 'ro',
    isa       => Dir,
    predicate => 'has_directory',
    coerce    => 1,
);

has 'report_output_to' => (
    is       => 'ro',
    isa      => duck_type([qw/tick/]),
    required => 1,
    handles  => ['tick'],
);

has 'on_completion' => (
    is       => 'ro',
    isa      => 'CodeRef',
    required => 1,
);

has '_code' => (
    init_arg => undef,
    reader   => 'code',
    isa      => 'CodeRef',
    lazy     => 1,
    builder  => '_build_code',
);

sub _build_code {
    my ($self) = @_;
    my $command = $self->command;

    # if we don't need to chdir anywhere, we can just return the
    # command unmodified.
    return $command if !$self->has_directory;

    my $directory = $self->directory;

    if(ref $command eq 'ARRAY'){
        return sub {
            chdir $directory;
            exec @$command;
        };
    }

    return sub {
        chdir $directory;
        goto $command;
    };

}

has 'job' => (
    init_arg   => undef,
    reader     => 'job',
    does       => 'AnyEvent::Subprocess::Job',
    lazy_build => 1,
    handles    => ['run'],
);

sub _build_job {
    my ($self) = @_;

    my $code = $self->code;
    my $done = $self->on_completion;

    my @capture = map {
        AnyEvent::Subprocess::Job::Delegate::MonitorHandle->new(
            name      => "${_}_monitor",
            handle    => $_,
            when      => 'Line',
            callbacks => [ sub { $self->tick( output => $_[0] ) } ],
        ),
    } qw/stdout stderr/;

    my $job = AnyEvent::Subprocess->new(
        code          => $code,
        on_completion => $done,
        delegates     => [ 'StandardHandles', @capture ],
    );

    return $job;
}

__PACKAGE__->meta->make_immutable;
1;
