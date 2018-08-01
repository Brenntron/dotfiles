# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)


ReferenceType.create(:name => 'cve',:description => 'Common Vulnerabilities and Exposures',:validation => '^(19|20)\d{2}-\d{4,}$',:bugzilla_format => 'cve-((19|20)\d{2}-\d{4,})',:example => '1999-1234',:rule_format => 'cve,<reference>',:url => 'http://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-DATA')
ReferenceType.create(:name => 'bugtraq',:description => 'Bugtraq - SecurityFocus',:validation => '^\d{1,10}$',:example => '12345',:rule_format => 'bugtraq,<reference>',:url => 'http://www.securityfocus.com/bid/DATA')
ReferenceType.create(:name => 'url',:description => 'Generic URL for vulnerability information',:validation => '^(?!http|ftp).*',:example => 'www.somesite.com/whatever/whocares',:rule_format => 'url,<reference>',:url => 'http://DATA')
ReferenceType.create(:name => 'nessus', :url => 'http://cgi.nessus.org/plugins/dump.php3?id=')
ReferenceType.create(:name => 'arachnids', :url => 'http://www.whitehats.com/info/IDS')
ReferenceType.create(:name => 'mcafee', :url => 'http://vil.nai.com/vil/content/v_')
# These don't appear to be used currently, but it doesn't hurt to have a few extra db rows in case
ReferenceType.create(:name => 'osvdb',:description => 'The Open Source Vulnerability Database',:validation => '^\d{1,10}$',:example => '12345',:rule_format => 'osvdb,<reference>',:url => 'http://www.osvdb.org/DATA')
ReferenceType.create(:name => 'msb',:description => 'Microsoft Security Bulletin',:validation => '^MS\d{2}-\d{3}$',:bugzilla_format => '(MS\d{2}-\d{3})',:example => 'MS08-067',:rule_format => 'url,technet.microsoft.com/en-us/security/bulletin/<reference>',:url => 'http://technet.microsoft.com/en-us/security/bulletin/DATA')
ReferenceType.create(:name => 'telus',:description => 'Telus bug report information',:bugzilla_format => '((FSC|TSL)\d{8}-\d{2})',:example => 'FSC20111103-05',:rule_format => '<reference>',:url => 'https://portal.telussecuritylabs.com/threat/DATA')
ReferenceType.create(:name => 'apsb',:description => 'Adobe Product Security Bulletin',:validation => '^APSB\d{2}-\d{2}$',:bugzilla_format => '(APSB\d{2}-\d{2})',:example => 'APSB13-03',:rule_format => 'url,www.adobe.com/support/security/bulletins/<reference>.html',:url => 'url,www.adobe.com/support/security/bulletins/DATA.html')

ExploitType.create(:name => 'core',:description => 'Core Impact exploit module.',:pcap_validation => '^((19|20)\d{2}-\d{4}$|none)-(\d+|none)-((ms\d{2}-\d{3}-)?)-core-\d+-\d+\.pcap')
ExploitType.create(:name => 'metasploit',:description => 'Metasploit exploit module.',:pcap_validation => '^((19|20)\d{2}-\d{4}$|none)-(\d+|none)-((ms\d{2}-\d{3}-)?)-metasploit-\d+-\d+\.pcap')
ExploitType.create(:name => 'canvas',:description => 'Immunity Canvas exploit module.',:pcap_validation => '^((19|20)\d{2}-\d{4}$|none)-(\d+|none)-((ms\d{2}-\d{3}-)?)-canvas-\d+-\d+\.pcap')
ExploitType.create(:name => 'other',:description => 'Other publicly available exploit module.',:pcap_validation => '^((19|20)\d{2}-\d{4}$|none)-(\d+|none)-((ms\d{2}-\d{3}-)?)-other-\d+-\d+\.pcap')
ExploitType.create(:name => 'telus',:description => 'Other publicly available exploit module.',:pcap_validation => '^((FSC|TSL)\d{8}-\d{2})-.*?attack-*?\.pcap$')
ExploitType.create(:name => 'expldb',:description => 'Other publicly available exploit module.',:pcap_validation => '^((19|20)\d{2}-\d{4}$|none)-(\d+|none)-((ms\d{2}-\d{3}-)?)-expldb-\d+-\d+\.pcap')

