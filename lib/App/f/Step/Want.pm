package App::f::Step::Want;
# ABSTRACT: indicate the desire to install a module
use Moose;
use namespace::autoclean;

use App::f::Util qw(is_newer_than);

with 'App::f::Step';

has 'module' => ( is => 'ro', isa => 'Str', required => 1 );
has 'version' => ( is => 'ro', isa => 'Maybe[Str]', required => 1 );

sub execute {
    my $self = shift;
    $self->tick( message => 'Want '. $self->module. ' '. ($self->version || '<undef>') );
    $self->add_step( Installed => { module => $self->module } );

    if(my $v = $self->has_new_enough_version){
        $self->done({ $self->module . ':install' =>  $v, $self->module . ':want' => 1 });
    }
    else {
        $self->add_step( Resolve => { module => $self->module, version => $self->version } );
        $self->done({ $self->module . ':want' => 1 });
    }
}

sub has_new_enough_version {
    my $self = shift;

    my $module = $self->module;
    my ($has, $version) = $self->detect_module($module);

    # if we have the module and the version we want is not > than the
    # version we have, we're done here.  if the version parsing blows
    # up, then install anyway

    return try {
        if($has && !is_newer_than($self->version, $version)){
            return $version || 1;
        }
        return;
    }
    catch {
        $self->tick( message => "Version parsing blew up on $module: $_" );
        return;
    };
}

sub detect_module {
    my ($self, $module) = @_;

    my $has = 0;
    my $version = eval {
        Class::MOP::load_class($module);
        $has = 1;
        my $meta = Class::MOP::Package->initialize($module);
        ${$meta->get_package_symbol('$VERSION')};
    };

    return ($has, $version);
}

sub equals {
    my ($self, $other) = @_;

    return unless $other->isa( __PACKAGE__ );
    return unless $self->module eq $other->module;


    # return unless # versions parse ok
    #     eval { version->parse($self->version) } &&
    #                eval { version->parse($other->version) } && 1;
    # return !is_newer_than($other, $self);

    return 1;
}

__PACKAGE__->meta->make_immutable;
1;
