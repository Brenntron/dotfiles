#!/usr/bin/env perl -w
#
# Name: snort_json_parser.pl
#
# Description: JSON output from Net Snort Parser
# Author: Marlin W. Pierce
#


use strict;
use Net::Snort::Parser::Rule;
use Net::Snort::Parser::File;
use JSON;


my $parser = Net::Snort::Parser::Rule->new();
$parser->{'noautorev'} = 1;


my $json = "init";
my $error_msg = "";
while(<>) {
    my $line = $_;

    chomp($line);
    $line =~ s/^\s+//;
    $line =~ s/\s+$//;

    if ($line =~ /^\s*$/) {
        next;
    }

    my $parsed_rule = $parser->parse_rule($line);

    if (!$parsed_rule) {
        $error_msg = "Line $.: not a rule";
        $json = encode_json( { 'error' => $error_msg } );
    }
    elsif($parsed_rule->{'failed'}) {
        $error_msg = "Line $.: FAILED - $parsed_rule->{failed}";
        $json = encode_json( { 'error' => $error_msg } );
    }
    else {
        $json = encode_json($parsed_rule);
    }

    print "$json\n";
}

