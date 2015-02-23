# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)


User.create(cvs_username:"pamullen",email:"pamullen@cisco.com",password: 'password', password_confirmation: 'password',committer:'false')

c1 = Contact.create(name: 'Giamia',about: 'Although Giamia came from a humble spark of lightning, he quickly grew to be a great craftsman, providing all the warming instruments needed by those close to him.',avatar: 'images/contacts/giamia.png')
c2 = Contact.create(name: 'Anostagia',about: 'Knowing there was a need for it, Anostagia drew on her experience and spearheaded the Flint & Flame storefront. In addition to coding the site, she also creates a few products available in the store.',avatar: 'images/contacts/anostagia.png')

p1 = Product.create(title: 'flint',price: 99,description: 'Flint is a hard, sedimentary cryptocrystalline form of the mineral quartz, categorized as a variety of chert.',isOnSale: true, image: 'images/products/flint.png',contact_id: c1.id)
p2 = Product.create(title: 'Kindling',price: 249,description: 'Easily combustible small sticks or twigs used for starting a fire.',isOnSale: false, image: 'images/products/kindling.png',contact_id: c2.id)
p3 = Product.create(title: 'Bow Drill',price: 999,description: 'The bow drill is an ancient tool. While it was usually used to make fire, it was also used for primitive woodworking and dentistry.',isOnSale: false, image: 'images/products/bow-drill.png',contact_id: c1.id)
p4 = Product.create(title: 'Tinder',price: 499,description: 'Tinder is easily combustible material used to ignite fires by rudimentary methods.',isOnSale: true, image: 'images/products/tinder.png',contact_id: c2.id)
p5 = Product.create(title: 'Birch Bark Shaving',price: 899,description: 'Fresh and easily combustable',isOnSale: true, image: 'images/products/birch.png',contact_id: c2.id)
p6 = Product.create(title: 'Matches',price:550,description:'One end is coated with a material that can be ignited by frictional heat generated by striking the match against a suitable surface.', isOnSale: true, image:'images/products/matches.png', contact_id: c2.id)

r1 = Review.create(reviewedAt: (DateTime.now - 3.days),text: "Started a fire in no time!",rating: 4, product_id: p3.id)
r2 = Review.create(reviewedAt: DateTime.now,text: "Not the brightest flame, but warm!",rating: 3, product_id: p6.id)
r3 = Review.create(reviewedAt: (DateTime.now - 5.days),text: "This is some amazing Flint! It lasts **forever** and works even when damp! I still remember the first day when I was only a little fire sprite and got one of these in my flame stalking for treemas. My eyes lit up the moment I tried it! Here's just a few uses for it:\n\n* Create a fire using just a knife and kindling!\n* Works even after jumping in a lake (although, that's suicide for me)\n* Small enough to fit in a pocket -- if you happen to wear pants\n\n\nYears later I'm still using the _same one_. That's the biggest advantage of this -- it doesn't run out easily like matches. As long as you have something to strike it against, **you can start a fire anywhere** you have something to burn!",rating: 5, product_id: p1.id)


Reference.create(name:'telus', description:'Telus bug report information', validation: 'nil', bugzilla_format:'((FSC|TSL)\\d{8}-\\d{2})',example:'FSC20111103-05',rule_format:'<reference>',url:'https://portal.telussecuritylabs.com/threat/DATA')

Attachment.create(bugzilla_attachment_id: '1234',filename:'some attachment',file_size:'25')

