# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)


ReferenceType.create(:name => 'cve',:description => 'Common Vulnerabilities and Exposures',:validation => '^(19|20)\d{2}-\d{4}$',:bugzilla_format => 'cve-((19|20)\d{2}-\d{4})',:example => '1999-1234',:rule_format => 'cve,<reference>',:url => 'http://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-DATA')
ReferenceType.create(:name => 'bugtraq',:description => 'Bugtraq - SecurityFocus',:validation => '^\d{1,10}$',:example => '12345',:rule_format => 'bugtraq,<reference>',:url => 'http://www.securityfocus.com/bid/DATA')
ReferenceType.create(:name => 'osvdb',:description => 'The Open Source Vulnerability Database',:validation => '^\d{1,10}$',:example => '12345',:rule_format => 'osvdb,<reference>',:url => 'http://www.osvdb.org/DATA')
ReferenceType.create(:name => 'msb',:description => 'Microsoft Security Bulletin',:validation => '^MS\d{2}-\d{3}$',:bugzilla_format => '(MS\d{2}-\d{3})',:example => 'MS08-067',:rule_format => 'url,technet.microsoft.com/en-us/security/bulletin/<reference>',:url => 'http://technet.microsoft.com/en-us/security/bulletin/DATA')
ReferenceType.create(:name => 'url',:description => 'Generic URL for vulnerability information',:validation => '^(?!http|ftp).*',:example => 'www.somesite.com/whatever/whocares',:rule_format => 'url,<reference>',:url => 'http://DATA')
ReferenceType.create(:name => 'telus',:description => 'Telus bug report information',:bugzilla_format => '((FSC|TSL)\d{8}-\d{2})',:example => 'FSC20111103-05',:rule_format => '<reference>',:url => 'https://portal.telussecuritylabs.com/threat/DATA')
ReferenceType.create(:name => 'apsb',:description => 'Adobe Product Security Bulletin',:validation => '^APSB\d{2}-\d{2}$',:bugzilla_format => '(APSB\d{2}-\d{2})',:example => 'APSB13-03',:rule_format => 'url,www.adobe.com/support/security/bulletins/<reference>.html',:url => 'url,www.adobe.com/support/security/bulletins/DATA.html')

ExploitType.create(:name => 'core',:description => 'Core Impact exploit module.',:pcap_validation => '^((19|20)\d{2}-\d{4}$|none)-(\d+|none)-((ms\d{2}-\d{3}-)?)-core-\d+-\d+\.pcap')
ExploitType.create(:name => 'metasploit',:description => 'Metasploit exploit module.',:pcap_validation => '^((19|20)\d{2}-\d{4}$|none)-(\d+|none)-((ms\d{2}-\d{3}-)?)-metasploit-\d+-\d+\.pcap')
ExploitType.create(:name => 'canvas',:description => 'Immunity Canvas exploit module.',:pcap_validation => '^((19|20)\d{2}-\d{4}$|none)-(\d+|none)-((ms\d{2}-\d{3}-)?)-canvas-\d+-\d+\.pcap')
ExploitType.create(:name => 'other',:description => 'Other publicly available exploit module.',:pcap_validation => '^((19|20)\d{2}-\d{4}$|none)-(\d+|none)-((ms\d{2}-\d{3}-)?)-other-\d+-\d+\.pcap')
ExploitType.create(:name => 'telus',:description => 'Other publicly available exploit module.',:pcap_validation => '^((FSC|TSL)\d{8}-\d{2})-.*?attack-*?\.pcap$')
ExploitType.create(:name => 'expldb',:description => 'Other publicly available exploit module.',:pcap_validation => '^((19|20)\d{2}-\d{4}$|none)-(\d+|none)-((ms\d{2}-\d{3}-)?)-expldb-\d+-\d+\.pcap')


