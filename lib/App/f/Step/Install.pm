package App::f::Step::Install;
# ABSTRACT: step to install a module
use Moose;
use namespace::autoclean;

use Module::Metadata;
use App::f::Subprocess;

with 'App::f::Step::WithDist';

sub BUILD {
    my $self = shift;
    $self->add_named_dep('unpack');
    $self->add_named_dep('configure');
    $self->add_named_dep('build');
    $self->add_named_dep('test');
}

sub do_install {
    my ($self, $build_type, $dir, $cb) = @_;

    my $install_cmd = $build_type eq 'Build.PL' ?
        [qw{./Build install}] : [qw/make install/];

    my $installer = App::f::Subprocess->new(
        command          => $install_cmd,
        directory        => $dir,
        report_output_to => $self,
        on_completion    => $cb,
    );

    $self->tick( progress => "Install in $dir" );
    $installer->run;
}

sub determine_modules_installed {
    my ($self, $dir) = @_;

    my @kids = $dir->children;
    my @dirs = grep { $_->isa('Path::Class::Dir') } @kids;
    my @files = grep { $_->isa('Path::Class::File') } @kids;

    my @meta = map { Module::Metadata->new_from_file( $_, collect_pod => 0 ) } @files;
    my @data = map {
        my $m = $_;
        ( map { [ $_ => eval { $m->version($_)->{original} } ] }
              grep { $_ ne 'main' } $m->packages_inside )
    } @meta;

    return (
        @data,
        map { $self->determine_modules_installed($_) } @dirs,
    );
}

sub execute {
    my ($self, $deps) = @_;

    my $build_type = $self->get_named_dep($deps, 'configure');
    my $dir        = $self->get_named_dep($deps, 'unpack');

    $self->do_install( $build_type, $dir, sub {
        $self->tick( progress => "Install in $dir done" );

        my @mods = $self->determine_modules_installed($dir->subdir('blib'));

        # we installed the dist and all the modules in the dist
        $self->done({
            $self->named_dep('install') => 1,
            map { ($_->[0]. ':install' => $_->[1]) } @mods,
        });
    });
}

__PACKAGE__->meta->make_immutable;
1;
