#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('Bullpen::Client');
}

my $client = Bullpen::Client->new(
    coordinator_address => 'tcp://127.0.0.1:6666',
    publisher_address   => 'tcp://127.0.0.1:7777',
);

diag "Make sure you have started a worker and server process using the conf/testing/*.json configs";

for ( 0 .. 10 ) {
    $client->send_request( 'testing' );
    my $count = 0;
    while ( my $message = $client->get_message ) {
        $count++;
        is($message, "[$count]", '... got the expected message');
    }
    is($count, 50, '... got the expected number of messages');
    $client->close;
    $client->reconnect;
}

$client->close;

done_testing;