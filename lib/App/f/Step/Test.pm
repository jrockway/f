package App::f::Step::Test;
# ABSTRACT: step to test a dist ("make test" or equivalent)
use Moose;
use namespace::autoclean;
use App::f::Subprocess;

with 'App::f::Step::WithDist';

sub BUILD {
    my $self = shift;
    $self->add_named_dep('unpack');
    $self->add_named_dep('configure');
    $self->add_named_dep('build');
}

sub execute {
    my ($self, $deps) = @_;

    my $dir        = $self->get_named_dep($deps, 'unpack');
    my $build_type = $self->get_named_dep($deps, 'configure');

    my $test_cmd = $build_type eq 'Build.PL' ? ['perl', 'Build', 'test'] : ['make', 'test'];

    my $test = App::f::Subprocess->new(
        command          => $test_cmd,
        directory        => $dir,
        report_output_to => $self,
        on_completion    => sub {
            $self->tick( message => 'Tested '. $self->dist_name );
            $self->done({ $self->named_dep('test') => 1 });
        },
    );

    $test->run;

    return;
}

__PACKAGE__->meta->make_immutable;
1;
