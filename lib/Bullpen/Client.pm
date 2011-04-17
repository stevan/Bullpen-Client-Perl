package Bullpen::Client;
use Moose;

use ZeroMQ qw[ :all ];

has [ 'coordinator_address', 'publisher_address' ] => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'subscription_key' => (
    is      => 'ro',
    writer  => '_set_subscription_key',
    isa     => 'Str',
    trigger => sub {
        my ($self, $key) = @_;
        $self->subscriber->setsockopt(
            ZMQ_SUBSCRIBE,
            $key
        );
    }
);

has 'context' => (
    is       => 'ro',
    isa      => 'ZeroMQ::Context',
    lazy     => 1,
    default  => sub { ZeroMQ::Context->new }
);

has 'coordinator' => (
    is      => 'ro',
    isa     => 'ZeroMQ::Socket',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $coordinator = $self->context->socket( ZMQ_REQ );
        $coordinator->connect( $self->coordinator_address );
        $coordinator;
    },
);

has 'subscriber' => (
    is      => 'ro',
    isa     => 'ZeroMQ::Socket',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $subscriber = $self->context->socket( ZMQ_SUB );
        $subscriber->connect( $self->publisher_address );
        $subscriber;
    },
);

# method ...

sub send_request {
    my ($self, $request) = @_;
    $self->coordinator->send( $request );
    $self->_set_subscription_key( $self->coordinator->recv->data );
}

sub get_message {
    my $self = shift;
    my $key     = $self->subscription_key;
    my $message = $self->subscriber->recv->data;
    $message =~ s/^$key //;
    $message;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

# ABSTRACT: A Moosey solution to this problem

=head1 SYNOPSIS

  use Bullpen::Client;

=head1 DESCRIPTION

