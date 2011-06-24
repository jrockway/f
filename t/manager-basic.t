use strict;
use warnings;
use Test::More;
use ok 'App::f::Manager';
use App::f::Breadboard::Service::Step;

my $manager = App::f::Manager->new;

my ($get, $build, $install);

{ package Get;
  use Moose;
  with 'App::f::Step';
  has 'dist' => ( is => 'ro', isa => 'Str', required => 1 );

  sub execute {
      my $self = shift;
      $get++;
      $self->done( { $self->dist. ':unpack' => '/tmp/'. $self->dist } );
      return;
  }

  package Build;
  use Moose;
  with 'App::f::Step';
  has 'dist' => ( is => 'ro', isa => 'Str', required => 1 );

  sub BUILD {
      my $self = shift;
      $self->add_dependency( $self->dist. ':unpack' );
  }

  sub execute {
      my $self = shift;
      $build++;
      $self->done( { $self->dist. ':build' => 1 } );
      return;
  }

  package Install;
  use Moose;
  with 'App::f::Step';
  has 'dist' => ( is => 'ro', isa => 'Str', required => 1 );

  sub BUILD {
      my $self = shift;
      $self->add_dependency( $self->dist. ':unpack' );
      $self->add_dependency( $self->dist. ':build' );
  }

  sub execute {
      my $self = shift;
      $install++;
      $self->done( { $self->dist. ':install' => 1 } );
      return;
  }
}

$manager->add_service(
    App::f::Breadboard::Service::Step->new(
        name       => 'Get',
        class      => 'Get',
        parameters => { dist => { required => 1 } },
    ),
);

$manager->add_service(
    App::f::Breadboard::Service::Step->new(
        name       => 'Build',
        class      => 'Build',
        parameters => { dist => { required => 1 } },
    ),
);

$manager->add_service(
    App::f::Breadboard::Service::Step->new(
        name       => 'Install',
        class      => 'Install',
        parameters => { dist => { required => 1 } },
    ),
);

my $get_moose = $manager->build_object( 'Get', { dist => 'Moose' } );
$manager->add_step( $get_moose );

is $get, 1, 'got moose';
ok $manager->has_state_for('Moose:unpack'), 'unpacked Moose';

my $build_moose = $manager->build_object( 'Build', { dist => 'Moose' } );
$build_moose->add_dependency('Class::MOP:install');
$manager->add_step( $build_moose);

ok !$build, 'cannot build moose yet, need cmop';

my $install_moose = $manager->build_object( 'Install', { dist => 'Moose' } );
$manager->add_step( $install_moose );

ok !$install, 'cannot install moose yet, need to build it';

my $install_cmop = $manager->build_object( 'Install', { dist => 'Class::MOP' } );
$manager->add_step( $install_cmop );

ok !$install, 'cannot install cmop yet, need to build it';

my $build_cmop = $manager->build_object( 'Build', { dist => 'Class::MOP' } );
$manager->add_step( $build_cmop );

ok !$build, 'cannot build cmop yet, need to get it';

my $get_cmop = $manager->build_object( 'Get', { dist => 'Class::MOP' } );
$manager->add_step( $get_cmop );

is $get, 2, 'got cmop and moose';
is $build, 2, 'built cmop and moose';
is $install, 2, 'installed cmop and moose';

done_testing;
