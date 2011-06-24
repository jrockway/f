package App::f::Breadboard::Service::Step;
# ABSTRACT: Bread::Board service for Steps
use Moose;
use namespace::autoclean;

extends 'Bread::Board::ConstructorInjection';

sub BUILD {
    my $self = shift;
    map {
        $self->add_dependency(
            $_,
            Bread::Board::Dependency->new( service_path => "/f/$_" ),
        )
    } qw/tick_cb completion_cb error_cb/;

}

__PACKAGE__->meta->make_immutable;
1;
