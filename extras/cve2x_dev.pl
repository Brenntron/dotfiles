#!/usr/bin/perl

#use warnings;
use strict;
use Switch;
use Getopt::Long;
use WWW::Mechanize;
use Data::Dumper;

##### Config #####

# TELUS login information - if applicable

my $telus_user 	= "sourcefirevr";
my $telus_pass 	= "2~wb32T*";
my $telus_subn 	= "2051-0001";
my $canvas_root = $ENV{"CANVAS_ROOT"} || "/nfs/research";
my $timeout    	= 5;                             # 5 second timeout for http connect

##################

# Global variables

my ($cve_file, $type, @cves, $cve, $msid, $source, $write, $verbose, $print, $ignore, $csv);

$ENV{"PERL_LWP_SSL_VERIFY_HOSTNAME"} = 0;

# All source information

my $source = {
	# Source abbreviation	  , Associated subroutine	 , Source full-name				, Source URL, 		CSV short name
	all    => { checked => "N", func => \&searchStart,         sname => "All",                                url => "Runs All Tests", csv_name => "" },
	ps     => { checked => "N", func => \&searchPacketstorm,   sname => "Packetstorm Security",               url => "http://packetstormsecurity.org/", csv_name => "other" },
	sf     => { checked => "N", func => \&searchSecurityfocus, sname => "Security Focus",                     url => "http://securityfocus.com/", csv_name => "bugtraq" },
	edb    => { checked => "N", func => \&searchExploitdb,     sname => "Exploit DB",                         url => "http://exploit-db.com/", csv_name => "expldb" },
	ms     => { checked => "N", func => \&searchMetasploit,    sname => "Metasploit",                         url => "http://metasploit.com/", csv_name => "metasploit" },
	cs     => { checked => "N", func => \&searchCore,          sname => "CORE Security",                      url => "http://coresecurity.com/", csv_name => "core" },
	telus  => { checked => "N", func => \&searchTelus,         sname => "TELUS",                              url => "http://telussecuritylabs.com/", csv_name => "telus" },
	osvdb  => { checked => "N", func => \&searchOSVDB,         sname => "OSVDB",                              url => "http://osvdb.org/", csv_name => "other" },
	mitre  => { checked => "N", func => \&searchMITRE,         sname => "MITRE",                              url => "http://cve.mitre.org/cgi-bin/cvename.cgi?name=", csv_name => "other" },
	canvas => { checked => "N", func => \&searchCANVAS,        sname => "CANVAS",                             url => "http://immunitysec.com/",  catalog => "$canvas_root/CANVAS_CATALOG", csv_name => "canvas" }
};


my @sources = sort keys %{$source};

GetOptions('c=s' => \$cve, 'f=s' => \$cve_file, 'p' => \$print, 't=s' => \$type, 'w' => \$write, 'v' => \$verbose, 'i=s' => \$ignore, 'y' => \$csv  );


##
## TODO LATER: GOOGLE QUERY
##
my @filter = (" ", "fedoraproject.org", "saintcorporation.com", "packetstormsecurity.org", "securityfocus.com", "exploit-db.com", "metasploit.com", "coresecurity.com", "osvdb.org");
my $query = ') ((exploit | (vuln | vulnerability) | sploit | hack | pwn) (filetype:java | filetype:py | filetype:pl | filetype:php | filetype:rb | filetype:sh | filetype:bat | filetype:c | filetype:c++ | filetype:cc | filetype:txt)) (intext:"#!/" | intext:"ruby" | intext:"python" | intext:"perl" | intext:”<?php” | intext:"bash" | intext:"#include")';


# Simple, search through all sources
sub searchStart($$)
{
	my $cve  = shift;
	my $type = shift;
	my $err  = undef;
	my @search;


	my @ignore = split( /,\s?/, $ignore );

	## If we are looking for all, pull in the sources alphabetically.
	## Otherwise, use type specified with -t
	($type eq lc "all") ? @search = sort @sources : $search[0] = $type;

	for my $sauce (sort @search)
	{
		next if $sauce eq lc "all";


		for( @ignore )
		{
			if( $sauce eq $_ )
			{
				$err = -1;
				last;
			}
		}

		if( $err )
		{
			$err = undef;
			next;
		}

		print "Searching: $source->{$sauce}->{sname}\n" if $verbose;
		$source->{$sauce}->{"func"}->($cve);

	} ## end for (sort @search)

	print "-" x 45, "\n" unless $write;
} ## end sub searchStart($$)