Rule.create(gid:'1',sid:'3679',rev:'12',message:'INDICATOR-OBFUSCATION Multiple Products IFRAME src javascript code execution',content:'alert tcp $EXTERNAL_NET $HTTP_PORTS -> $HOME_NET any (msg:"INDICATOR-OBFUSCATION Multiple Products IFRAME src javascript code execution"; flow:to_client,established; file_data; content:"IFRAME"; nocase; pcre:"/\x3c\s*IFRAME\s*[^\x3e]*src=\x22javascript\x3a/smi"; metadata:service http; reference:bugtraq,13544; reference:bugtraq,30560; reference:cve,2005-1476; reference:cve,2008-2939; reference:nessus,18243; classtype:attempted-user; sid:3679; rev:12;)', state:'open',average_check: '29.0',average_match:'73.1',average_nonmatch:'24,9',tested:'false')
Rule.create(gid:'1',sid:'13990',rev:'17',message:'SQL union select - possible sql injection attempt - GET parameter',content:'alert tcp $EXTERNAL_NET any -> $HOME_NET $HTTP_PORTS (msg:"SQL union select - possible sql injection attempt - GET parameter"; flow:to_server,established; content:"union"; fast_pattern; nocase; http_uri; content:"select"; nocase; http_uri; pcre:"/union\s+(all\s+)?select\s+/Ui"; metadata:policy security-ips drop, service http; reference:bugtraq,21227; reference:cve,2006-6268; reference:cve,2007-1021; reference:cve,2007-2824; reference:cve,2011-1667; reference:url,www.securityfocus.com/archive/1/452259; classtype:misc-attack; sid:13990; rev:17;)',state:'open',average_check: '8.3',average_match:'24.9',average_nonmatch:'0.0',tested:'false')
Rule.create(gid:'1',sid:'19439',rev:'8',message:'SQL 1 = 1 - possible sql injection attempt',content:'alert tcp $EXTERNAL_NET any -> $HOME_NET $HTTP_PORTS (msg:"SQL 1 = 1 - possible sql injection attempt"; flow:to_server,established; content:"1=1"; fast_pattern:only; http_uri; pcre:"/(and|or)[\s\x2f\x2A]+1=1/Ui"; metadata:policy balanced-ips drop, policy security-ips drop, service http; reference:url,ferruh.mavituna.com/sql-injection-cheatsheet-oku/; classtype:web-application-attack; sid:19439; rev:8;)',state:'open',average_check:'1.4',average_match:'4.7',average_nonmatch:'0.1',tested:'false')
Rule.create(gid:'1',sid:'24172',rev:'1',message:'SQL use of concat function with select - likely SQL injection',content:'alert tcp $EXTERNAL_NET any -> $HOME_NET $HTTP_PORTS (msg:"SQL use of concat function with select - likely SQL injection"; flow:to_server,established; content:"SELECT "; nocase; http_uri; content:"CONCAT|28|"; within:100; nocase; http_uri; metadata:policy security-ips drop, service http; reference:url,ferruh.mavituna.com/sql-injection-cheatsheet-oku/; classtype:web-application-attack; sid:24172; rev:1;)',state:'open',average_check:'0.1',average_match:'0.0',average_nonmatch:'0.1',tested:'false')
Rule.create(gid:'1',sid:'17129',rev:'18',message:'BROWSER-IE Microsoft Internet Explorer use-after-free memory corruption attempt',content:'alert tcp $EXTERNAL_NET $HTTP_PORTS -> $HOME_NET any (msg:"BROWSER-IE Microsoft Internet Explorer use-after-free memory corruption attempt"; flow:to_client,established; file_data; content:"<script>"; nocase; content:"function"; distance:0; nocase; content:"()"; within:30; content:"location."; fast_pattern:only; pcre:"/function\s+?\w+\s*?\x28[^\x7b]+?\x7b[^\x7d]*?location\.(protocol|href)\s*?=\s*?[\x22\x27]\s*?(mailto|http|file).*?[\x22\x27]/smi"; metadata:service http; reference:bugtraq,42257; reference:cve,2010-2556; reference:url,osvdb.org/show/osvdb/66999; reference:url,technet.microsoft.com/en-us/security/bulletin/ms10-053; classtype:attempted-dos; sid:17129; rev:18;)',state:'open',average_check:'11.8',average_match:'0.0',average_nonmatch:'7.4',tested:'false')
Rule.create(gid:'1',sid:'30040',rev:'2',message:'SQL 1 = 1 - possible sql injection attempt',content:'alert tcp $EXTERNAL_NET any -> $HOME_NET $HTTP_PORTS (msg:"SQL 1 = 1 - possible sql injection attempt"; flow:to_server,established; content:"1%3D1"; fast_pattern:only; http_client_body; pcre:"/or\++1%3D1/Pi"; metadata:policy balanced-ips drop, policy security-ips drop, service http; reference:url,ferruh.mavituna.com/sql-injection-cheatsheet-oku/; classtype:web-application-attack; sid:30040; rev:2;)',state:'open',average_check:'3.6',average_match:'0.0',average_nonmatch:'0.0',tested:'false')


Exploit.create(name:"exploit abc123",description:"this is an exploit that everything has",pcap_validation:"?? dont know....",data:"blah blah blah data goes here. lots of data im not sure how much data but i would imagine lots would need to be here. I could talk all day about data but i wont because there are other things to do.")


#
# Attachment.create(bugzilla_attachment_id: '1234',filename:'some attachment',file_size:'25')
#
#
# Rule.create(gid:'1',sid:'12345',rev:'1',message:'This is a message',content:'this is where the content goes',state:'open',average_check: '2.5',average_match:'1.7',tested:'false')
# Rule.create(gid:'1',sid:'54321',rev:'1',message:'This is a new message',content:'content works here',state:'open',average_check: '2.2',average_match:'3.1',tested:'false')
#
# Exploit.create(name:"exploit abc123",description:"this is an exploit that everything has",pcap_validation:"?? dont know....",data:"blah blah blah data goes here. lots of data im not sure how much data but i would imagine lots would need to be here. I could talk all day about data but i wont because there are other things to do.")
#
#

