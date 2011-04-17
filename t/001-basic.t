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

while (1) {
    print "? ";
    my $input = <STDIN>;
    chomp $input;

    $client->send_request( $input );

    while ( my $message = $client->get_message ) {
        warn "got $message";
    }
    warn "no more messages";
}

done_testing;