sub searchMITRE
{

	setChecked("mitre", "Y");

	my $cve = shift;
	my $url = $source->{"mitre"}->{"url"} . "CVE-$cve";
	my $mech = mechInit("mitre");

	$mech->get($url);

	my $info = ($mech->content =~ /<tr>\s*<th colspan="2">Description<\/th>\s*<\/tr>\s*<tr>\s*<td colspan="2">(.*?)<\/td>\s*<\/tr>/smig)[0];
	# Put the description all on one line.
	$info =~ s/\n/ /g;

	# Put search results into the source hash
	push(@{$source->{"mitre"}{"links"}}, $info) if $info;

} ## end sub searchMITRE

sub searchPacketstorm
{

	setChecked("ps", "Y");

	my $cve = shift;

	my $mech = mechInit("ps");

	$mech->get("http://packetstormsecurity.com/files/cve/CVE-$cve");

	my @results = $mech->content =~ /(files\/view\/\d+\/[^"]+)(?=(?:.+\/files\/tags\/exploit))"/smig;

	# Put search results into the source hash
	push(@{ $source->{"ps"}{"links"} }, "http://packetstormsecurity.org/$_") for @results;

} ## end sub searchPacketstorm

sub searchSecurityfocus
{

	setChecked("sf", "Y");

	my $cve = shift;

	my $mech = mechInit("sf");

	$mech->get("http://www.securityfocus.com/bid");

	$mech->submit_form(form_id => 0, fields => { CVE => "$cve" });

	if ($mech->content =~ /www.securityfocus\.com\/bid\/(\d+)/)
	{
		$mech->get("bid/$1/exploit");

		my (@res) = $mech->content =~ /class="title">.+<br\/>(.+)<\/ul>/smi;

		# Clean up the results a little bit
		$_ =~ s/\n//smg   for @res;
		$_ =~ s/<ul>//smg for @res;
		$_ =~ s/\t//smg   for @res;

		for (my $x = 0 ; $x < @res ; $x++)
		{
			if ($res[$x] =~ /(data\/vulnerabilities\/[^"]+)/)
			{
				push(@{ $source->{"sf"}{"links"} }, "http://securityfocus.com/$1");
			} 
		} 
	} 
} ## end sub searchSecurityfocus

sub searchExploitdb
{

	setChecked("edb", "Y");

	my $cve = shift;

	my $mech = mechInit("edb");

	# Sometimes Exploit-DB can be a bit lazy
	my $numtries = 3;
	do {
		$mech->get("https://www.exploit-db.com/search/?action=search&cve=$cve");
		$numtries--;
	} while(!($mech->success()) && ($numtries != 0) && (print STDERR ">>> Trying Exploit-DB again.\n"));

	my @results = $mech->content =~ /(https?:\/\/www.exploit-db.com\/exploits\/\d+)/smig;

	push(@{ $source->{"edb"}{"links"} }, $_) for @results;
} ## end sub searchExploitdb

sub searchMetasploit
{
	setChecked("ms", "Y");

	my $cve = shift;

	my $mech = mechInit("ms");

	$mech->get("http://www.rapid7.com/db/search?q=$cve&t=m");
	my @results = $mech->content =~ /(https?:\/\/github.com\/rapid7\/metasploit-framework\/blob\/master\/modules\/exploits\/[^"']+)["']\s*>\s*Source Code/smi;

	push(@{ $source->{"ms"}{"links"} }, $_) for @results;
} ## end sub searchMetasploit

sub searchCore
{
	print STDERR ">>> Core Security link has changed.  Check disabled!\n";
        setChecked("cs", "DISABLED");
        return;

	setChecked("cs", "Y");

	my $cve = shift;

	my $mech = mechInit("cs");

	$mech->get("http://www.coresecurity.com/index.php?module=SearchMod&action=index&q=$cve&x=12&y=10");

	if ($mech->content =~ /.*class="linkSearch" href="(http:\/\/www.coresecurity.com\/content\/.*[^\"]+)">/i)
	{
		push(@{ $source->{"cs"}{"links"} }, $1);
	}
} ## end sub searchCore

sub searchOSVDB
{

        print STDERR ">>> Need to add CloudFlare bybass.  Check disabled!\n";
        setChecked("osvdb", "DISABLED");
        return;

	setChecked("osvdb", "Y");

	my $cve = shift;

	my $mech = mechInit("osvdb");

	$mech->get("http://osvdb.org/search/search?search%5Bvuln_title%5D=&search%5Btext_type%5D=titles&search%5Bs_date%5D=&search%5Be_date%5D=&search%5Brefid%5D=$cve&search%5Breferencetypes%5D=CVEID&search%5Bvendors%5D=&search%5Bcvss_score_from%5D=&search%5Bcvss_score_to%5D=&search%5Bcvss_av%5D=*&search%5Bcvss_ac%5D=*&search%5Bcvss_a%5D=*&search%5Bcvss_ci%5D=*&search%5Bcvss_ii%5D=*&search%5Bcvss_ai%5D=*&kthx=search");

	if ($mech->content =~ /href="(\/show\/osvdb\/\d[^"]+)"/i)
	{
		my $id = $1;
		$mech->get("http://osvdb.org/$id");

		if ($mech->content =~ /<li>Generic Exploit URL:.*<\/li>/smig)
		{
			push(@{ $source->{"osvdb"}{"links"} }, "http://osvdb.org/$id");
		} ## end if ($mech->content =~ ...)

	} ## end if ($mech->content =~ ...)
} ## end sub searchOSVDB

sub searchTelus
{

        print STDERR ">>> Contract negotiations FTL.  Check disabled!\n";
        setChecked("telus", "DISABLED");
        return;

	setChecked("telus", "Y");

	my $cve = shift;

	my $mech = mechInit("telus");

	# Dummy GET to perform login

	$mech->get("https://portal.telussecuritylabs.com/search/search_results?kw=1");

	# Submit login form

	$mech->submit_form(
		form_number => 1,
		fields      => {
			"user\[username\]"          => $telus_user,
			"user\[subscriber_number\]" => $telus_subn,
			"user\[password\]"          => $telus_pass
		}
	);

	$mech->get("https://portal.telussecuritylabs.com/search/search_results?kw=$cve");

	# the page above will have a link that matches this regex if the cve is found

	my @results = uniq( $mech->content =~ /<a href="\/(threat\/TSL\d+-\d+)">/msgi );

	for my $part ( @results )	
	{

		$mech->get("https://portal.telussecuritylabs.com/$part");

		# Find any actual exploitcode?

		if ($mech->content =~ /Vulnerability Proof of Concept/i)
		{
			$part =~ s/threat/asset/;

			push(@{ $source->{"telus"}{"links"} }, "https://portal.telussecuritylabs.com/$part/vulnerability_proof_of_concept/");
		} ## end if ($mech->content =~ ...)
	} ## end if ($mech->content =~ ...)
} ## end sub searchTelus

sub search1337Day
{
	setChecked("1337", "Y");

	my $cve  = shift;
	my $msid = cve2msid($cve);

	my $mech = mechInit("1337");
	my $id   = $cve;
	my @results;

	$mech->get("http://1337day.com/search/");
	$mech->submit_form(form_id => 0, fields => { dong => $cve });
	@results = $mech->content =~ /(\/exploits\/\d+[^'"]+)/smig;

	## Lookup by CVE failed, try it by MSID if we could look it up
	if (!@results && $msid)
	{
		$id = $msid;

		$mech->get("http://1337day.com/search/");
		$mech->submit_form(form_id => 0, fields => { dong => $msid });
		@results = $mech->content =~ /(\/exploits\/\d+[^'"]+)/smig;
	} ## end if (!@results && $msid...)
	else
	{
		print "\n";
	} ## end else [ if (!@results && $msid...)]

	if (@results)
	{
		foreach (@results)
		{
			push(@{ $source->{"1337"}{"links"} }, "http://1337day.com$_");
		} ## end foreach (@results)
	} ## end if (@results)
} ## end sub search1337Day

sub searchCANVAS
{
        setChecked("canvas", "Y");

        my $cve  = shift;
        my $msid = cve2msid($cve);
        my $cat  = $source->{canvas}->{catalog};

        ## Open the catalog and search for our MSID or CVE
        open(LIST, $cat) || setChecked("canvas", "ERROR") && warn "ERROR: $!: $cat\n"; # && setChecked("canvas", "ERROR") && return;
                my @list = <LIST>;
        close LIST;

	# get lines from catalog

        my @ret = grep { /($msid|$cve)/i } @list;

	foreach( @ret )
	{
		chomp;
	
		# Grab useful information from the lines
		if( $_ =~ /^\.\/(exploits\/[^:]+):.+(https?[^']+)/ )
		{
			my $modname 	= $1;
			my $url 	= $2;
				
			for( @{ $source->{canvas}{links} } )
			{
				# Hoping to instigate some rage
				goto final_bosses_use_goto if $_ =~ /\Q$modname\E/;
			}
				
	        	push(@{ $source->{canvas}{links} }, $modname ." - ". $url );

			final_bosses_use_goto:

		}

	}

        return;
} ## end sub searchCANVAS

## Convert CVE to MSID
sub cve2msid
{
	my $cve  = shift;
	my $mech = WWW::Mechanize->new();

	$mech->get("http://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-$cve");

	if ($mech->content =~ /MS:(MS\d{2}-\d{3,})/mi)
	{
		$msid = $1;
	} ## end if ($mech->content =~ ...)
	else
	{
		$msid = "FOOOOOOBAAAAAARR";
	} ## end else [ if ($mech->content =~ ...)]

} ## end sub cve2msid

sub printHeader
{
	my $cve = shift;
	if(!$csv) {
            print "[*] Searching CVE: $cve\n\n";
    	}
	return;
} ## end sub printHeader

sub printFooter
{
	my $cve  = shift;
	my $msid = shift;
	my $q    = "(";

	if ($msid)
	{
		my $msid2 = join "_", (split /-/, $msid);
		$q .= join " | ", "\"$cve\"", "\"$msid\"", "\"$msid2\"";
	} ## end if ($msid)
	else
	{
		$q .= "\"$cve\"";
	} ## end else [ if ($msid) ]

	$q .= $query;
	$q .= join " -site:", @filter;

	print "\n[*] Google Search: $q\n\n";
	print "-" x 50, "\n";
} ## end sub printFooter

sub templateOut($)
{
	my $cve = shift;
	my $notes;
	foreach my $k (sort @sources)
	{
		next if lc $k eq "all";

		if ($#{ $source->{$k}{"links"} } >= 0)
		{
            if($csv) {
                foreach my $link (@{ $source->{$k}{"links"} }) {
                    print $source->{$k}->{"csv_name"} . ",$link\n";
                }
		    }
			$notes .= $source->{$k}{"sname"} . ":\n";
			$notes .= "  " . join("\n  ", @{ $source->{$k}{"links"} }) . "\n\n";

		} ## end if ($#{ $source->{$k}{...}})
	} ## end foreach my $k (sort @sources...)

	if($csv) {
        exit;
    }

	my $template = <<EOS;

Research Checks:
Preexisting Coverage: ..................... Y/N
Evasion Cases: ............................ Y/N
Policy Modifications: ..................... Y/N

Public Source Checks:
EOS
	foreach my $k ( @sources )
	{
		next if lc $k eq "all";

		$template .= sprintf("%s: %s ", $source->{ $k }{ sname }, "." x ( 41 - length( $source->{ $k }{ sname } ) ) );

                if( $source->{ $k }{ checked } eq 'Y' ) {

                        if( scalar @{ $source->{ $k }{ "links" } } ) {
                                $template .= "Y\n";
                        } else {
                                $template .= "N\n";
                        }

                } elsif( $source->{ $k }{ checked } eq 'N' ) {

			$template .= "NOT CHECKED\n";

                } else {

			$template .= $source->{ $k }{ checked } . "\n";

                }

		# Clear out the links for the next source
		$source->{$k}{"links"} = undef;

	}

	$template .= <<EOS;
Google: ................................... Y/N
MU Dynamics: .............................. Y/N
BreakingPoint: ............................ Y/N


---------------------------------------------
Analyst Notes:

$notes

---------------------------------------------
New Rules:


---------------------------------------------
Modified Rules:


---------------------------------------------
Deleted Rules:


EOS

	print $template unless $write;
	print "-" x 45, "\n" unless $write;

	if ($write)
	{
		open CVE, ">$cve.vrt" || warn "ERROR: $!\n";
		print CVE $template;
		close CVE;

		print "WROTE TEMPLATE: $cve to $cve.vrt\n" if $verbose;
	} ## end if ($write)

} ## end sub templateOut($)

sub setChecked($$)
{
	my $k = shift;    # Type: ms, ps, telus, etc
	my $v = shift;    # Value: Y, N, ERROR
	$source->{$k}{checked} = $v;
} ## end sub setChecked($$)

sub syntaxExit
{

	my $opts = join "|", sort @sources;

	print "\nSyntax: $0 -p -v -w [-c <CVE> | -f <CVE File Path>] -t [$opts]\n\n";
	print "\t-c\t - CVE to search on (format: YYYY-NNNN): 2008-4250\n";
	print "\t-f\t - File containing CVEs (one per line. format: YYYY-NNNN)\n";
	print "\t-p\t - Print out a blank template and exit.\n";
	print "\t-v\t - Verbose\n";
	print "\t-y\t - Print CSV of links\n";
	print "\t-w\t - Write Template to CVE.vrt instead of STDOUT (ie - 2008-4250.vrt)\n";
	print "\t-i\t - Ignore sources.  (ie - -i ms,osvdb,telus)\n";
	print "\t-t\t - Search Type (Options below):\n\n";
	foreach my $k (sort @sources)
	{
		print "$k\t- $source->{$k}->{url}\n";
	} ## end foreach my $k (sort @sources...)

	print "\nBaseline Example (MS08-067): $0 -v -t all -c 2008-4250\n\n";

	exit(1);
} ## end sub syntaxExit



sub mechInit($)
{
	my $k = shift;
	my $mech = WWW::Mechanize->new(onerror => sub {setChecked($k, "ERROR");}, timeout => 10);
	return $mech;
} ## end sub mechInit($)

sub uniq
{
	return keys %{ { map { $_ => 1 } @_ } };
}

MAIN:
{
	## If $print is set, just print out a blank template
	if ($print == 1)
	{
		templateOut("YYYY-NNNN");
		exit(0);
	}

	if( $ARGV[0] =~ /^(\d{4}-\d{4})$/ )
	{
		$cve = $1;
		$type = ( $type ) ? $type : "all";

		goto cveonly;
	}

	# Unknown search source
	syntaxExit() unless exists $source->{ $type };

	if ($cve && $cve_file)
	{
		syntaxExit();
	} ## end if ($cve && $cve_file)

	$msid = cve2msid($cve);

	# make sure we have all necessary data

	if ($cve_file && $type)
	{
		open(my $infile, "<", $cve_file);

		@cves = <$infile>;

		close($infile);

		# GET ME SOME RESULTS GOD DAMNIT

		for my $cve (@cves)
		{
			chomp $cve;

			## Skip blank lines and comments
			next if ($cve =~ /^($|#)/);

			printHeader($cve);
			searchStart($cve, $type);

			## Uncomment when Google search is determined
			#printFooter($cve, $msid);

			templateOut($cve);
		} ## end for my $cve (@cves)

	} ## end if ($cve_file && $type...)
	elsif ($cve && $type)
	{
		cveonly:

		printHeader($cve);
		searchStart($cve, $type);

		## Uncomment when Google search is determined
		#printFooter($cve, $msid);

		templateOut($cve);
	} ## end elsif ($cve && $type)
	else
	{
		syntaxExit();
	} ## end else [ if ($cve_file && $type...)]

} ## end MAIN:

