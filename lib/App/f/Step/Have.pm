package App::f::Step::Have;
# ABSTRACT: subclass of Want for modules that we already Have
use Moose;
use namespace::autoclean;

extends 'App::f::Step::Want';

sub execute {
    my $self = shift;
    $self->done({
        $self->named_dep('want')      => 1,
        $self->named_dep('install')   => $self->version,
        $self->named_dep('installed') => $self->version,
    });
}

# the reason this class exists is to compare equal to future Want
# requests, satisfying them without doing any resolution or module
# loading.  this is important for dependencies that aren't actually
# modules, like "perl > 5.14.0".
#
# why the META spec treats "perl" as a module dependency is beyond me,
# but this is better than special-casing "perl" in a bunch of
# different places.
#
# -JR

__PACKAGE__->meta->make_immutable;
1;
