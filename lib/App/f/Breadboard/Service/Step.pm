package App::f::Breadboard::Service::Step;
# ABSTRACT: Bread::Board service for Steps
use Moose;
use namespace::autoclean;

extends 'Bread::Board::BlockInjection';

has '+block' => (
    init_arg => undef,
    lazy     => 1,
    default  => sub {
        return sub {
            my $s = shift;
            my $fixup = $s->param('fixup');
            my $class = $s->class;

            my $obj = $class->new( $s->params );
            $obj = $fixup->($obj) if $fixup;
            return $obj;
        };
    },
);

sub BUILD {
    my $self = shift;
    map {
        $self->add_dependency(
            $_,
            Bread::Board::Dependency->new( service_path => "/f/$_" ),
        )
    } qw/tick_cb completion_cb error_cb add_step_cb/;

    $self->parameters->{fixup} = { isa => 'CodeRef', optional => 1 };
}

__PACKAGE__->meta->make_immutable;
1;
