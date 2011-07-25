package App::f::Step::Configure;
# ABSTRACT: step to configure a dist (read META.json, run Makefile.PL)
use Moose;
use namespace::autoclean;
use App::f::Subprocess;

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
    $self->add_named_dep('meta');

    for my $mod ($self->prereqs){
        $self->add_dependency( "$mod:installed" );
    }
}

sub do_configure {
    my ($self, $dir, $cb) = @_;

    my $makefile_pl = $dir->file('Makefile.PL');
    my $build_pl    = $dir->file('Build.PL');

    my $type;

    $type = ['perl', 'Build.PL'] if -e $build_pl;
    $type = ['perl', 'Makefile.PL'] if -e $makefile_pl;

    if(!$type){
        $self->error( sprintf(
            q{Don't know how to configure %s: no Build.PL or Makefile.PL},
            $self->dist_name,
        ));

        return;
    }

    my $config = App::f::Subprocess->new(
        command          => sub { close *STDIN; exec @$type },
        directory        => $dir,
        report_output_to => $self,
        on_completion    => sub {
            $self->tick( message => 'configured ' . $self->dist->name );
            $cb->($type);
        },
    );

    $config->run;
}

sub read_meta {
    my ($self, $dir) = @_;

}

sub execute {
    my ($self, $deps) = @_;

    my $dir = $deps->{$self->named_dep('unpack')};

    $self->do_configure($dir, sub {
        my $type = shift;

        # my $meta = $self->reread_meta;
        my $meta = $self->get_named_dep($deps, 'meta');

        my @prereqs;
        for my $stage (qw/build runtime test/){
            my $requires = $meta->prereqs->{$stage}{requires};
            for my $module (keys %$requires){
                my $version = $requires->{$module};
                $self->add_step( Want => { module => $module, version => $version || 0 } );
                push @prereqs, $module;
            }
        }

        $self->add_step( Build => {
            dist    => $self->dist,
            prereqs => \@prereqs,
        });

        $self->done({
            $self->named_dep('configure') => $type,
        });
    });

    return;
}

__PACKAGE__->meta->make_immutable;
1;
