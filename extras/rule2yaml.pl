#!/usr/bin/perl
use strict;
use Net::Snort::Parser::Rule;
use YAML;
use YAML::Dumper;


while(<STDIN>) {
	chomp;
	my $rule = Net::Snort::Parser::Rule->new->parse_rule($_);

	if(!$rule) {
		$rule = {'failed' => 'Unable to parse rule'};
	}
	else {
		if(!$rule->{'failed'}) {
                        my $rp = Net::Snort::Parser::Rule->new();

                        $rp->{'noautorev'} = 1;
                        $rule->{'optomized'} = $rp->build_rule($rule);
		}
	}

	delete $rule->{'options'};
	print YAML::Dumper->new->dump($rule);
}
