package App::f::Step::Build;
# ABSTRACT: step to build a dist ("make" or equivalent)
use Moose;
use namespace::autoclean;
use AnyEvent::Subprocess;

with 'App::f::Step::WithDist';

has 'prereqs' => (
    init_arg => 'prereqs',
    isa      => 'ArrayRef[Str]',
    required => 1,
    traits   => ['Array'],
    handles  => { prereqs => 'elements' },
);

sub BUILD {
    my $self = shift;
    $self->add_named_dep('unpack');
    $self->add_named_dep('configure');

    for my $mod ($self->prereqs){
        $self->add_dependency( "$mod:installed" );
    }
}

sub execute {
    my ($self, $deps) = @_;

    my $build_type = $self->get_named_dep($deps, 'configure');
    my $dir        = $self->get_named_dep($deps, 'unpack');

    my $build_cmd = $build_type eq 'Build.PL' ? ['./Build'] : ['make'];

    my $build = AnyEvent::Subprocess->new(
        code => sub {
            chdir $dir;
            exec @$build_cmd,
        },
        on_completion => sub {
            $self->tick( message => 'Built '. $self->dist_name );
            $self->done({ $self->named_dep('build') => 1 });
        },
    );

    $build->run;

    return;
}

__PACKAGE__->meta->make_immutable;
1;
