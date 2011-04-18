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
    clearer => '_clear_coordinator'
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
    clearer => '_clear_subscriber'
);

sub BUILD {
    my $self = shift;
    $self->subscriber;
    $self->coordinator;
}

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

# ...

sub reconnect {
    my $self = shift;
    $self->subscriber;
    $self->coordinator;
}

sub close {
    my $self = shift;
    $self->subscriber->close();
    $self->_clear_subscriber;
    $self->coordinator->close();
    $self->_clear_coordinator;
}

sub DEMOLISH { (shift)->close }

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

# ABSTRACT: A Moosey solution to this problem

=head1 SYNOPSIS

  use Bullpen::Client;

  my $client = Bullpen::Client->new(
      coordinator_address => 'tcp://127.0.0.1:6666',
      publisher_address   => 'tcp://127.0.0.1:7777',
  );

  $client->send_request( 'some message' );
  while ( my $message = $client->get_message ) {
      say $message;
  }

  $client->close;

=head1 DESCRIPTION

