# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)



u1 = User.create(cvs_username:"tuser1",email:"testUser1@cisco.com  ",password: 'password', password_confirmation: 'password',committer:'false')
u2 = User.create(cvs_username:"tuser2",email:"testUser2@cisco.com",password: 'password', password_confirmation: 'password',committer:'false')


Reference.create(name:'telus', description:'Telus bug report information', validation: 'nil', bugzilla_format:'((FSC|TSL)\\d{8}-\\d{2})',example:'FSC20111103-05',rule_format:'<reference>',url:'https://portal.telussecuritylabs.com/threat/DATA')


Rule.create(gid:'1',sid:'3679',rev:'12',message:'INDICATOR-OBFUSCATION Multiple Products IFRAME src javascript code execution',content:'alert tcp $EXTERNAL_NET $HTTP_PORTS -> $HOME_NET any (msg:"INDICATOR-OBFUSCATION Multiple Products IFRAME src javascript code execution"; flow:to_client,established; file_data; content:"IFRAME"; nocase; pcre:"/\x3c\s*IFRAME\s*[^\x3e]*src=\x22javascript\x3a/smi"; metadata:service http; reference:bugtraq,13544; reference:bugtraq,30560; reference:cve,2005-1476; reference:cve,2008-2939; reference:nessus,18243; classtype:attempted-user; sid:3679; rev:12;)', state:'open',average_check: '29.0',average_match:'73.1',average_nonmatch:'24,9',tested:'false')
Rule.create(gid:'1',sid:'13990',rev:'17',message:'SQL union select - possible sql injection attempt - GET parameter',content:'alert tcp $EXTERNAL_NET any -> $HOME_NET $HTTP_PORTS (msg:"SQL union select - possible sql injection attempt - GET parameter"; flow:to_server,established; content:"union"; fast_pattern; nocase; http_uri; content:"select"; nocase; http_uri; pcre:"/union\s+(all\s+)?select\s+/Ui"; metadata:policy security-ips drop, service http; reference:bugtraq,21227; reference:cve,2006-6268; reference:cve,2007-1021; reference:cve,2007-2824; reference:cve,2011-1667; reference:url,www.securityfocus.com/archive/1/452259; classtype:misc-attack; sid:13990; rev:17;)',state:'open',average_check: '8.3',average_match:'24.9',average_nonmatch:'0.0',tested:'false')
Rule.create(gid:'1',sid:'19439',rev:'8',message:'SQL 1 = 1 - possible sql injection attempt',content:'alert tcp $EXTERNAL_NET any -> $HOME_NET $HTTP_PORTS (msg:"SQL 1 = 1 - possible sql injection attempt"; flow:to_server,established; content:"1=1"; fast_pattern:only; http_uri; pcre:"/(and|or)[\s\x2f\x2A]+1=1/Ui"; metadata:policy balanced-ips drop, policy security-ips drop, service http; reference:url,ferruh.mavituna.com/sql-injection-cheatsheet-oku/; classtype:web-application-attack; sid:19439; rev:8;)',state:'open',average_check:'1.4',average_match:'4.7',average_nonmatch:'0.1',tested:'false')
Rule.create(gid:'1',sid:'24172',rev:'1',message:'SQL use of concat function with select - likely SQL injection',content:'alert tcp $EXTERNAL_NET any -> $HOME_NET $HTTP_PORTS (msg:"SQL use of concat function with select - likely SQL injection"; flow:to_server,established; content:"SELECT "; nocase; http_uri; content:"CONCAT|28|"; within:100; nocase; http_uri; metadata:policy security-ips drop, service http; reference:url,ferruh.mavituna.com/sql-injection-cheatsheet-oku/; classtype:web-application-attack; sid:24172; rev:1;)',state:'open',average_check:'0.1',average_match:'0.0',average_nonmatch:'0.1',tested:'false')
Rule.create(gid:'1',sid:'17129',rev:'18',message:'BROWSER-IE Microsoft Internet Explorer use-after-free memory corruption attempt',content:'alert tcp $EXTERNAL_NET $HTTP_PORTS -> $HOME_NET any (msg:"BROWSER-IE Microsoft Internet Explorer use-after-free memory corruption attempt"; flow:to_client,established; file_data; content:"<script>"; nocase; content:"function"; distance:0; nocase; content:"()"; within:30; content:"location."; fast_pattern:only; pcre:"/function\s+?\w+\s*?\x28[^\x7b]+?\x7b[^\x7d]*?location\.(protocol|href)\s*?=\s*?[\x22\x27]\s*?(mailto|http|file).*?[\x22\x27]/smi"; metadata:service http; reference:bugtraq,42257; reference:cve,2010-2556; reference:url,osvdb.org/show/osvdb/66999; reference:url,technet.microsoft.com/en-us/security/bulletin/ms10-053; classtype:attempted-dos; sid:17129; rev:18;)',state:'open',average_check:'11.8',average_match:'0.0',average_nonmatch:'7.4',tested:'false')
Rule.create(gid:'1',sid:'30040',rev:'2',message:'SQL 1 = 1 - possible sql injection attempt',content:'alert tcp $EXTERNAL_NET any -> $HOME_NET $HTTP_PORTS (msg:"SQL 1 = 1 - possible sql injection attempt"; flow:to_server,established; content:"1%3D1"; fast_pattern:only; http_client_body; pcre:"/or\++1%3D1/Pi"; metadata:policy balanced-ips drop, policy security-ips drop, service http; reference:url,ferruh.mavituna.com/sql-injection-cheatsheet-oku/; classtype:web-application-attack; sid:30040; rev:2;)',state:'open',average_check:'3.6',average_match:'0.0',average_nonmatch:'0.0',tested:'false')


