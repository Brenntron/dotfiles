#!/usr/local/bin/perl -w
#
# Name: phoo.pl
# 
# Description: A rule parser to quickly help analyze rule files prior to commit.
# Read in a rule file, parse and display several components of the rule listed below:
#    NEEDS -->
#    Flow:
#    Metadata: (note if no policy, note if no service)
#    references: (CVE (required), bugtraq, url)
#    classtype:
#    sid not required, but if present needs to be displayed
#
# Output in the following order
#    connect
#    message
#    flow
#    detection block
#    metadata
#    references
#    classtype
# 
# Author: McLovin
#
use strict;
use Net::Snort::Parser::Rule;
use Net::Snort::Parser::File;
use Data::Dumper;

print "Parser version: " . $Net::Snort::Parser::Rule::VERSION . "\n";

my $dumprulestruct = 0;  # for debug output, dump the rule structure for the first rule and exit

my $file = "";
my $csv = 0;

if(defined($ARGV[0]) && $ARGV[0] ne "") {
   if($ARGV[0] eq "csv") {
      $csv = 1;
      if(defined($ARGV[1]) && $ARGV[1] ne "") {
         $file = $ARGV[1];
      }
   } elsif($ARGV[0] eq "struct") {
      $dumprulestruct = 1;
      if(defined($ARGV[1]) && $ARGV[1] ne "") {
         $file = $ARGV[1];
      }
   } else {
      $file = $ARGV[0];
      if(defined($ARGV[1]) && $ARGV[1] eq "csv") {
         $csv = 1;
      } elsif(defined($ARGV[1]) && $ARGV[1] eq "struct") {
         $dumprulestruct = 1;
      }
   }
}

if($file eq "") {
   $file = "in.rules";
}

my @VALID_VARS = qw( HOME_NET EXTERNAL_NET DNS_SERVERS SMTP_SERVERS HTTP_SERVERS SQL_SERVERS
                     TELNET_SERVERS SSH_SERVERS FTP_SERVERS SIP_SERVERS AIM_SERVERS HTTP_PORTS
                     SHELLCODE_PORTS ORACLE_PORTS SSH_PORTS FTP_PORTS SIP_PORTS FILE_DATA_PORTS );

my $version = 9999;
my $warning=0;
my $failure=0;
print "Checking Rule file $file\n\n";
my $parse = Net::Snort::Parser::Rule->new();
$parse->{'noautorev'} = 1;
my (@lines) = parse_file($file);

my @improvements;
my $updated_rule = "";

my @consolidatedalerts;
my @csvoutput;

my $line_num = 0;
foreach my $line (@lines){
   $line_num++;
   $line->{'line'} =~ s/^\s+//;
   $line->{'line'} =~ s/\s+$//;
   chomp($line->{'line'});
   next unless($line->{'line'});
#    print Dumper($line);
#    exit;
   print "*"x80 . "\n";
   process_line($line->{'line'}, $line_num);
}


if($csv == 0) {
   if(@consolidatedalerts > 0) {
      print STDERR "\n\nConsolidated alerts:\n";
      print STDERR @consolidatedalerts;
   }
} else {
   if(@csvoutput > 0) {
      print STDERR join("\n", @csvoutput) . "\n";
   }
}

if($failure){
   print "\n";
   print "*** THERE WERE FAILURES ***\n";
   print "*** THERE WERE FAILURES ***\n";
   print "*** THERE WERE FAILURES ***\n";
   print "\n";
   exit -1;
}
if($warning){
   exit 1;
}
exit 0; # all good

