use strict;
use warnings;
use Test::More;

use App::f::Manager;
use App::f::Breadboard::Service::Step;

my $completed = 0;

my $manager = App::f::Manager->new( completion_cb => sub { $completed++ } );

{ package WithDep;
  use Moose;
  with 'App::f::Step';
  sub BUILD {
      my $self = shift;
      $self->add_dependency('add_step');
  }
  sub execute {
      my $self = shift;
      $self->done({ with_dep => 1 });
  }

  package WithoutDep;
  use Moose;
  with 'App::f::Step';
  sub execute {
      my $self = shift;
      $self->done({ without_dep => 1 });
  }

  package Adder;
  use Moose;
  with 'App::f::Step';
  sub execute {
      my $self = shift;
      $self->add_step( 'WithDep', {} );
      $self->add_step( 'WithoutDep', {} );
      $self->done({ add_step => 1 });
  }
}

$manager->add_service(
    App::f::Breadboard::Service::Step->new(name  => $_, class => $_),
) for qw/Adder WithDep WithoutDep/;

$manager->add_step('Adder');

ok $manager->state_for( 'add_step' ),    'finished the Adder step';
ok $manager->state_for( 'with_dep' ),    'finished the step with a dependency on added_step';
ok $manager->state_for( 'without_dep' ), 'finished the added step without a dep';

is $completed, 1, 'ran out of work exactly once';

done_testing;