# Reference.create(reference_data:"12345",reference_type: ref2)
# Reference.create(reference_data:"cve,1936-7254",reference_type: ref1)
#
# r1 = Rule.create(gid:'1',sid:'3679',rev:'12',message:'INDICATOR-OBFUSCATION Multiple Products IFRAME src javascript code execution',rule_content:'alert tcp $EXTERNAL_NET $HTTP_PORTS -> $HOME_NET any (msg:"INDICATOR-OBFUSCATION Multiple Products IFRAME src javascript code execution"; flow:to_client,established; file_data; content:"IFRAME"; nocase; pcre:"/\x3c\s*IFRAME\s*[^\x3e]*src=\x22javascript\x3a/smi"; metadata:service http; reference:bugtraq,13544; reference:bugtraq,30560; reference:cve,2005-1476; reference:cve,2008-2939; reference:nessus,18243; classtype:attempted-user; sid:3679; rev:12;)', state:'unchanged',average_check: '29.0',average_match:'73.1',average_nonmatch:'24,9',tested:'false', committed:true,)
# r2 = Rule.create(gid:'1',sid:'13990',rev:'17',message:'SQL union select - possible sql injection attempt - GET parameter',rule_content:'alert tcp $EXTERNAL_NET any -> $HOME_NET $HTTP_PORTS (msg:"SQL union select - possible sql injection attempt - GET parameter"; flow:to_server,established; content:"union"; fast_pattern; nocase; http_uri; content:"select"; nocase; http_uri; pcre:"/union\s+(all\s+)?select\s+/Ui"; metadata:policy security-ips drop, service http; reference:bugtraq,21227; reference:cve,2006-6268; reference:cve,2007-1021; reference:cve,2007-2824; reference:cve,2011-1667; reference:url,www.securityfocus.com/archive/1/452259; classtype:misc-attack; sid:13990; rev:17;)',state:'unchanged',average_check: '8.3',average_match:'24.9',average_nonmatch:'0.0',tested:'false', committed:true,)
# r3 = Rule.create(gid:'1',sid:'19439',rev:'8',message:'SQL 1 = 1 - possible sql injection attempt',rule_content:'alert tcp $EXTERNAL_NET any -> $HOME_NET $HTTP_PORTS (msg:"SQL 1 = 1 - possible sql injection attempt"; flow:to_server,established; content:"1=1"; fast_pattern:only; http_uri; pcre:"/(and|or)[\s\x2f\x2A]+1=1/Ui"; metadata:policy balanced-ips drop, policy security-ips drop, service http; reference:url,ferruh.mavituna.com/sql-injection-cheatsheet-oku/; classtype:web-application-attack; sid:19439; rev:8;)',state:'unchanged',average_check:'1.4',average_match:'4.7',average_nonmatch:'0.1',tested:'false', committed:true)
# r4 = Rule.create(gid:'1',sid:'24172',rev:'1',message:'SQL use of concat function with select - likely SQL injection',rule_content:'alert tcp $EXTERNAL_NET any -> $HOME_NET $HTTP_PORTS (msg:"SQL use of concat function with select - likely SQL injection"; flow:to_server,established; content:"SELECT "; nocase; http_uri; content:"CONCAT|28|"; within:100; nocase; http_uri; metadata:policy security-ips drop, service http; reference:url,ferruh.mavituna.com/sql-injection-cheatsheet-oku/; classtype:web-application-attack; sid:24172; rev:1;)',state:'unchanged',average_check:'0.1',average_match:'0.0',average_nonmatch:'0.1',tested:'false', committed:true,)
# r5 = Rule.create(gid:'1',sid:'17129',rev:'18',message:'BROWSER-IE Microsoft Internet Explorer use-after-free memory corruption attempt',rule_content:'alert tcp $EXTERNAL_NET $HTTP_PORTS -> $HOME_NET any (msg:"BROWSER-IE Microsoft Internet Explorer use-after-free memory corruption attempt"; flow:to_client,established; file_data; content:"<script>"; nocase; content:"function"; distance:0; nocase; content:"()"; within:30; content:"location."; fast_pattern:only; pcre:"/function\s+?\w+\s*?\x28[^\x7b]+?\x7b[^\x7d]*?location\.(protocol|href)\s*?=\s*?[\x22\x27]\s*?(mailto|http|file).*?[\x22\x27]/smi"; metadata:service http; reference:bugtraq,42257; reference:cve,2010-2556; reference:url,osvdb.org/show/osvdb/66999; reference:url,technet.microsoft.com/en-us/security/bulletin/ms10-053; classtype:attempted-dos; sid:17129; rev:18;)',state:'updated',average_check:'11.8',average_match:'0.0',average_nonmatch:'7.4',tested:'false', committed:false)
# r6 = Rule.create(gid:'1',sid:'30040',rev:'2',message:'SQL 1 = 1 - possible sql injection attempt',rule_content:'alert tcp $EXTERNAL_NET any -> $HOME_NET $HTTP_PORTS (msg:"SQL 1 = 1 - possible sql injection attempt"; flow:to_server,established; content:"1%3D1"; fast_pattern:only; http_client_body; pcre:"/or\++1%3D1/Pi"; metadata:policy balanced-ips drop, policy security-ips drop, service http; reference:url,ferruh.mavituna.com/sql-injection-cheatsheet-oku/; classtype:web-application-attack; sid:30040; rev:2;)',state:'new',average_check:'3.6',average_match:'0.0',average_nonmatch:'0.0',tested:'false', committed:false)
#
# # parse rule content
# rules = [r1, r2, r3, r4, r5, r6]
# rules.each do |r|
#   rule = r.rule_content
#   r.connection = /(.*?)\(/.match(rule)[1].strip
#   r.message = /msg:"(.*?)";/.match(rule)[1].strip
#   r.flow = /flow:(.*?);/.match(rule)[1].strip
#   r.detection = /flow:.*?;(.*?)metadata:/.match(rule)[1].strip
#   r.metadata = /metadata:(.*?);/.match(rule)[1].strip
#   r.class_type = /classtype:*(.*?);/.match(rule)[1].strip
#   r.save
# end
#
# Exploit.create(name:"exploit abc123",description:"this is an exploit that everything has",pcap_validation:"?? dont know....",data:"blah blah blah data goes here. lots of data im not sure how much data but i would imagine lots would need to be here. I could talk all day about data but i wont because there are other things to do.")
#
# b1 = Bug.create(bugzilla_id:'116261',state:'PENDING',status:'RESOLVED',resolution:'PENDING',summary:'[TELUS][VULN][SID] 25849-25852,26392,29504 [BP] CVE-2013-0657 FSC20130121-06 Schneider Electric Interactive Graphical SCADA System', committer_id:'1',gid:'1',sid:'nil',rev:'1',user_id: u1.id, classification: 0)
# b2 = Bug.create(bugzilla_id:'103015',state:'ASSIGNED',status:'NEW',resolution:'OPEN',summary:'[SID] 22078,25366-25367 [SPARK] [NSS][MSTUES] FSC20120508-11 CVE-2012-0143 Microsoft Excel invalid Window2 BIFF record',committer_id:'1',gid:'1',sid:'nil',rev:'1',user_id: u2.id, classification: 2)
# b3 = Bug.create(bugzilla_id:'103016',state:'ASSIGNED',status:'NEW',resolution:'OPEN',summary:'Microsoft Excel invalid Window2 BIFF record',committer_id:'1',gid:'1',sid:'nil',rev:'1',user_id: u1.id,classification:0)
#
# #some closed bugs for stats
# Bug.create(bugzilla_id:'000001',state:'FIXED',status:'RESOLVED',resolution:'FIXED',summary:'Important Bug #1',gid:'1',sid:'nil',rev:'1',user_id:u1.id,committer_id:u2.id,classification:0,work_time:5.78,rework_time:2.97,review_time:5.43)
# Bug.create(bugzilla_id:'000002',state:'FIXED',status:'RESOLVED',resolution:'FIXED',summary:'Important Bug #2',gid:'1',sid:'nil',rev:'1',user_id:u1.id,committer_id:u2.id,classification:0,work_time:10.24,rework_time:6.04,review_time:1.3)
# Bug.create(bugzilla_id:'000003',state:'FIXED',status:'RESOLVED',resolution:'FIXED',summary:'Important Bug #3',gid:'1',sid:'nil',rev:'1',user_id:u1.id,committer_id:u2.id,classification:0,work_time:6.45,rework_time:4.72,review_time:0.51)
# Bug.create(bugzilla_id:'000004',state:'FIXED',status:'RESOLVED',resolution:'FIXED',summary:'Important Bug #4',gid:'1',sid:'nil',rev:'1',user_id:u1.id,committer_id:u2.id,classification:0,work_time:10.76,rework_time:nil,review_time:4.44)
# Bug.create(bugzilla_id:'000005',state:'FIXED',status:'RESOLVED',resolution:'FIXED',summary:'Important Bug #5',gid:'1',sid:'nil',rev:'1',user_id:u1.id,committer_id:u2.id,classification:0,work_time:1.82,rework_time:3.86,review_time:4.4)
# Bug.create(bugzilla_id:'000006',state:'FIXED',status:'RESOLVED',resolution:'FIXED',summary:'Important Bug #6',gid:'1',sid:'nil',rev:'1',user_id:u1.id,committer_id:u2.id,classification:0,work_time:12.13,rework_time:2.18,review_time:0.03)
# Bug.create(bugzilla_id:'000007',state:'FIXED',status:'RESOLVED',resolution:'FIXED',summary:'Important Bug #7',gid:'1',sid:'nil',rev:'1',user_id:u1.id,committer_id:u2.id,classification:0,work_time:5.18,rework_time:4.44,review_time:2.7)
# Bug.create(bugzilla_id:'000008',state:'FIXED',status:'RESOLVED',resolution:'FIXED',summary:'Important Bug #8',gid:'1',sid:'nil',rev:'1',user_id:u1.id,committer_id:u2.id,classification:0,work_time:4.3,rework_time:nil,review_time:3.92)
# Bug.create(bugzilla_id:'000009',state:'FIXED',status:'RESOLVED',resolution:'FIXED',summary:'Important Bug #9',gid:'1',sid:'nil',rev:'1',user_id:u1.id,committer_id:u2.id,classification:0,work_time:7.29,rework_time:nil,review_time:0.13)
#
# Bug.create(bugzilla_id:'000010',state:'FIXED',status:'RESOLVED',resolution:'FIXED',summary:'Important Bug #10',gid:'1',sid:'nil',rev:'1',user_id:u2.id,committer_id:u1.id,classification:0,work_time:1.49,rework_time:nil,review_time:4.59)
# Bug.create(bugzilla_id:'000011',state:'FIXED',status:'RESOLVED',resolution:'FIXED',summary:'Important Bug #11',gid:'1',sid:'nil',rev:'1',user_id:u2.id,committer_id:u1.id,classification:0,work_time:2.72,rework_time:8.44,review_time:2.67)
# Bug.create(bugzilla_id:'000012',state:'FIXED',status:'RESOLVED',resolution:'FIXED',summary:'Important Bug #12',gid:'1',sid:'nil',rev:'1',user_id:u2.id,committer_id:u1.id,classification:0,work_time:7.27,rework_time:nil,review_time:4.75)
# Bug.create(bugzilla_id:'000013',state:'FIXED',status:'RESOLVED',resolution:'FIXED',summary:'Important Bug #13',gid:'1',sid:'nil',rev:'1',user_id:u2.id,committer_id:u1.id,classification:0,work_time:9.41,rework_time:nil,review_time:6.47)
# Bug.create(bugzilla_id:'000014',state:'FIXED',status:'RESOLVED',resolution:'FIXED',summary:'Important Bug #14',gid:'1',sid:'nil',rev:'1',user_id:u2.id,committer_id:u1.id,classification:0,work_time:9.44,rework_time:nil,review_time:6.86)
#
# a1 = Attachment.create(bugzilla_attachment_id:'137288',direct_upload_url: 'https://bugzilla.vrt.sourcefire.com/attachment.cgi?id=137288',file_name:'2006-5112-20250-metasploit-60939-1.pcap',size: '2', creator: u2.email, content_type: "text/plain",summary:"just some words")
# b3.attachments << a1
# a2 = Attachment.create(bugzilla_attachment_id:'83950',direct_upload_url: 'https://bugzilla.vrt.sourcefire.com/attachment.cgi?id=83950',file_name:'FSC20120110-17-attack-1a.pcap',size: '17', creator: u1.email, content_type: "text/plain",summary:"just some words")
# b1.attachments << a2
# a3 = Attachment.create(bugzilla_attachment_id:'113473',direct_upload_url: 'https://bugzilla.vrt.sourcefire.com/attachment.cgi?id=113473',file_name:'normal-2011-0098-ms-84851-1.pcap',size: '19', creator: u1.email, content_type: "text/plain",summary:"just some words")
# b3.attachments << a3
#
# Note.create(comment: "This is some content",note_type: "committer",author: "nicherbe@cisco.com", bug_id: b1.id)
# Note.create(comment: "We should all have awesome notes",note_type: "committer",author: "nicherbe@cisco.com", bug_id: b2.id)
# Note.create(comment: "Test research content is important",note_type: "research",author: "nicherbe@cisco.com", bug_id: b3.id)
# Note.create(comment: "More notes to test multiple notes on a bug",note_type: "research",author: "nicherbe@cisco.com", bug_id: b1.id)
#
# n4 = Note.create(comment: "More notes to test multiple notes on a bug",note_type: "research",author: "nicherbe@cisco.com")
# b1.notes << n4
# b1.save