rule_categories = ['APP-DETECT', 'BLACKLIST', 'BROWSER-CHROME', 'BROWSER-FIREFOX', 'BROWSER-IE', 'BROWSER-OTHER',
                   'BROWSER-PLUGINS', 'BROWSER-WEBKIT', 'CONTENT-REPLACE', 'EXPLOIT-KIT', 'FILE-EXECUTABLE', 'FILE-FLASH',
                   'FILE-IDENTIFY', 'FILE-IMAGE', 'FILE-JAVA', 'FILE-MULTIMEDIA', 'FILE-OFFICE', 'FILE-OTHER', 'FILE-PDF',
                   'INDICATOR-COMPROMISE', 'INDICATOR-OBFUSCATION', 'INDICATOR-SCAN', 'INDICATOR-SHELLCODE', 'MALWARE-BACKDOOR',
                   'MALWARE-CNC', 'MALWARE-OTHER', 'MALWARE-TOOLS', 'NETBIOS', 'OS-LINUX', 'OS-MOBILE', 'OS-OTHER', 'OS-SOLARIS',
                   'OS-WINDOWS', 'POLICY-MULTIMEDIA', 'POLICY-OTHER', 'POLICY-SOCIAL', 'POLICY-SPAM', 'PROTOCOL-DNS',
                   'PROTOCOL-FINGER', 'PROTOCOL-FTP', 'PROTOCOL-ICMP', 'PROTOCOL-IMAP', 'PROTOCOL-NNTP', 'PROTOCOL-OTHER',
                   'PROTOCOL-POP', 'PROTOCOL-RPC', 'PROTOCOL-SCADA', 'PROTOCOL-SERVICES', 'PROTOCOL-SNMP', 'PROTOCOL-TELNET',
                   'PROTOCOL-TFTP', 'PROTOCOL-VOIP', 'PUA-ADWARE', 'PUA-OTHER', 'PUA-P2P', 'PUA-TOOLBARS', 'SERVER-APACHE',
                   'SERVER-IIS', 'SERVER-MAIL', 'SERVER-MSSQL', 'SERVER-MYSQL', 'SERVER-ORACLE', 'SERVER-OTHER', 'SERVER-SAMBA', 'SERVER-WEBAPP']

rule_categories.each do |rc|
  RuleCategory.create(category: rc)
end

roles = ['admin', 'analyst', 'build coordinator', 'committer', 'manager']

roles.each do |role|
  Role.create(role: role)
end

