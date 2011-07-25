package App::f::UI;
# ABSTRACT: a pretty UI for f
use Moose;
use namespace::autoclean;
use Hash::Util::FieldHash qw(fieldhash);

has 'progress' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub {
        fieldhash my %hash;
        return \%hash;
    },
);

has 'steps' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub {
        fieldhash my %hash;
        return \%hash;
    },
);

has 'done_count' => (
    is      => 'ro',
    traits  => ['Counter'],
    handles => { inc_done_count => 'inc' },
    default => sub { 0 },
);

has 'seen_count' => (
    is      => 'ro',
    traits  => ['Counter'],
    handles => { inc_seen_count => 'inc' },
    default => sub { 0 },
);

my @spinner = qw{ | / - \\ };

sub inc_step {
    my ($self, $step) = @_;
    my $progress = $self->progress;
    $progress->{$step} ||= 0;
    return $progress->{$step}++;
}

sub report_seen {
    my ($self, @steps) = @_;
    map {
        if(!exists $self->steps->{$_}){
            $self->steps->{$_} = $_;
            $self->inc_seen_count;
        }
    } @steps;
    $self->draw;
}

sub report_in_flight {
    my ($self, @steps) = @_;
    map { $self->inc_step($_) } @steps;
    $self->draw;
}

sub report_progress {
    my ($self, @steps) = @_;
    map { $self->inc_step($_) } @steps;
    $self->draw;
}

sub report_done {
    my ($self, @steps) = @_;
    map {
        delete $self->progress->{$_};
        delete $self->steps->{$_};
        $self->inc_done_count;
    } @steps;
    $self->draw;
}

# XXX: cut-n-paste
sub format_step {
    my ($self, $step) = @_;
    my $name = $step->meta->name;
    $name =~ s/^App::f::Step:://g;
    my $json = JSON->new->allow_blessed(1)->convert_blessed(1)->encode($step);
    return "$name=$json";
}

sub draw {
    my $self = shift;
    my $progress = $self->progress;
    my $steps    = $self->steps;

    print `clear`;
    print "Doing some awesome things:\n\n";
    for my $key (sort keys %$progress){
        my $progress = $progress->{$key};
        my $spinner  = $progress == 1 ? ':' : $spinner[$progress % @spinner];
        my $step     = $self->format_step($steps->{$key});
        print "\t $spinner $step\n";
    }
    print "\n\n";
    my $total = $self->seen_count;
    my $done  = $self->done_count;

    my $equals = eval { 80 * $done/$total } || 0;
    my $blanks = 80 - $equals;

    print "[=";
    print "=" x $equals;
    print ">";
    print " " x $blanks;
    print "] $done/$total\n\n";

}

__PACKAGE__->meta->make_immutable;
1;
