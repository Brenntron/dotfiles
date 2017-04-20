# Systems

This is document is for the systems 

## List of our Systems
*   Ruby on Rails Source
*   Appache Web server
*   Passenger
*   MySQL Database
*   AC API
*   Bugzilla
*   Subversion Rules Repo
*   Subversion Callback Web Service
*   Active MQ
*   Local (Rule) Test Worker
*   PCAP Test Worker
*   visruleparser.pl
*   cve2x.pl


### Ruby on Rails Source
Of course, our code.

### MySQL Database
We have a local mysql database.
*   host: localhost
*   database: analyst_console
*   user: root
*   password: yes

### AC API
We maintain a web service API to manipulate bug records and rule records in our database.

### Bugzilla
We call bugzilla to import bugs into our system.

### Subversion Rules Repo
We checkout and commit to the rules folder in subversion.
*   URL: /rules/trunk
*   Working Folder: $RAILS_ROOT/extras/snort

These will always be .rules files.
Specifically /rules/trunk/snort-rules/*.rules.
Later /rules/trunk/so-rules/*.rules.

Snort rules will be in $RAILS_ROOT/extras/working/snort-rules.
Later SO rules will be in $RAILS_ROOT/extras/working/so_rules.

**Production installation** will require an svn checkout of the *.rules files to the snort-rules and so_rules directories.

### Subversion Callback Web Service
We maintain a callback web service.
Whenever a rule is committed to subversion,
a post-commit hook will call our server at

    /rule_sync/rule_files

with the filename parameter set to a comma separated list of relative file paths,
either snort-rules/* or so_rules/*.

### Active MQ
ActiveMQ is used to queue jobs to do Local (Rule) Tests and PCAP Tests.

### visruleparser.pl
We get the source for a perl script visruleparser.pl from outside our development team.

###  cve2x.pl
???

