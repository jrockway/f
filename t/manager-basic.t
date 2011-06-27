use strict;
use warnings;
use Test::More;
use ok 'App::f::Manager';
use App::f::Breadboard::Service::Step;

my $completed = 0;
my $manager = App::f::Manager->new( completion_cb => sub { $completed++ } );

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

$manager->add_step( 'Get', { dist => 'Moose' } );
is $get, 1, 'got moose';
ok $manager->has_state_for('Moose:unpack'), 'unpacked Moose';

is $completed, 1, 'ran out of work';

$manager->add_step( 'Build', {
    dist  => 'Moose',
    fixup => sub {
        my $obj = shift;
        $obj->add_dependency('Class::MOP:install');
        return $obj;
    },
});
ok !$build, 'cannot build moose yet, need cmop';

$manager->add_step( 'Install', { dist => 'Moose' } );
ok !$install, 'cannot install moose yet, need to build it';

$manager->add_step( 'Install', { dist => 'Class::MOP' } );
ok !$install, 'cannot install cmop yet, need to build it';

$manager->add_step( 'Build', { dist => 'Class::MOP' } );
ok !$build, 'cannot build cmop yet, need to get it';

my $get_cmop = $manager->add_step( 'Get', { dist => 'Class::MOP' } );
is $get, 2, 'got cmop and moose';
is $build, 2, 'built cmop and moose';
is $install, 2, 'installed cmop and moose';

is $completed, 2, 'ran out of work again';

done_testing;