# vrt generic users
vi = User.create(kerberos_login:"vrtincom",cvs_username:"vrtincom",cec_username:"vrtincom",display_name:"Vrt Incoming",committer:true,email:"vrt-incoming@sourcefire.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')

vq = User.create(kerberos_login:"vrtqa",cvs_username:"vrtqa",cec_username:"vrtqa",display_name:"Vrt quality assurance",committer:true,email:"vrt-qa@sourcefire.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')

# admins
je = User.create(kerberos_login:"jesler",cvs_username:"jesler",cec_username:"jesler",display_name:"Joel Esler",committer:true,email:"jesler@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')
je.roles << Role.where(role: 'admin')
je.roles << Role.where(role: 'manager')

nh = User.create(kerberos_login:"nherbert",cvs_username:"nherbert",cec_username:"nicherbe",display_name:"Nick Herbert",committer:true,email:"nicherbe@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')
nh.roles << Role.where(role: 'admin')
nh.roles << Role.where(role: 'manager')
nh.move_to_child_of(je)

nv = User.create(kerberos_login:"nverbeck",cvs_username:"nverbeck",cec_username:"nverbeck",display_name:"Nicolette Verbeck",committer:true,email:"nverbeck@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')
nv.roles << Role.where(role: 'admin')
nv.move_to_child_of(nh)

mp = User.create(kerberos_login:"marlpier",cvs_username:"marlpier",cec_username:"marlpier",display_name:"Marlin Pierce",committer:true,email:"marlpier@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')
mp.roles << Role.where(role: 'admin')
mp.move_to_child_of(nh)

ts = User.create(kerberos_login:"tsmallwo",cvs_username:"tsmallwo",cec_username:"tsmallwo",display_name:"Thomas Smallwood",committer:true,email:"tsmallwo@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')
ts.roles << Role.where(role: 'admin')
ts.move_to_child_of(nh)

# managers
chinski = User.create(kerberos_login:"mwatchinski",cvs_username:"mwatchinski",cec_username:"mwatchin",display_name:"Matt Watchinski",committer:true,email:"mwatchin@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')
chinski.roles << Role.where(role: 'manager')
je.move_to_child_of(chinski)

cm = User.create(kerberos_login:"cmarshall",cvs_username:"cmarshall",cec_username:"marshal1",display_name:"Chris Marshall",committer:true,email:"marshal1@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')
cm.roles << Role.where(role: 'manager')
cm.roles << Role.where(role: 'committer')
cm.move_to_child_of(chinski)

pm = User.create(kerberos_login:"pmullen",cvs_username:"pmullen",cec_username:"pamullen",display_name:"Patrick Mullen",committer:true,email:"pamullen@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')
pm.roles << Role.where(role: 'manager')
pm.roles << Role.where(role: 'committer')
#add as child to chris marshall
pm.move_to_child_of(cm)

olney = User.create(kerberos_login:"molney",cvs_username:"molney",cec_username:"molney",display_name:"Matt Olney",committer:true,email:"molney@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')
olney.roles << Role.where(role: 'manager')
olney.move_to_child_of(chinski)

nigel = User.create(kerberos_login:"nhoughton",cvs_username:"nhoughton",cec_username:"nhoughto",display_name:"Nigel Houghton",committer:true,email:"nhoughto@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')
nigel.roles << Role.where(role: 'manager')
nigel.move_to_child_of(chinski)

nr = User.create(kerberos_login:"drandolph",cvs_username:"drandolph",cec_username:"nrandolp",display_name:"Nick Randolph",committer:true,email:"nrandolp@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')
nr.roles << Role.where(role: 'manager')

pentney = User.create(kerberos_login:"rpentney",cvs_username:"rpentney",cec_username:"rpentney",display_name:"Ryan Pentney",committer:true,email:"rpentney@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')
pentney.roles << Role.where(role: 'manager')
pentney.move_to_child_of(olney)

mickel = User.create(kerberos_login:"mmickel",cvs_username:"mmickel",cec_username:"mmickel",display_name:"Matthew Mickel",committer:true,email:"mmickel@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')
mickel.roles << Role.where(role: 'manager')

jmarsh = User.create(kerberos_login:"josmarsh",cvs_username:"josmarsh",cec_username:"josmarsh",display_name:"Joe Marshall",committer:true,email:"josmarsh@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')
jmarsh.roles << Role.where(role: 'manager')
jmarsh.move_to_child_of(cm)

blunck = User.create(kerberos_login:"ablunck",cvs_username:"ablunck",cec_username:"ablunck",display_name:"Andrew Blunck",committer:true,email:"ablunck@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')
blunck.roles << Role.where(role: 'manager')

yves = User.create(kerberos_login:"yyounan",cvs_username:"yyounan",cec_username:"yvyounan",display_name:"Yves Younan",committer:true,email:"yvyounan@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')
yves.roles << Role.where(role: 'manager')
yves.move_to_child_of(nigel)

alain = User.create(kerberos_login:"azidouemba",cvs_username:"azidouemba",cec_username:"azidouem",display_name:"Alain Zidouemba",committer:true,email:"azidouem@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')
alain.roles << Role.where(role: 'manager')
alain.move_to_child_of(cm)

kambis = User.create(kerberos_login:"akambis",cvs_username:"akambis",cec_username:"akambis",display_name:"Alex Kambis",committer:true,email:"akambis@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')
kambis.roles << Role.where(role: 'manager')
kambis.move_to_child_of(nigel)

micharr = User.create(kerberos_login:"micharr3",cvs_username:"micharr3",cec_username:"micharr3",display_name:"Michael Harris",committer:true,email:"micharr3@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')
micharr.roles << Role.where(role: 'manager')
micharr.move_to_child_of(nigel)

nolan = User.create(kerberos_login:"knolan",cvs_username:"knolan",cec_username:"kanolan",display_name:"Kate Nolan",committer:true,email:"kanolan@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')
nolan.roles << Role.where(role: 'manager')

morgan = User.create(kerberos_login:"smorgan",cvs_username:"smorgan",cec_username:"stevmorg",display_name:"Steve Morgan",committer:true,email:"stevmorg@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')
morgan.roles << Role.where(role: 'manager')

raynor = User.create(kerberos_login:"draynor",cvs_username:"draynor",cec_username:"draynor",display_name:"Dave Raynor",committer:true,email:"draynor@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')
raynor.roles << Role.where(role: 'manager')
raynor.move_to_child_of(olney)

jj = User.create(kerberos_login:"jcummings",cvs_username:"jcummings",cec_username:"jjcummin",display_name:"JJ Cummings",committer:true,email:"jjcummin@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')
jj.roles << Role.where(role: 'manager')
jj.move_to_child_of(olney)

# analysts/committers

am = User.create(kerberos_login:"amcdonnell",cvs_username:"amcdonnell",cec_username:"almcdonn",display_name:"Alex McDonnell",committer:true,email:"almcdonn@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')
am.move_to_child_of(pm)


tm = User.create(kerberos_login:"tmontier",cvs_username:"tmontier",cec_username:"tmontier",display_name:"Tyler Montier",committer:true,email:"tmontier@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')
tm.roles << Role.where(role: 'committer')

cz = User.create(kerberos_login:"cmarczewski",cvs_username:"cmarczewski",cec_username:"cmarczew",display_name:"Chris Marczewski",committer:true,email:"cmarczew@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')
cz.roles << Role.where(role: 'committer')

gs = User.create(kerberos_login:"gserrao",cvs_username:"gserrao",cec_username:"gserrao",display_name:"Geoff Serrao",committer:true,email:"gserrao@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')


lieb = User.create(kerberos_login:"dliebenb",cvs_username:"dliebenb",cec_username:"dliebenb",display_name:"David Liebenberg",committer:true,email:"dliebenb@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')

graz = User.create(kerberos_login:"magrazia",cvs_username:"magrazia",cec_username:"magrazia",display_name:"Mariano Graziano",committer:true,email:"magrazia@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')

bania = User.create(kerberos_login:"pbania",cvs_username:"pbania",cec_username:"pbania",display_name:"Piotr Bania",committer:true,email:"pbania@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')

mercer = User.create(kerberos_login:"wmercer",cvs_username:"wmercer",cec_username:"wamercer",display_name:"Warren Mercer",committer:true,email:"wamercer@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')

mcdan = User.create(kerberos_login:"dmcdaniel",cvs_username:"dmcdaniel",cec_username:"davemcda",display_name:"Dave McDaniel",committer:true,email:"davemcda@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')

kbrook = User.create(kerberos_login:"kbrooks",cvs_username:"kbrooks",cec_username:"kevbrook",display_name:"Kevin Brooks",committer:true,email:"kevbrook@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')

pfrank = User.create(kerberos_login:"pfrank",cvs_username:"pfrank",cec_username:"paufrank",display_name:"Paul Frank",committer:true,email:"paufrank@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')


arnes = User.create(kerberos_login:"jarneson",cvs_username:"jarneson",cec_username:"jarneson",display_name:"John Arneson",committer:true,email:"jarneson@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')

erick = User.create(kerberos_login:"egalinkin",cvs_username:"egalinkin",cec_username:"ergalink",display_name:"Erick Galinkin",committer:true,email:"ergalink@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')

mavis = User.create(kerberos_login:"nmavis",cvs_username:"nmavis",cec_username:"nmavis",display_name:"Nicholas Mavis",committer:true,email:"nmavis@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')


rjohn = User.create(kerberos_login:"rjohnson",cvs_username:"rjohnson",cec_username:"richjoh",display_name:"Rich Johnson",committer:true,email:"richjoh@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')
rjohn.move_to_child_of(nigel)


stultz = User.create(kerberos_login:"bstultz",cvs_username:"bstultz",cec_username:"brastult",display_name:"Brandon Stultz",committer:true,email:"brastult@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')


zeiser = User.create(kerberos_login:"mzeiser",cvs_username:"mzeiser",cec_username:"mzeiser",display_name:"Martin Zeiser",committer:true,email:"mzeiser@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')

jzadd = User.create(kerberos_login:"jzaddach",cvs_username:"jzaddach",cec_username:"jzaddach",display_name:"Jonas Zaddach",committer:true,email:"jzaddach@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')

angel = User.create(kerberos_login:"anvilleg",cvs_username:"anvilleg",cec_username:"anvilleg",display_name:"Angel Villegas",committer:true,email:"anvilleg@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')

mcbee = User.create(kerberos_login:"cmcbee",cvs_username:"cmcbee",cec_username:"chmcbee",display_name:"Christopher McBee",committer:true,email:"chmcbee@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')

pacho = User.create(kerberos_login:"cpacho",cvs_username:"cpacho",cec_username:"cpacho",display_name:"Carlos Pacho",committer:true,email:"cpacho@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')

rich = User.create(kerberos_login:"richard.harman",cvs_username:"richard.harman",cec_username:"rharmanj",display_name:"Richard Harman Jr",committer:true,email:"rharmanj@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')

suan = User.create(kerberos_login:"nsuan",cvs_username:"nsuan",cec_username:"nsuan",display_name:"Nick Suan",committer:true,email:"nsuan@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')

dvl = User.create(kerberos_login:"dvl",cvs_username:"dvl",cec_username:"dalangil",display_name:"Dan Langille",committer:true,email:"dalangil@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')

lazlo = User.create(kerberos_login:"ldanieli",cvs_username:"ldanieli",cec_username:"ldanieli",display_name:"Laszlo Danielisz",committer:true,email:"ldanieli@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')


felder = User.create(kerberos_login:"mafelder",cvs_username:"mafelder",cec_username:"mafelder",display_name:"Mark Felder",committer:true,email:"mafelder@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')


mclov = User.create(kerberos_login:"kmiklavcic",cvs_username:"kmiklavcic",cec_username:"kmiklavc",display_name:"Kevin Miklavcic",committer:true,email:"kmiklavc@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')

suffl = User.create(kerberos_login:"dsuffling",cvs_username:"dsuffling",cec_username:"dsufflin",display_name:"Dave Suffling",committer:true,email:"dsufflin@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')

samir = User.create(kerberos_login:"ssapra",cvs_username:"ssapra",cec_username:"ssapra",display_name:"Samir Sapra",committer:true,email:"ssapra@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')

judge = User.create(kerberos_login:"tjudge",cvs_username:"tjudge",cec_username:"tomjudge",display_name:"Tom Judge",committer:true,email:"tomjudge@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')


lin = User.create(kerberos_login:"klin",cvs_username:"klin",cec_username:"kevlin2",display_name:"Kevin Lin",committer:true,email:"kevlin2@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')

metz = User.create(kerberos_login:"rsteinmetz",cvs_username:"rsteinmetz",cec_username:"rsteinme",display_name:"Ryan Steinmetz",committer:true,email:"rsteinme@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')
metz.move_to_child_of(nigel)





gs = User.create(kerberos_login:"gserrao",cvs_username:"gserrao",cec_username:"gserrao",display_name:"Geoff Serrao",committer:true,email:"gserrao@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')


lieb = User.create(kerberos_login:"dliebenb",cvs_username:"dliebenb",cec_username:"dliebenb",display_name:"David Liebenberg",committer:true,email:"dliebenb@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')

graz = User.create(kerberos_login:"magrazia",cvs_username:"magrazia",cec_username:"magrazia",display_name:"Mariano Graziano",committer:true,email:"magrazia@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')

bania = User.create(kerberos_login:"pbania",cvs_username:"pbania",cec_username:"pbania",display_name:"Piotr Bania",committer:true,email:"pbania@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')

mercer = User.create(kerberos_login:"wmercer",cvs_username:"wmercer",cec_username:"wamercer",display_name:"Warren Mercer",committer:true,email:"wamercer@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')

mcdan = User.create(kerberos_login:"dmcdaniel",cvs_username:"dmcdaniel",cec_username:"davemcda",display_name:"Dave McDaniel",committer:true,email:"davemcda@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')

kbrook = User.create(kerberos_login:"kbrooks",cvs_username:"kbrooks",cec_username:"kevbrook",display_name:"Kevin Brooks",committer:true,email:"kevbrook@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')

pfrank = User.create(kerberos_login:"pfrank",cvs_username:"pfrank",cec_username:"paufrank",display_name:"Paul Frank",committer:true,email:"paufrank@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')


arnes = User.create(kerberos_login:"jarneson",cvs_username:"jarneson",cec_username:"jarneson",display_name:"John Arneson",committer:true,email:"jarneson@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')

erick = User.create(kerberos_login:"egalinkin",cvs_username:"egalinkin",cec_username:"ergalink",display_name:"Erick Galinkin",committer:true,email:"ergalink@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')

mavis = User.create(kerberos_login:"nmavis",cvs_username:"nmavis",cec_username:"nmavis",display_name:"Nicholas Mavis",committer:true,email:"nmavis@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')


rjohn = User.create(kerberos_login:"rjohnson",cvs_username:"rjohnson",cec_username:"richjoh",display_name:"Rich Johnson",committer:true,email:"richjoh@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')
rjohn.move_to_child_of(nigel)


stultz = User.create(kerberos_login:"bstultz",cvs_username:"bstultz",cec_username:"brastult",display_name:"Brandon Stultz",committer:true,email:"brastult@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')


zeiser = User.create(kerberos_login:"mzeiser",cvs_username:"mzeiser",cec_username:"mzeiser",display_name:"Martin Zeiser",committer:true,email:"mzeiser@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')

jzadd = User.create(kerberos_login:"jzaddach",cvs_username:"jzaddach",cec_username:"jzaddach",display_name:"Jonas Zaddach",committer:true,email:"jzaddach@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')

angel = User.create(kerberos_login:"anvilleg",cvs_username:"anvilleg",cec_username:"anvilleg",display_name:"Angel Villegas",committer:true,email:"anvilleg@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')

mcbee = User.create(kerberos_login:"cmcbee",cvs_username:"cmcbee",cec_username:"chmcbee",display_name:"Christopher McBee",committer:true,email:"chmcbee@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')

pacho = User.create(kerberos_login:"cpacho",cvs_username:"cpacho",cec_username:"cpacho",display_name:"Carlos Pacho",committer:true,email:"cpacho@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')

rich = User.create(kerberos_login:"richard.harman",cvs_username:"richard.harman",cec_username:"rharmanj",display_name:"Richard Harman Jr",committer:true,email:"rharmanj@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')

suan = User.create(kerberos_login:"nsuan",cvs_username:"nsuan",cec_username:"nsuan",display_name:"Nick Suan",committer:true,email:"nsuan@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')

dvl = User.create(kerberos_login:"dvl",cvs_username:"dvl",cec_username:"dalangil",display_name:"Dan Langille",committer:true,email:"dalangil@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')

lazlo = User.create(kerberos_login:"ldanieli",cvs_username:"ldanieli",cec_username:"ldanieli",display_name:"Laszlo Danielisz",committer:true,email:"ldanieli@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')


felder = User.create(kerberos_login:"mafelder",cvs_username:"mafelder",cec_username:"mafelder",display_name:"Mark Felder",committer:true,email:"mafelder@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')


mclov = User.create(kerberos_login:"kmiklavcic",cvs_username:"kmiklavcic",cec_username:"kmiklavc",display_name:"Kevin Miklavcic",committer:true,email:"kmiklavc@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')

suffl = User.create(kerberos_login:"dsuffling",cvs_username:"dsuffling",cec_username:"dsufflin",display_name:"Dave Suffling",committer:true,email:"dsufflin@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')

samir = User.create(kerberos_login:"ssapra",cvs_username:"ssapra",cec_username:"ssapra",display_name:"Samir Sapra",committer:true,email:"ssapra@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')

judge = User.create(kerberos_login:"tjudge",cvs_username:"tjudge",cec_username:"tomjudge",display_name:"Tom Judge",committer:true,email:"tomjudge@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')


lin = User.create(kerberos_login:"klin",cvs_username:"klin",cec_username:"kevlin2",display_name:"Kevin Lin",committer:true,email:"kevlin2@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')

metz = User.create(kerberos_login:"rsteinmetz",cvs_username:"rsteinmetz",cec_username:"rsteinme",display_name:"Ryan Steinmetz",committer:true,email:"rsteinme@cisco.com",confirmed:true,password:'acpassword',password_confirmation:'acpassword')
metz.move_to_child_of(nigel)





User.all.each do |u|
  u.update_attributes(class_level: 0)
end

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
Company.create(name:"Cisco")
Customer.create(name:"Nick Herbert",email:"nherbert@cisco.com",company:Company.first)
Complaint.create(channel:"somechannel", status:"NEW", description:"THis needs a description",added_through:"Admin Portal",complaint_assigned_at:Time.now, customer:Customer.first)
ComplaintEntry.create(complaint:Complaint.first,subdomain:"www",domain:"snort.org",path:"/downloads",wbrs_score:2,status:"NEW",user:User.find(4))
Complaint.create(channel:"somechannel", status:"NEW", description:"Here is a description",added_through:"Admin Portal",complaint_assigned_at:Time.now, customer:Customer.first)
ComplaintEntry.create(complaint:Complaint.last,subdomain:"www",domain:"talosintelligence.com",path:nil, wbrs_score:8,status:"NEW",user:User.find(4))
ComplaintEntry.create(complaint:Complaint.last,subdomain:"www",domain:"hbo.com",path:nil, wbrs_score:4,status:"NEW",user:User.find(4))
ComplaintEntry.create(complaint:Complaint.first,subdomain:"www",domain:"sssscomic.com",path:nil, wbrs_score:4,status:"NEW",user:User.find(4))
