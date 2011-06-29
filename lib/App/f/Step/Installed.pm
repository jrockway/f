package App::f::Step::Installed;
# ABSTRACT: task that completes when a module has been installed
use Moose;
use namespace::autoclean;

with 'App::f::Step';

has 'module' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub BUILD {
    my $self = shift;
    $self->add_dependency( $self->module . ':install' );
}

sub execute {
    my ($self, $deps) = @_;

    my $module = $self->module;
    my $version = $deps->{ "$module:install" } || '(unknown)';

    $self->tick( message => "Successfully installed ". $self->module. " <$version>" );
    $self->done({ "$module:installed" => $version });
}

__PACKAGE__->meta->make_immutable;
1;