sub process_line {
#    my ($line->{'line'}, $line_num) = @_;
   my $line = $_[0];
   my $line_num = $_[1];
   my $rule = $parse->parse_rule($line);

   if($dumprulestruct == 1) {
      print Dumper($rule);
      exit;
   }

   my (@failed,@warnings,$servicemetadata,$balancedpolicy);

   @improvements = ();

   # if line does not contain a rule (comment, blank, etc)
   if(!$rule){
      print "$line_num: $line\n";
      return;
   }
   
   # if line contains a failed rule
   if($rule->{'failed'}){
      print "$line_num: FAILED - $rule->{failed}\n   $line\n";
      push(@consolidatedalerts, "FAIL ($line_num): .#.#.# > RULE FAILED NET::SNORT::PARSE PARSING\n");
      push(@csvoutput, "error,Rule failed parser library");
      $failure++;
      return;
   }

   # Verify variables in connection information
   my ($src_net, $src_port, $dst_net, $dst_port) = $line =~ /^\s*#?\s*alert\s+[^\s]+\s+([^\s]+)\s+([^\s]+)\s*->\s*([^\s]+)\s+([^\s]+)/;
   #print "$src_net, $src_port, $dst_net, $dst_port\n";
   foreach my $connvar ($src_net, $src_port, $dst_net, $dst_port) {
      if($connvar =~ /^\$/) {
         $connvar =~ s/^\$//;
         if(!grep(/^$connvar$/, @VALID_VARS)) {
            $failure++;
            push(@failed, "INVALID VARIABLE - $connvar");
         }
      } else {
         # If not a variable, at least look somewhat like something valid
         # This could be more robust.  It seems snort rule parser library
         # doesn't validate this format so it seems this issue is deeper
         # than just "library doesn't validate variable names because it
         # has no way of knowing what's valid and what isn't." 
         if(!($connvar =~ /^any$/) && !($connvar =~ /^[\d,\[\]\.!:]+$/)) {
            $failure++;
            push(@failed, "INVALID CONNECTION INFO - $connvar");
         }
      }
   }   

   # Potential improvements to the rule
   find_fast_pattern_only($rule);

   # ZDNOTE : Just slapping this in here for now
   if($line =~ /\$(HTTP|FILE_DATA)_PORTS\s*->.*flow\s*:\s*(established\s*,\s*)?(to_client|from_server)/) {
      if(!($line =~ /file_data/)) {
         push(@warnings, 'HTTP or FILE_DATA_PORTS to_client and no file_data keyword');
      }
      if($line =~ /\$HTTP_PORTS/) {
         push(@warnings, 'HTTP_PORTS is used -- is FILE_DATA_PORTS more appropriate?');
      }
      if($line =~ /\$FILE_DATA_PORTS/) {
         if(!($line =~ /metadata[^;]*service\s+http/) ||
            !($line =~ /metadata[^;]*service\s+pop3/) ||
            !($line =~ /metadata[^;]*service\s+imap/) ||
            !($line =~ /metadata[^;]*service\s+ftp-data/)) {
               $failure++;
               push(@failed, 'FILE_DATA_PORTS should have service for http, pop3, imap, and ftp-data');
         }
      }
   }

   # No from_client or from_server... Should only do to_server and to_client
   if($line =~ /flow\s*:\s*(established\s*,\s*)?from_(server|client)/) {
      $failure++;
      push(@failed, 'from_client and from_server is against standards, use to_server and to_client');
   }

   if(($line =~ /\$SMTP_SERVERS/) || ($line =~ /msg\s*:\s*"\s*SMTP/) || ($line =~ /->\s*[^\s]+\s+25\s*\(/) || ($line =~ /tcp\s+[^\s]+25\s*->/)) {
      if(!($line =~ /metadata[^;]*service\s+smtp/)) {
         $failure++;
         push(@failed, 'SMTP rules should have service smtp');
      }
   }

   if(($line =~ /->\s*[^\s]+\s+25\s*\(/) && !($line =~ /to_server/)) {
      $failure++;
      push(@failed, 'Connection information points to SMTP port but detection is not to_server');
   }

   if($line =~ /[\s;]base64_(decode|data)/) {
      if($line =~ /metadata\s*:[^;]*policy/) {
         push(@warnings, 'Base64 rule options are very slow, rule should not be in any policies');
      }

      if($line =~ /[\s;]base64_decode\s*;/) {
         push(@failed, 'RULES COMMIT PROCESS HAS BUG THAT REMOVES base64_decode WITHOUT relative OPTION');
         push(@failed, "IT IS UNLIKELY YOU ACTUALLY WANT base64_decode WITHOUT relative\n%\t\tdoing so starts at the start of the payload");
      }
   }

   if($line =~ /[\s;]metadata\s*:.*[\s;]metadata\s*:/) {
      $failure++;
      push(@failed, "Multiple instances of metadata in the same rule");
   }

   if($line =~ /[\s;]fast_pattern\s*;/) {
      if(!($line =~ /content.*content/)) {
         $failure++;
         push(@failed, "SERIOUSLY? YOU HAVE fast_pattern; (NOT :only) WITH ONLY ONE CONTENT MATCH!");
      } else {
         push(@warnings, "fast_pattern (not :only) specified.  Is it really needed?");
      }
   }

   # flowbits:noalert should not be in any policies
   if($line =~ /flowbits\s*:\s*noalert\s*;/) {
      if(defined($rule->{'metadata'}->{'policy'}) && %{$rule->{'metadata'}->{'policy'}}) {  # 0 if hash is empty
         $failure++;
         push(@failed, "Rules with flowbits:noalert must not be in any policies");
      }
   }

   # else we're a rule, lets get the info patrick needs
   my $r = $rule;
   # Connection
   print "Connection: $r->{action} $r->{protocol} $r->{src} $r->{srcport} $r->{direction} $r->{dst} $r->{dstport}\n";

   # Message
   print "Message   : $r->{name}\n";

   # Verifications of rule message
   my $validmsgchars = ' a-zA-Z0-9\+\/_\.\?=&\-';
   if($r->{name} =~ /([^$validmsgchars]|--)/) {
      push(@failed, "Invalid character found in rule message.  Valid characters are: [$validmsgchars] but no '--'");
   }
   if(!($r->{name} =~ /attempt/)) {
      push(@warnings, "Should the rule message have the word \"attempt\"?") unless ($r->{name} =~ /^(BOTNET-CNC|BLACKLIST|MALWARE-BACKDOOR|MALWARE-CNC|MALWARE-OTHER|MALWARE-TOOLS) /);
   }

   # Category list generated 18-JUN-2013
   my @rulecategories = qw(APP-DETECT ATTACK-RESPONSES BACKDOOR BAD-TRAFFIC BLACKLIST BOTNET-CNC BROWSER-CHROME BROWSER-FIREFOX BROWSER-IE BROWSER-OTHER BROWSER-PLUGINS BROWSER-WEBKIT CHAT CONTENT-REPLACE DDOS DELETED DNS DOS EXPERIMENTAL EXPLOIT-KIT EXPLOIT FILE-EXECUTABLE FILE-FLASH FILE-IDENTIFY FILE-IMAGE FILE-JAVA FILE-MULTIMEDIA FILE-OFFICE FILE-OTHER FILE-PDF FINGER FTP ICMP-INFO ICMP IMAP INDICATOR-COMPROMISE INDICATOR-OBFUSCATION INDICATOR-SCAN INDICATOR-SHELLCODE INFO LOCAL MALWARE-BACKDOOR MALWARE-CNC MALWARE-OTHER MALWARE-TOOLS MISC MULTIMEDIA MYSQL NETBIOS NNTP ORACLE OS-LINUX OS-MOBILE OS-OTHER OS-SOLARIS OS-WINDOWS OTHER-IDS P2P PHISHING-SPAM POLICY-MULTIMEDIA POLICY-OTHER POLICY POLICY-SOCIAL POLICY-SPAM POP2 POP3 PROTOCOL-DNS PROTOCOL-FINGER PROTOCOL-FTP PROTOCOL-ICMP PROTOCOL-IMAP PROTOCOL-NNTP PROTOCOL-POP PROTOCOL-RPC PROTOCOL-SCADA PROTOCOL-SERVICES PROTOCOL-SNMP PROTOCOL-TELNET PROTOCOL-TFTP PROTOCOL-VOIP PUA-ADWARE PUA-OTHER PUA-P2P PUA-TOOLBARS RPC RSERVICES SCADA SCAN SERVER-APACHE SERVER-IIS SERVER-MAIL SERVER-MSSQL SERVER-MYSQL SERVER-ORACLE SERVER-OTHER SERVER-SAMBA SERVER-WEBAPP SHELLCODE SMTP SNMP SPECIFIC-THREATS SPYWARE-PUT SQL TELNET TFTP VIRUS VOIP WEB-ACTIVEX WEB-ATTACKS WEB-CGI WEB-CLIENT WEB-COLDFUSION WEB-FRONTPAGE WEB-IIS WEB-MISC WEB-PHP X11);

   # Extra VOIP stuff that is handled in textrules-commit.pl
   push(@rulecategories, qw(VOIP-SIP-TCP VOIP-SIP-UDP VOIP-SKINNY-TCP VOIP-SDP-TCP VOIP-SDP-UDP));

   my ($category) = $r->{name} =~ /^([^\s]+)\s/;

   my $categorypcre = "^(" . join('|', @rulecategories). ") ";

   if(!($r->{name} =~ /$categorypcre/)) {
      $failure++;
      push @failed, "Rule category $category not valid";
   }

   # Categories that are deprecated - updated 2012-10-31
#   if($r->{name} =~ /^(BACKDOOR|BOTNET-CNC|POLICY|WEB-ISS|WEB-CLIENT|EXPLOIT|SPECIFIC-THREATS) /) {
   if($r->{name} =~ /^(ATTACK-RESPONSES|BACKDOOR|BAD-TRAFFIC|BOTNET-CNC|CHAT|DDOS|EXPERIMENTAL|FINGER|FTP|ICMP|IMAP|INFO|LOCAL|MISC|MULTIMEDIA|MYSQL|ORACLE|OTHER-IDS|P2P|PHISHING-SPAM|POLICY|POP2|POP3|RSERVICES|SHELLCODE|SMTP|VIRUS|VOIP|WEB-ACTIVEX|WEB-ATTACKS|WEB-CGI|WEB-COLDFUSION|WEB-IIS|WEB-MISC|WEB-PHP|SPECIFIC-THREATS|EXPLOIT|WEB-CLIENT|SPYWARE-PUT) /) {
      $failure++;
      push @failed, "Rule category $category is deprecated";
   }

#   # Categories that shouldn't be used - These are now deprecated
#   if($r->{name} =~ /^(SPECIFIC-THREATS|WEB-CLIENT) /) {
#      push(@warnings, "RULE CATEGORY $category should be avoided");
#   }
   
   # Category-specific checks
   if($r->{name} =~ /^(BOTNET-CNC|BLACKLIST|MALWARE-BACKDOOR|MALWARE-CNC|MALWARE-OTHER|MALWARE-TOOLS) /) {
      if(!$r->{metadata}{impact_flag}) {
         push @warnings, "$category rules should have metadata:impact_flag red";
      }
   }

   if($r->{name} =~ /^SMTP/) {
      if($line =~ /flow\s*:\s*(established\s*,\s*)?to_server/) {
         if(!(get_option($r, 'file_data'))) {
            push(@warnings, 'SMTP and no file_data keyword - needed for detection within attachments');
         }
      }
   }
   
   # Flow
   my $flow = get_option($r, 'flow');
   if( $flow && $flow >=0 ){
      $flow = $r->{options}{$flow}{original};
   } else {
      my $proto = get_option($r, 'protocol');
      if( $proto && $proto eq 'tcp') {
         $failure++;
         push @failed, 'FLOW';
      } else {
         push(@warnings, 'FLOW');
      }
      $flow = '<MISSING>';
   }
   print "Flow      : $flow\n";

   # Detection: awful I know
   print "Detection :\n"; # Newline will be within $detection below
   my $detection = $line;
   # $detection =~ /msg:\"(.*?)\";(.*)/;
   # $detection = $2;
   # $detection =~ /(.*?)(reference:|metadata:).*?;/;
   # $detection = $1;
   # a little more robust than previous...
   $detection =~ s/alert(.*?)\((.*)\)/$2/;

   foreach my $strippershoes (qw(reference metadata msg flow classtype sid rev)) {
      $detection =~ s/(^|[\s;])$strippershoes:(.*?);//g;
   }
 
   $detection =~ s/^\s+//;
   $detection =~ s/\s+$//;

   # split detection into separate rule option lines.  Current as of snort 2.9.3.5
   foreach my $ruleoption (qw(content rawbytes uricontent urilen isdataat pcre file_data base64_decode base64_data byte_test byte_jump byte_extract ftpbounce asn1 cvs dce_iface dce_opnum dce_stub_data ssl_version ssl_state fragoffset ttl tos id ipopts fragbits dsize flags flowbits seq ack window itype icode icmp_id icmp_seq rpc ip_proto sameip stream_reassemble stream_size logto session resp react tag activates activated_by count replace detection_filter sip_header sip_body threshold uri_data raw_uri_data header_data raw_header_data method_data cookie_data raw_cookie_data stat_code_data stat_msg_data http_encode pkt_data sip_stat_code gtp_type gtp_info)) {
      $detection =~ s/[\s;]$ruleoption([:;])/\n\t$ruleoption$1/g;
   }

   print "\t$detection\n";

   # Find some common mistakes
   # pcre: using a pipe in a character class
   if($detection =~ /pcre\s*:\s*"[^"]*\[[^\]]*\|/) {
     push(@warnings, "Pipe found in character class - are you sure you want this?  [a|b] is not correct; [ab] is.");
   }

   # pcre: missing backslash for hex chars
   # "exec" in the pcre gives us a false positive, so strip that out
   my ($pcre) = $detection =~ m/pcre\s*:([^;]*);/;
   if(defined $pcre) {
      $pcre =~ s/exec//gi;
      if($pcre =~ /[^\\]x[0-9a-f]{2}/i) {
         push(@warnings, "Missing backslash for hex char in pcre? /x[0-9a-f]{2}/ detected");
      }
      if($pcre =~ /\\[0-9a-f]{2}/i) {
         push(@warnings, "Missing 'x' for hex char in pcre? /\\\\[0-9a-f]{2}/ detected");
      }
   }

   # Here's a nice place to put errors for using rule options that shouldn't be used
   if(get_option($r, 'threshold')){
      push(@failed, 'Threshold is deprecated -- replace with detection_filter');
   }

   # Metadata:
   # Removed warnings for missing metadata components because it seems that metadata is the exception
   # rather than the norm now.
#print Dumper($r->{metadata});
   print "Metadata  :";
   if( $r->{metadata} ){
      if( $r->{metadata}{policy} ){
         print "\n\tPolicy: " . join(', ', keys %{$r->{metadata}{policy}}) . "\n";
         if( join(', ', keys %{$r->{metadata}{policy}}) =~ m/balanced-ips/) {
            $balancedpolicy = 1;
         }
      } else {
#         push(@warnings, "METADATA Policy");
         print "\n\tPolicy: <MISSING>\n";
      }   
      if( $r->{metadata}{service}){
         print "\tService: " . join(', ', keys %{$r->{metadata}{service}}) . "\n";
         $servicemetadata = 1;
      } else {
#         push(@warnings, "METADATA Service");
         print "\tService: <MISSING>\n";
      }
      if($r->{metadata}{impact_flag}) {
         print "\tImpact Flag: " . join(', ', keys %{$r->{metadata}{impact_flag}}) . "\n";
      }
      if($r->{metadata}{ruleset}) {
         print "\tRuleset: " . join(', ', keys %{$r->{metadata}{ruleset}}) . "\n";
      }
   } else {
#      push(@warnings, "METADATA");
      print " <MISSING>\n";
   }
   
   # References:
   print "References:";
   if(!$r->{references}){
      push(@warnings, 'No references');
      push(@warnings, 'No CVE reference');
      print " <MISSING>\n";
   } else {
      if( $r->{references}{cve} ){
         #print "\tCVE:\n\t\t" . join("\n\t\t", keys %{$r->{references}{cve}}) . "\n";
         print "\n\tCVE:     " . join(", ", keys %{$r->{references}{cve}}) . "\n";
      } else {
         push(@warnings, 'No CVE reference');
         print "\n\tCVE:     <MISSING>\n";
      }
      if( $r->{references}{bugtraq} ){
         #print "\tBUGTRAQ:\n\t\t" . join("\n\t\t", keys %{$r->{references}{bugtraq}}) . "\n";
         print "\tBUGTRAQ: " . join(", ", keys %{$r->{references}{bugtraq}}) . "\n";
      } else {
         print "\tBUGTRAQ: <MISSING>\n";
      }      
      if( $r->{references}{url} ){
         #print "\tURL:\n\t\t" . join("\n\t\t", keys %{$r->{references}{url}}) . "\n";
         print "\tURL:     " . join(", ", keys %{$r->{references}{url}}) . "\n";
         foreach my $key (keys %{$r->{references}{url}}) {
            if($key =~ /microsoft\.com.*ms..-.{1,3}/i) { # Looks vaguely like an MS Bulletin reference
               if(#!($key =~ /www\.microsoft\.com\/technet\/security\/bulletin\/(MS|ms)[0-9]{2}-[0-9]{3}.mspx($|\s)/) && # Old form no longer supported
                  !($key =~ /technet\.microsoft\.com\/en-us\/security\/bulletin\/(MS|ms)[0-9]{2}-[0-9]{3}($|\s)/) &&
                  !($key =~ /technet\.microsoft\.com\/en-us\/security\/advisory\/[0-9]+($|\s)/)) {
                  if($key =~ /technet\.microsoft\.com\/en-us\/security\/bulletin\/(MS|ms)[0-9]{2}-XXX($|\s)/i) {
                     push(@warnings, 'MICROSOFT DUMMY BULLETIN REFERENCE IN USE');
                  } else {
                     push(@failed, 'Reference: Improperly formatted Microsoft reference');
                  }
               }
            } elsif($key =~ /osvdb\.org/) {
               if(!($key =~ /osvdb\.org\/show\/osvdb\/\d+($|\s)/)) {
                  push(@failed, 'Reference: Improperly formatted OSVDB reference');
               }
            }
         }
      } else {
         print "\tURL:     <MISSING>\n";
      }
   }
   
   # Classtype:
   print "Classtype : ";
   if(!$r->{classification}){
      # If the classtype were missing however, the rule parser would have not returned a parsed rule
      # and we would have died long ago.  Like the dinosaurs.
      push(@failed, 'CLASSTYPE');
      print "<MISSING>\n";
   } else {
      print "$r->{classification}\n";
   }
   
   # SID:
   print "Sid       : ";
   if(!$r->{sid}){
      print "<MISSING>\n";
   } else {
      print "$r->{sid}\n";
   }

   # REV:
   print "Rev       : ";
   if(!$r->{revision}){
      print "<MISSING>\n";
   } else {
      print "$r->{revision}\n";
   }
   # print "Original: $line\n";

# Service metadata is now required for all rules and is independent of policies
#   if($balancedpolicy && !$servicemetadata) {
#      $failure++;
#      push(@failed, 'POLICY rule is in balanced-ips with no service metadata');
#   }
#   if(!$balancedpolicy && $servicemetadata) {
#      $failure++;
#      push(@failed, 'POLICY rule has service metadata but is not in balanced-ips');
#   }
   if(!$servicemetadata) {
      # $failure++; # No longer a failure
      push(@warnings, 'Rule has no service metadata');
   }


   if( @failed || @warnings || @improvements ){
      print "\n" . "%"x80 . "\n";
      if(@failed){
         $failure++;
         print "% FAILURE - Rule failed due to the following missing requirements\n";
         print "%\t" . join("\n%\t", @failed) . "\n";
         print "%"x80 . "\n";
         foreach my $alert (@failed) {
            push(@consolidatedalerts, "FAIL ($line_num): $alert\n");
            push(@csvoutput, "error,$line_num,$alert");
         }
      }
      if(@warnings){
         $warning++;
         print "% WARNING - Rule is missing the following components\n";
         print "%\t" . join("\n%\t", @warnings) . "\n";
         print "%"x80 . "\n";
         foreach my $alert (@warnings) {
            push(@consolidatedalerts, "WARN ($line_num): $alert\n");
            push(@csvoutput, "warning,$line_num,$alert");
         }
      }
      if(@improvements) {
         print "% RECOMMENDATIONS - Rule has the following recommended changes\n";
         print "%\t" . join("\n%\t", @improvements) . "\n";
         print "%"x80 . "\n";
         foreach my $alert (@improvements) {
            push(@consolidatedalerts, "IMPR ($line_num): $alert\n");
            push(@csvoutput, "suggestion,$line_num,$alert");
         }
#      print "\n\n$updated_rule\n";
      }
   }

   #print Dumper($rule);
}

# Return the option index of the option keywork requested
sub get_option {
   my ($r,$type) = @_;
   foreach my $opt (keys %{$r->{options}}){
      if( $r->{options}{$opt}{type} eq $type ){
         return $opt;
      }
   }
   return;  
}




sub find_fast_pattern_only {
   my ($rule) = @_;

   my $fast_pattern_only_candidate;
   my $fast_pattern_length;
   my $content_length;

   # if our rule already has a fast_pattern, go right to it.
   # Otherwise, find the first longest content match
   if( $rule->{'_fast_pattern'}) {

      foreach my $option (sort {$a<=>$b} keys %{ $rule->{'options'} } ) {
         next unless (defined $rule->{'options'}{$option}->{'fast_pattern'});
         $fast_pattern_only_candidate = $option;
         #last;
         # Since we already have fast_pattern:only, just return
         return;
      }
   } else {
      # Find the first longest content match
      $fast_pattern_only_candidate = -1;
      $fast_pattern_length = 0;

      foreach my $option (sort {$a<=>$b} keys %{ $rule->{'options'} } ) {
         next unless ($rule->{'options'}{$option}->{'type'} eq 'content');
         $content_length = length($rule->{'options'}{$option}->{'string'});
         if($content_length > $fast_pattern_length) {
            $fast_pattern_length = $content_length;
            $fast_pattern_only_candidate = $option;
         }
      }
   }

   # No content match option in the rule, so just print it out
   if($fast_pattern_only_candidate == -1) {
#      print $parse->build_rule($rule)."\n";
      return;#next;
   }

   # Check to see if we can add fast_pattern:only, print appropriately
   if(is_valid_candidate($rule, $fast_pattern_only_candidate)) {
      # Add fast_pattern_only (overwrite fast_pattern if present)
      $rule->{'options'}{$fast_pattern_only_candidate}->{'fast_pattern'} = 'only';
      delete $rule->{'options'}{$fast_pattern_only_candidate}->{'nocase'};
      $updated_rule = $parse->build_rule($rule);
      push(@improvements, "fast_pattern:only");
   }# else {
   #   $updated_rule = $parse->build_rule($rule)."\n";
   #}
}

sub is_valid_candidate {
   my ($rule,$opt) = @_;

   #print Dumper($rule)."\n";

   # Make sure we're not negated
   return 0 if ($rule->{'options'}{$opt}->{'not'});

   # See if we're relative or case-sensitive
   return 0 if ($rule->{'options'}{$opt}->{'relative'});
   return 0 if ($rule->{'options'}{$opt}->{'depth'});
   return 0 if ($rule->{'options'}{$opt}->{'offset'});

   # See if we're a valid buffer
   return 0 unless ( !defined $rule->{'options'}{$opt}->{'location'} ||
                     $rule->{'options'}{$opt}->{'location'} eq 'normal' ||
                     $rule->{'options'}{$opt}->{'location'} eq 'http_uri' ||
                     $rule->{'options'}{$opt}->{'location'} eq 'http_header' ||
                     $rule->{'options'}{$opt}->{'location'} eq 'http_post' #||
#                     $rule->{'options'}{$opt}->{'location'} eq 'http_method'
   );

   # We're going to be a little extra clever here.
   # If nocase is set, we're good.  But if nocase is not
   # set, we're going to check to see if there are any
   # alphabetic characters.  If not, then case doesn't
   # matter so we'll still accept the content match
   # Also, if the content is longer than 10 bytes we're going
   # to say that case probably doesn't matter even if there are
   # alphabetic characters because generally this is true
   if(!exists $rule->{'options'}{$opt}->{'nocase'}) {
      return 0 if (($rule->{'options'}{$opt}->{'string'} =~ /[A-Za-z]/) && 
                   (length($rule->{'options'}{$opt}->{'string'}) < 10));
   }

   # Now check to see if the next option is relative to us
   my $nextopt = $opt + 1;

   return 1 if (!exists $rule->{'options'}{$nextopt});

   if($rule->{'options'}{$nextopt}->{'type'} eq 'content') {
      return 0 if ($rule->{'options'}{$nextopt}->{'relative'});
      return 0 if ($rule->{'options'}{$nextopt}->{'depth'});
   } elsif($rule->{'options'}{$nextopt}->{'type'} eq 'pcre') {
      return 0 if ($rule->{'options'}{$nextopt}->{'args'} =~ /\/[^\/]*R[^\/]*"$/);
   } elsif(defined($rule->{'options'}{$nextopt}->{'args'}) && $rule->{'options'}{$nextopt}->{'args'} =~ /relative/) {
      return 0;
   }

#     elsif($rule->{'options'}{$nextopt}->{'type'} eq 'byte_test') {
#      return 0 if ($rule->{'options'}{$nextopt}->{'args'} =~ /relative/);
#   } elsif($rule->{'options'}{$nextopt}->{'type'} eq 'byte_jump') {
#      return 0 if ($rule->{'options'}{$nextopt}->{'args'} =~ /relative/);
#   } elsif($rule->{'options'}{$nextopt}->{'type'} eq 'isdataat') {
#      return 0 if ($rule->{'options'}{$nextopt}->{'args'} =~ /relative/);
#   } elsif($rule->{'options'}{$nextopt}->{'type'} eq 'byte_extract') {
#      return 0 if ($rule->{'options'}{$nextopt}->{'args'} =~ /relative/);
#   }

   return(1);
}