Exploit.create(name:"exploit abc123",description:"this is an exploit that everything has",pcap_validation:"?? dont know....",data:"blah blah blah data goes here. lots of data im not sure how much data but i would imagine lots would need to be here. I could talk all day about data but i wont because there are other things to do.")

b1 = Bug.create(bugzilla_id:'116261',state:'PENDING',status:'RESOLVED',resolution:'PENDING',summary:'[TELUS][VULN][SID] 25849-25852,26392,29504 [BP] CVE-2013-0657 FSC20130121-06 Schneider Electric Interactive Graphical SCADA System', committer_id:'1',gid:'1',sid:'nil',rev:'1',user_id: u1.id, classification: 0)
b2 = Bug.create(bugzilla_id:'103015',state:'ASSIGNED',status:'NEW',resolution:'OPEN',summary:'[SID] 22078,25366-25367 [SPARK] [NSS][MSTUES] FSC20120508-11 CVE-2012-0143 Microsoft Excel invalid Window2 BIFF record',committer_id:'1',gid:'1',sid:'nil',rev:'1',user_id: u2, classification: 2)
b3 = Bug.create(bugzilla_id:'103016',state:'ASSIGNED',status:'NEW',resolution:'OPEN',summary:'Microsoft Excel invalid Window2 BIFF record',committer_id:'1',gid:'1',sid:'nil',rev:'1',user_id: u1.id, classification: 0)

a1 = Attachment.create(bugzilla_attachment_id:'137288',direct_upload_url: 'https://bugzilla.vrt.sourcefire.com/attachment.cgi?id=137288',file_name:'2006-5112-20250-metasploit-60939-1.pcap',size: '2', creator: u2.email, content_type: "text/plain",summary:"just some words")
b3.attachments << a1
a2 = Attachment.create(bugzilla_attachment_id:'83950',direct_upload_url: 'https://bugzilla.vrt.sourcefire.com/attachment.cgi?id=83950',file_name:'FSC20120110-17-attack-1a.pcap',size: '17', creator: u1.email, content_type: "text/plain",summary:"just some words")
b1.attachments << a2
a3 = Attachment.create(bugzilla_attachment_id:'113473',direct_upload_url: 'https://bugzilla.vrt.sourcefire.com/attachment.cgi?id=113473',file_name:'normal-2011-0098-ms-84851-1.pcap',size: '19', creator: u1.email, content_type: "text/plain",summary:"just some words")
b3.attachments << a3

Note.create(comment: "This is some content",note_type: "committer",author: "nicherbe@cisco.com", bug_id: b1.id)
Note.create(comment: "We should all have awesome notes",note_type: "committer",author: "nicherbe@cisco.com", bug_id: b2.id)
Note.create(comment: "Test research content is important",note_type: "research",author: "nicherbe@cisco.com", bug_id: b3.id)
Note.create(comment: "More notes to test multiple notes on a bug",note_type: "research",author: "nicherbe@cisco.com", bug_id: b1.id)

n4 = Note.create(comment: "More notes to test multiple notes on a bug",note_type: "research",author: "nicherbe@cisco.com")
b1.notes << n4
b1.save
