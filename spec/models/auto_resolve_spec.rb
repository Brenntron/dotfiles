describe AutoResolve do
  describe 'auto conviction' do

    UmbrellaSecurityInfoResponse = Struct.new(:code, :body)
    UmbrellaVolumeResponse = Struct.new(:code, :body)
    UmbrellaScanResponse = Struct.new(:code, :body)


    umbrella_popular_good = UmbrellaSecurityInfoResponse.new
    umbrella_popular_good.code = 200
    umbrella_popular_good.body = "{\"dga_score\":0.0,\"perplexity\":0.18786756104373362,\"entropy\":1.9182958340544896,\"securerank2\":100.0,\"pagerank\":63.36242,\"asn_score\":-0.07587332170749107,\"prefix_score\":-0.02867604643567799,\"rip_score\":-0.12451293522019732,\"popularity\":100.0,\"fastflux\":false,\"geodiversity\":[[\"US\",0.3591],[\"BR\",0.1046],[\"IN\",0.0603],[\"CA\",0.0358],[\"GB\",0.0344],[\"EG\",0.0288],[\"TR\",0.0216],[\"VN\",0.0202],[\"IT\",0.02],[\"MX\",0.0169],[\"DE\",0.0162],[\"FR\",0.0152],[\"AU\",0.0138],[\"JP\",0.0129],[\"PH\",0.0126],[\"RU\",0.0113],[\"ES\",0.0106],[\"IR\",0.0098],[\"NL\",0.0085],[\"PL\",0.0085],[\"ID\",0.0072],[\"CN\",0.0071],[\"AR\",0.007],[\"MY\",0.007],[\"UA\",0.0068],[\"DZ\",0.0064],[\"CO\",0.0056],[\"EC\",0.0053],[\"ZA\",0.005],[\"PT\",0.0047],[\"SE\",0.0045],[\"SA\",0.0039],[\"TH\",0.0038],[\"BE\",0.0037],[\"SG\",0.0036],[\"CL\",0.0036],[\"VE\",0.0035],[\"DK\",0.0033],[\"PE\",0.0032],[\"MA\",0.0031],[\"IE\",0.0031],[\"IL\",0.0029],[\"YE\",0.0027],[\"CH\",0.0026],[\"RO\",0.0024],[\"HK\",0.0024],[\"GR\",0.0023],[\"CZ\",0.0023],[\"TW\",0.0021],[\"AE\",0.0021],[\"PK\",0.0021],[\"AT\",0.002],[\"NZ\",0.002],[\"HU\",0.002],[\"NO\",0.0019],[\"KZ\",0.0017],[\"??\",0.0016],[\"AF\",0.0016],[\"KR\",0.0016],[\"CR\",0.0015],[\"IQ\",0.0015],[\"BM\",0.0014],[\"UY\",0.0013],[\"SK\",0.0012],[\"DO\",0.0011],[\"TT\",0.001],[\"BG\",0.001],[\"BD\",0.001],[\"LK\",0.001],[\"BY\",9.0E-4],[\"TN\",9.0E-4],[\"NG\",9.0E-4],[\"FI\",8.0E-4],[\"PR\",8.0E-4],[\"SY\",8.0E-4],[\"RS\",8.0E-4],[\"JO\",8.0E-4],[\"GT\",7.0E-4],[\"BA\",7.0E-4],[\"BO\",7.0E-4],[\"LT\",7.0E-4],[\"KE\",7.0E-4],[\"LB\",7.0E-4],[\"UZ\",6.0E-4],[\"QA\",6.0E-4],[\"SD\",6.0E-4],[\"LY\",6.0E-4],[\"NP\",6.0E-4],[\"OM\",5.0E-4],[\"PA\",5.0E-4],[\"HN\",5.0E-4],[\"HR\",5.0E-4],[\"ET\",4.0E-4],[\"GH\",4.0E-4],[\"AZ\",4.0E-4],[\"PS\",4.0E-4],[\"AL\",4.0E-4],[\"PY\",4.0E-4],[\"SI\",4.0E-4],[\"BZ\",3.0E-4],[\"SV\",3.0E-4],[\"CI\",3.0E-4],[\"JM\",3.0E-4],[\"KW\",3.0E-4],[\"EE\",2.0E-4],[\"GE\",2.0E-4],[\"AO\",2.0E-4],[\"BW\",2.0E-4],[\"BH\",2.0E-4],[\"CY\",2.0E-4],[\"SN\",2.0E-4],[\"LV\",2.0E-4],[\"LU\",2.0E-4],[\"MK\",2.0E-4],[\"MD\",2.0E-4],[\"MU\",2.0E-4],[\"MM\",2.0E-4],[\"MT\",2.0E-4],[\"NA\",2.0E-4],[\"IS\",2.0E-4],[\"KH\",2.0E-4],[\"DJ\",1.0E-4],[\"UG\",1.0E-4],[\"TZ\",1.0E-4],[\"GY\",1.0E-4],[\"GU\",1.0E-4],[\"GP\",1.0E-4],[\"RE\",1.0E-4],[\"AM\",1.0E-4],[\"TG\",1.0E-4],[\"BS\",1.0E-4],[\"BB\",1.0E-4],[\"BN\",1.0E-4],[\"BJ\",1.0E-4],[\"CW\",1.0E-4],[\"CD\",1.0E-4],[\"CM\",1.0E-4],[\"ME\",1.0E-4],[\"MV\",1.0E-4],[\"MZ\",1.0E-4],[\"MO\",1.0E-4],[\"MQ\",1.0E-4],[\"NI\",1.0E-4],[\"NE\",1.0E-4],[\"HT\",1.0E-4],[\"ZM\",1.0E-4],[\"ZW\",1.0E-4],[\"JE\",1.0E-4],[\"KG\",1.0E-4],[\"KY\",1.0E-4],[\"LA\",1.0E-4]],\"geodiversity_normalized\":[[\"BM\",0.20375896159233017],[\"YE\",0.09244116857647527],[\"LY\",0.03906714839945628],[\"JP\",0.030247161175715482],[\"UY\",0.017327997941008564],[\"GP\",0.01611794734153928],[\"OM\",0.01584445948550431],[\"UZ\",0.012655753260989624],[\"ZA\",0.012459173513181756],[\"NA\",0.012353255907166424],[\"DJ\",0.012059048193487418],[\"ET\",0.011267448269447748],[\"NE\",0.011130948345478668],[\"TG\",0.011115586042923016],[\"MQ\",0.010917816571685718],[\"CD\",0.010133128017268738],[\"IR\",0.009554115786249174],[\"GY\",0.009020860272706092],[\"ZW\",0.008999440533249985],[\"JO\",0.008587359427940694],[\"CI\",0.008458906984088651],[\"EC\",0.008424890295545056],[\"ZM\",0.008062503221898677],[\"QA\",0.007927753403880314],[\"MA\",0.007834061862256707],[\"SD\",0.007603882043760343],[\"SA\",0.007515213996104046],[\"IL\",0.007413411654412088],[\"NP\",0.0073149722224984315],[\"LB\",0.006992890545058264],[\"PH\",0.006975493060458157],[\"TT\",0.006877277598164459],[\"MM\",0.00672071497838774],[\"NZ\",0.006606545844889045],[\"AU\",0.006420955278274985],[\"SN\",0.005953888649969115],[\"GU\",0.005444608289488192],[\"PY\",0.005383647601754953],[\"BJ\",0.005373769349274668],[\"AM\",0.005345902883036986],[\"ME\",0.0051186887386536865],[\"IN\",0.005105527493742024],[\"LK\",0.005030075492148507],[\"BZ\",0.005025008344752182],[\"MU\",0.004938319913989788],[\"SG\",0.004904747993133913],[\"BH\",0.0048228971516750836],[\"KW\",0.004798889830765654],[\"EG\",0.004619340709342588],[\"BR\",0.004599468222743493],[\"AT\",0.004540410833015574],[\"GH\",0.004520279187084444],[\"HU\",0.0045116381878804275],[\"GE\",0.004497835567036878],[\"KE\",0.004491586986786001],[\"AE\",0.004484969188213879],[\"MT\",0.004350760132876633],[\"CO\",0.0043249507554260005],[\"PT\",0.0043077022802489266],[\"MD\",0.00428657404682345],[\"MZ\",0.004127445917671008],[\"TN\",0.0038572622599467817],[\"BD\",0.0038168055504889087],[\"PE\",0.003802764959897941],[\"GT\",0.0037809849520660166],[\"BO\",0.0037776439081732686],[\"RE\",0.0037705696686448544],[\"IS\",0.0037224273209199416],[\"CZ\",0.0037113614866476213],[\"SY\",0.003700792682319089],[\"MO\",0.0036077884818748684],[\"ES\",0.0035846536395296663],[\"MX\",0.0035827810660169703],[\"BW\",0.0035818656343892972],[\"CL\",0.003554849247808106],[\"DE\",0.003531979589799978],[\"GR\",0.003524631758147203],[\"IQ\",0.0034449203973161615],[\"HK\",0.0034358080966143713],[\"KG\",0.0032849747373204486],[\"JE\",0.003256006998903569],[\"HR\",0.0032409882444745662],[\"VE\",0.0032242854277104603],[\"SV\",0.0031234464489522467],[\"KR\",0.003049835621805406],[\"AF\",0.003036249637633131],[\"RO\",0.002997571804394868],[\"CH\",0.002979705709246971],[\"KZ\",0.0029703044415169007],[\"BE\",0.0029144025985733658],[\"MV\",0.0028368296972065285],[\"CR\",0.002776258271107416],[\"BB\",0.0027733942190858846],[\"AZ\",0.0027669033344557264],[\"LT\",0.0027166143334635736],[\"FR\",0.002678444359267468],[\"KY\",0.002611575887068207],[\"HN\",0.002598002229714169],[\"FI\",0.002592164727092915],[\"KH\",0.0025637233207784207],[\"SE\",0.002559739783173962],[\"HT\",0.0025571097550423963],[\"US\",0.0024955430120255106],[\"UG\",0.0024637310529903363],[\"DO\",0.002447096492825564],[\"PA\",0.0024279688323486756],[\"NL\",0.0023297394861225263],[\"EE\",0.002320455022564876],[\"IE\",0.0023053956285744802],[\"SI\",0.002304148999054233],[\"RS\",0.0022736983175376756],[\"PS\",0.002254662648206714],[\"TW\",0.002188166300297028],[\"TZ\",0.0021626386902226457],[\"AO\",0.0021310410867562417],[\"SK\",0.0019483833374038515],[\"CA\",0.0019178395715433397],[\"BY\",0.0019097823579033273],[\"MY\",0.0018519651455630832],[\"AL\",0.0018296669943540411],[\"AR\",0.001817066969918926],[\"GB\",0.001795893396906611],[\"CY\",0.0017925147482679188],[\"LA\",0.0017850531790498205],[\"TH\",0.0017688191331781708],[\"LV\",0.0017597982819709738],[\"PL\",0.0017570479059798101],[\"JM\",0.0017179364931356996],[\"NO\",0.0016701570504380208],[\"LU\",0.0015553395089509797],[\"IT\",0.0014440301311380746],[\"NG\",0.0013904044024260944],[\"UA\",0.0013449056884677643],[\"BA\",0.0012723618350648786],[\"MK\",0.0012578380153405292],[\"??\",0.00124098909424614],[\"BS\",0.0011379132764855538],[\"PR\",0.0011252738806954998],[\"VN\",0.0011050924675411258],[\"PK\",0.0010718205066905487],[\"RU\",0.0010681750932449397],[\"ID\",9.676335777603613E-4],[\"BG\",9.381747224025812E-4],[\"CN\",8.529633575726018E-4],[\"DK\",8.518203079498652E-4],[\"CW\",7.487854976037012E-4],[\"DZ\",6.800142031102517E-4],[\"TR\",5.295034276648443E-4],[\"CM\",3.475859949117745E-4],[\"BN\",3.384718139199583E-4],[\"NI\",2.8908538206708653E-4]],\"tld_geodiversity\":[],\"geoscore\":0.0,\"ks_test\":0.0,\"attack\":\"\",\"threat_type\":\"\",\"found\":true}"

    umbrella_popular_bad = UmbrellaSecurityInfoResponse.new
    umbrella_popular_bad.code = 200
    umbrella_popular_bad.body = "{\"dga_score\":0.0,\"perplexity\":0.1698321879522074,\"entropy\":3.4594316186372978,\"securerank2\":0.0,\"pagerank\":0.0,\"asn_score\":-0.014739406284196042,\"prefix_score\":-0.023982712069696013,\"rip_score\":-0.011198019721606252,\"popularity\":0.0,\"fastflux\":false,\"geodiversity\":[[\"US\",0.5],[\"BR\",0.5]],\"geodiversity_normalized\":[[\"BR\",0.863526213328589],[\"US\",0.13647378667141086]],\"tld_geodiversity\":[],\"geoscore\":0.0,\"ks_test\":0.0,\"attack\":\"\",\"threat_type\":\"\",\"found\":true}"


    umbrella_scan_bad = UmbrellaScanResponse.new
    umbrella_scan_bad.code = 200
    umbrella_scan_bad.body = "{\"1234computer.com\":{\"status\":-1,\"security_categories\":[\"66\"],\"content_categories\":[\"121\"]}}"

    umbrella_scan_good = UmbrellaScanResponse.new
    umbrella_scan_good.code = 200
    umbrella_scan_good.body = "{\"google.com\":{\"status\":1,\"security_categories\":[],\"content_categories\":[\"23\"]}}"

    let(:target_address) {'testing.com'}

    let(:reptool_whitelist_good) {
      {"google.com"=>{"source"=>"From whitelist_ips in PostgreSQL", "comment"=>"", "status"=>"ACTIVE", "ident"=>"", "_id"=>"57165ecb673ca5a24b1b66db", "hostname"=>"google.com", "expiration"=>"NEVER"}}
    }


    let(:virus_total_conviction_hash) {

          {"scan_id"=>"860a53b43369df83336dfea8bcc1604b3b49868174b4b8757f6ecce7d6c0e340-1594300951", "resource"=>"1234computer.com", "url"=>"http://1234computer.com/", "response_code"=>1, "scan_date"=>"2020-07-09 13:22:31", "permalink"=>"https://www.virustotal.com/gui/url/860a53b43369df83336dfea8bcc1604b3b49868174b4b8757f6ecce7d6c0e340/detection/u-860a53b43369df83336dfea8bcc1604b3b49868174b4b8757f6ecce7d6c0e340-1594300951", "verbose_msg"=>"Scan finished, scan information embedded in this object", "filescan_id"=>nil, "positives"=>3, "total"=>79, "scans"=>{"Botvrij.eu"=>{"detected"=>false, "result"=>"clean site"}, "Feodo Tracker"=>{"detected"=>false, "result"=>"clean site"}, "CLEAN MX"=>{"detected"=>false, "result"=>"clean site"}, "DNS8"=>{"detected"=>false, "result"=>"clean site"}, "NotMining"=>{"detected"=>false, "result"=>"unrated site"}, "VX Vault"=>{"detected"=>false, "result"=>"clean site"}, "securolytics"=>{"detected"=>false, "result"=>"clean site"}, "Tencent"=>{"detected"=>false, "result"=>"clean site"}, "MalwarePatrol"=>{"detected"=>false, "result"=>"clean site"}, "MalSilo"=>{"detected"=>false, "result"=>"clean site"}, "Comodo Valkyrie Verdict"=>{"detected"=>false, "result"=>"unrated site"}, "PhishLabs"=>{"detected"=>false, "result"=>"unrated site"}, "EmergingThreats"=>{"detected"=>false, "result"=>"clean site"}, "Sangfor"=>{"detected"=>false, "result"=>"clean site"}, "K7AntiVirus"=>{"detected"=>false, "result"=>"clean site"}, "Spam404"=>{"detected"=>false, "result"=>"clean site"}, "Virusdie External Site Scan"=>{"detected"=>false, "result"=>"clean site"}, "Artists Against 419"=>{"detected"=>false, "result"=>"clean site"}, "IPsum"=>{"detected"=>false, "result"=>"clean site"}, "Cyren"=>{"detected"=>false, "result"=>"clean site"}, "Quttera"=>{"detected"=>false, "result"=>"clean site"}, "AegisLab WebGuard"=>{"detected"=>false, "result"=>"clean site"}, "MalwareDomainList"=>{"detected"=>false, "result"=>"clean site", "detail"=>"http://www.malwaredomainlist.com/mdl.php?search=1234computer.com"}, "Lumu"=>{"detected"=>false, "result"=>"unrated site"}, "zvelo"=>{"detected"=>false, "result"=>"clean site"}, "Google Safebrowsing"=>{"detected"=>false, "result"=>"clean site"}, "Kaspersky"=>{"detected"=>true, "result"=>"phishing"}, "BitDefender"=>{"detected"=>false, "result"=>"clean site"}, "GreenSnow"=>{"detected"=>false, "result"=>"clean site"}, "G-Data"=>{"detected"=>false, "result"=>"clean site"}, "OpenPhish"=>{"detected"=>false, "result"=>"clean site"}, "Malware Domain Blocklist"=>{"detected"=>false, "result"=>"clean site"}, "AutoShun"=>{"detected"=>false, "result"=>"unrated site"}, "Trustwave"=>{"detected"=>false, "result"=>"clean site"}, "Web Security Guard"=>{"detected"=>false, "result"=>"clean site"}, "Cyan"=>{"detected"=>false, "result"=>"unrated site"}, "CyRadar"=>{"detected"=>false, "result"=>"clean site"}, "desenmascara.me"=>{"detected"=>false, "result"=>"clean site"}, "ADMINUSLabs"=>{"detected"=>false, "result"=>"clean site"}, "CINS Army"=>{"detected"=>false, "result"=>"clean site"}, "Dr.Web"=>{"detected"=>false, "result"=>"clean site"}, "AlienVault"=>{"detected"=>false, "result"=>"clean site"}, "Emsisoft"=>{"detected"=>false, "result"=>"clean site"}, "Spamhaus"=>{"detected"=>false, "result"=>"clean site"}, "malwares.com URL checker"=>{"detected"=>false, "result"=>"clean site"}, "Phishtank"=>{"detected"=>false, "result"=>"clean site"}, "EonScope"=>{"detected"=>false, "result"=>"clean site"}, "Malwared"=>{"detected"=>false, "result"=>"clean site"}, "Avira"=>{"detected"=>true, "result"=>"phishing site"}, "Cisco Talos IP Blacklist"=>{"detected"=>false, "result"=>"clean site"}, "CyberCrime"=>{"detected"=>false, "result"=>"clean site"}, "Antiy-AVL"=>{"detected"=>false, "result"=>"clean site"}, "Forcepoint ThreatSeeker"=>{"detected"=>true, "result"=>"phishing site"}, "SCUMWARE.org"=>{"detected"=>false, "result"=>"clean site"}, "Certego"=>{"detected"=>false, "result"=>"clean site"}, "Yandex Safebrowsing"=>{"detected"=>false, "result"=>"clean site", "detail"=>"http://yandex.com/infected?l10n=en&url=http://1234computer.com/"}, "ESET"=>{"detected"=>false, "result"=>"clean site"}, "Threatsourcing"=>{"detected"=>false, "result"=>"clean site"}, "URLhaus"=>{"detected"=>false, "result"=>"clean site"}, "SecureBrain"=>{"detected"=>false, "result"=>"clean site"}, "Nucleon"=>{"detected"=>false, "result"=>"clean site"}, "PREBYTES"=>{"detected"=>false, "result"=>"clean site"}, "Sophos"=>{"detected"=>false, "result"=>"unrated site"}, "Blueliv"=>{"detected"=>false, "result"=>"clean site"}, "BlockList"=>{"detected"=>false, "result"=>"clean site"}, "Netcraft"=>{"detected"=>false, "result"=>"unrated site"}, "CRDF"=>{"detected"=>false, "result"=>"clean site"}, "ThreatHive"=>{"detected"=>false, "result"=>"clean site"}, "BADWARE.INFO"=>{"detected"=>false, "result"=>"clean site"}, "FraudScore"=>{"detected"=>false, "result"=>"clean site"}, "Quick Heal"=>{"detected"=>false, "result"=>"clean site"}, "Rising"=>{"detected"=>false, "result"=>"clean site"}, "StopBadware"=>{"detected"=>false, "result"=>"unrated site"}, "Sucuri SiteCheck"=>{"detected"=>false, "result"=>"clean site"}, "Fortinet"=>{"detected"=>true, "result"=>"phishing site"}, "StopForumSpam"=>{"detected"=>false, "result"=>"clean site"}, "ZeroCERT"=>{"detected"=>false, "result"=>"clean site"}, "Baidu-International"=>{"detected"=>false, "result"=>"clean site"}, "Phishing Database"=>{"detected"=>false, "result"=>"clean site"}}}
    }

    let(:virus_total_clean_hash) {

      {"scan_id"=>"860a53b43369df83336dfea8bcc1604b3b49868174b4b8757f6ecce7d6c0e340-1594300951", "resource"=>"1234computer.com", "url"=>"http://1234computer.com/", "response_code"=>1, "scan_date"=>"2020-07-09 13:22:31", "permalink"=>"https://www.virustotal.com/gui/url/860a53b43369df83336dfea8bcc1604b3b49868174b4b8757f6ecce7d6c0e340/detection/u-860a53b43369df83336dfea8bcc1604b3b49868174b4b8757f6ecce7d6c0e340-1594300951", "verbose_msg"=>"Scan finished, scan information embedded in this object", "filescan_id"=>nil, "positives"=>0, "total"=>79, "scans"=>{"Botvrij.eu"=>{"detected"=>false, "result"=>"clean site"}, "Feodo Tracker"=>{"detected"=>false, "result"=>"clean site"}, "CLEAN MX"=>{"detected"=>false, "result"=>"clean site"}, "DNS8"=>{"detected"=>false, "result"=>"clean site"}, "NotMining"=>{"detected"=>false, "result"=>"unrated site"}, "VX Vault"=>{"detected"=>false, "result"=>"clean site"}, "securolytics"=>{"detected"=>false, "result"=>"clean site"}, "Tencent"=>{"detected"=>false, "result"=>"clean site"}, "MalwarePatrol"=>{"detected"=>false, "result"=>"clean site"}, "MalSilo"=>{"detected"=>false, "result"=>"clean site"}, "Comodo Valkyrie Verdict"=>{"detected"=>false, "result"=>"unrated site"}, "PhishLabs"=>{"detected"=>false, "result"=>"unrated site"}, "EmergingThreats"=>{"detected"=>false, "result"=>"clean site"}, "Sangfor"=>{"detected"=>false, "result"=>"clean site"}, "K7AntiVirus"=>{"detected"=>false, "result"=>"clean site"}, "Spam404"=>{"detected"=>false, "result"=>"clean site"}, "Virusdie External Site Scan"=>{"detected"=>false, "result"=>"clean site"}, "Artists Against 419"=>{"detected"=>false, "result"=>"clean site"}, "IPsum"=>{"detected"=>false, "result"=>"clean site"}, "Cyren"=>{"detected"=>false, "result"=>"clean site"}, "Quttera"=>{"detected"=>false, "result"=>"clean site"}, "AegisLab WebGuard"=>{"detected"=>false, "result"=>"clean site"}, "MalwareDomainList"=>{"detected"=>false, "result"=>"clean site", "detail"=>"http://www.malwaredomainlist.com/mdl.php?search=1234computer.com"}, "Lumu"=>{"detected"=>false, "result"=>"unrated site"}, "zvelo"=>{"detected"=>false, "result"=>"clean site"}, "Google Safebrowsing"=>{"detected"=>false, "result"=>"clean site"}, "Kaspersky"=>{"detected"=>false, "result"=>"phishing"}, "BitDefender"=>{"detected"=>false, "result"=>"clean site"}, "GreenSnow"=>{"detected"=>false, "result"=>"clean site"}, "G-Data"=>{"detected"=>false, "result"=>"clean site"}, "OpenPhish"=>{"detected"=>false, "result"=>"clean site"}, "Malware Domain Blocklist"=>{"detected"=>false, "result"=>"clean site"}, "AutoShun"=>{"detected"=>false, "result"=>"unrated site"}, "Trustwave"=>{"detected"=>false, "result"=>"clean site"}, "Web Security Guard"=>{"detected"=>false, "result"=>"clean site"}, "Cyan"=>{"detected"=>false, "result"=>"unrated site"}, "CyRadar"=>{"detected"=>false, "result"=>"clean site"}, "desenmascara.me"=>{"detected"=>false, "result"=>"clean site"}, "ADMINUSLabs"=>{"detected"=>false, "result"=>"clean site"}, "CINS Army"=>{"detected"=>false, "result"=>"clean site"}, "Dr.Web"=>{"detected"=>false, "result"=>"clean site"}, "AlienVault"=>{"detected"=>false, "result"=>"clean site"}, "Emsisoft"=>{"detected"=>false, "result"=>"clean site"}, "Spamhaus"=>{"detected"=>false, "result"=>"clean site"}, "malwares.com URL checker"=>{"detected"=>false, "result"=>"clean site"}, "Phishtank"=>{"detected"=>false, "result"=>"clean site"}, "EonScope"=>{"detected"=>false, "result"=>"clean site"}, "Malwared"=>{"detected"=>false, "result"=>"clean site"}, "Avira"=>{"detected"=>false, "result"=>"phishing site"}, "Cisco Talos IP Blacklist"=>{"detected"=>false, "result"=>"clean site"}, "CyberCrime"=>{"detected"=>false, "result"=>"clean site"}, "Antiy-AVL"=>{"detected"=>false, "result"=>"clean site"}, "Forcepoint ThreatSeeker"=>{"detected"=>false, "result"=>"phishing site"}, "SCUMWARE.org"=>{"detected"=>false, "result"=>"clean site"}, "Certego"=>{"detected"=>false, "result"=>"clean site"}, "Yandex Safebrowsing"=>{"detected"=>false, "result"=>"clean site", "detail"=>"http://yandex.com/infected?l10n=en&url=http://1234computer.com/"}, "ESET"=>{"detected"=>false, "result"=>"clean site"}, "Threatsourcing"=>{"detected"=>false, "result"=>"clean site"}, "URLhaus"=>{"detected"=>false, "result"=>"clean site"}, "SecureBrain"=>{"detected"=>false, "result"=>"clean site"}, "Nucleon"=>{"detected"=>false, "result"=>"clean site"}, "PREBYTES"=>{"detected"=>false, "result"=>"clean site"}, "Sophos"=>{"detected"=>false, "result"=>"unrated site"}, "Blueliv"=>{"detected"=>false, "result"=>"clean site"}, "BlockList"=>{"detected"=>false, "result"=>"clean site"}, "Netcraft"=>{"detected"=>false, "result"=>"unrated site"}, "CRDF"=>{"detected"=>false, "result"=>"clean site"}, "ThreatHive"=>{"detected"=>false, "result"=>"clean site"}, "BADWARE.INFO"=>{"detected"=>false, "result"=>"clean site"}, "FraudScore"=>{"detected"=>false, "result"=>"clean site"}, "Quick Heal"=>{"detected"=>false, "result"=>"clean site"}, "Rising"=>{"detected"=>false, "result"=>"clean site"}, "StopBadware"=>{"detected"=>false, "result"=>"unrated site"}, "Sucuri SiteCheck"=>{"detected"=>false, "result"=>"clean site"}, "Fortinet"=>{"detected"=>false, "result"=>"phishing site"}, "StopForumSpam"=>{"detected"=>false, "result"=>"clean site"}, "ZeroCERT"=>{"detected"=>false, "result"=>"clean site"}, "Baidu-International"=>{"detected"=>false, "result"=>"clean site"}, "Phishing Database"=>{"detected"=>false, "result"=>"clean site"}}}
    }

    let(:virus_total_bad_untrusted_hash) {

      {"scan_id"=>"860a53b43369df83336dfea8bcc1604b3b49868174b4b8757f6ecce7d6c0e340-1594300951", "resource"=>"1234computer.com", "url"=>"http://1234computer.com/", "response_code"=>1, "scan_date"=>"2020-07-09 13:22:31", "permalink"=>"https://www.virustotal.com/gui/url/860a53b43369df83336dfea8bcc1604b3b49868174b4b8757f6ecce7d6c0e340/detection/u-860a53b43369df83336dfea8bcc1604b3b49868174b4b8757f6ecce7d6c0e340-1594300951", "verbose_msg"=>"Scan finished, scan information embedded in this object", "filescan_id"=>nil, "positives"=>6, "total"=>79, "scans"=>{"Botvrij.eu"=>{"detected"=>true, "result"=>"clean site"}, "Feodo Tracker"=>{"detected"=>true, "result"=>"clean site"}, "CLEAN MX"=>{"detected"=>true, "result"=>"clean site"}, "DNS8"=>{"detected"=>true, "result"=>"clean site"}, "NotMining"=>{"detected"=>true, "result"=>"unrated site"}, "VX Vault"=>{"detected"=>true, "result"=>"clean site"}, "securolytics"=>{"detected"=>false, "result"=>"clean site"}, "Tencent"=>{"detected"=>false, "result"=>"clean site"}, "MalwarePatrol"=>{"detected"=>false, "result"=>"clean site"}, "MalSilo"=>{"detected"=>false, "result"=>"clean site"}, "Comodo Valkyrie Verdict"=>{"detected"=>false, "result"=>"unrated site"}, "PhishLabs"=>{"detected"=>false, "result"=>"unrated site"}, "EmergingThreats"=>{"detected"=>false, "result"=>"clean site"}, "Sangfor"=>{"detected"=>false, "result"=>"clean site"}, "K7AntiVirus"=>{"detected"=>false, "result"=>"clean site"}, "Spam404"=>{"detected"=>false, "result"=>"clean site"}, "Virusdie External Site Scan"=>{"detected"=>false, "result"=>"clean site"}, "Artists Against 419"=>{"detected"=>false, "result"=>"clean site"}, "IPsum"=>{"detected"=>false, "result"=>"clean site"}, "Cyren"=>{"detected"=>false, "result"=>"clean site"}, "Quttera"=>{"detected"=>false, "result"=>"clean site"}, "AegisLab WebGuard"=>{"detected"=>false, "result"=>"clean site"}, "MalwareDomainList"=>{"detected"=>false, "result"=>"clean site", "detail"=>"http://www.malwaredomainlist.com/mdl.php?search=1234computer.com"}, "Lumu"=>{"detected"=>false, "result"=>"unrated site"}, "zvelo"=>{"detected"=>false, "result"=>"clean site"}, "Google Safebrowsing"=>{"detected"=>false, "result"=>"clean site"}, "Kaspersky"=>{"detected"=>false, "result"=>"phishing"}, "BitDefender"=>{"detected"=>false, "result"=>"clean site"}, "GreenSnow"=>{"detected"=>false, "result"=>"clean site"}, "G-Data"=>{"detected"=>false, "result"=>"clean site"}, "OpenPhish"=>{"detected"=>false, "result"=>"clean site"}, "Malware Domain Blocklist"=>{"detected"=>false, "result"=>"clean site"}, "AutoShun"=>{"detected"=>false, "result"=>"unrated site"}, "Trustwave"=>{"detected"=>false, "result"=>"clean site"}, "Web Security Guard"=>{"detected"=>false, "result"=>"clean site"}, "Cyan"=>{"detected"=>false, "result"=>"unrated site"}, "CyRadar"=>{"detected"=>false, "result"=>"clean site"}, "desenmascara.me"=>{"detected"=>false, "result"=>"clean site"}, "ADMINUSLabs"=>{"detected"=>false, "result"=>"clean site"}, "CINS Army"=>{"detected"=>false, "result"=>"clean site"}, "Dr.Web"=>{"detected"=>false, "result"=>"clean site"}, "AlienVault"=>{"detected"=>false, "result"=>"clean site"}, "Emsisoft"=>{"detected"=>false, "result"=>"clean site"}, "Spamhaus"=>{"detected"=>false, "result"=>"clean site"}, "malwares.com URL checker"=>{"detected"=>false, "result"=>"clean site"}, "Phishtank"=>{"detected"=>false, "result"=>"clean site"}, "EonScope"=>{"detected"=>false, "result"=>"clean site"}, "Malwared"=>{"detected"=>false, "result"=>"clean site"}, "Avira"=>{"detected"=>false, "result"=>"phishing site"}, "Cisco Talos IP Blacklist"=>{"detected"=>false, "result"=>"clean site"}, "CyberCrime"=>{"detected"=>false, "result"=>"clean site"}, "Antiy-AVL"=>{"detected"=>false, "result"=>"clean site"}, "Forcepoint ThreatSeeker"=>{"detected"=>false, "result"=>"phishing site"}, "SCUMWARE.org"=>{"detected"=>false, "result"=>"clean site"}, "Certego"=>{"detected"=>false, "result"=>"clean site"}, "Yandex Safebrowsing"=>{"detected"=>false, "result"=>"clean site", "detail"=>"http://yandex.com/infected?l10n=en&url=http://1234computer.com/"}, "ESET"=>{"detected"=>false, "result"=>"clean site"}, "Threatsourcing"=>{"detected"=>false, "result"=>"clean site"}, "URLhaus"=>{"detected"=>false, "result"=>"clean site"}, "SecureBrain"=>{"detected"=>false, "result"=>"clean site"}, "Nucleon"=>{"detected"=>false, "result"=>"clean site"}, "PREBYTES"=>{"detected"=>false, "result"=>"clean site"}, "Sophos"=>{"detected"=>false, "result"=>"unrated site"}, "Blueliv"=>{"detected"=>false, "result"=>"clean site"}, "BlockList"=>{"detected"=>false, "result"=>"clean site"}, "Netcraft"=>{"detected"=>false, "result"=>"unrated site"}, "CRDF"=>{"detected"=>false, "result"=>"clean site"}, "ThreatHive"=>{"detected"=>false, "result"=>"clean site"}, "BADWARE.INFO"=>{"detected"=>false, "result"=>"clean site"}, "FraudScore"=>{"detected"=>false, "result"=>"clean site"}, "Quick Heal"=>{"detected"=>false, "result"=>"clean site"}, "Rising"=>{"detected"=>false, "result"=>"clean site"}, "StopBadware"=>{"detected"=>false, "result"=>"unrated site"}, "Sucuri SiteCheck"=>{"detected"=>false, "result"=>"clean site"}, "Fortinet"=>{"detected"=>false, "result"=>"phishing site"}, "StopForumSpam"=>{"detected"=>false, "result"=>"clean site"}, "ZeroCERT"=>{"detected"=>false, "result"=>"clean site"}, "Baidu-International"=>{"detected"=>false, "result"=>"clean site"}, "Phishing Database"=>{"detected"=>false, "result"=>"clean site"}}}
    }


    let(:umbrella_clear_json) {
      {
          target_address => {
              "status" => 1,
              "security_categories" => [],
              "content_categories" => ["25","32"]
          }
      }.to_json
    }
    before(:each) do
      @dispute_entry = DisputeEntry.new
      @dispute_entry.id = 1
      @dispute_entry.uri = target_address
      @dispute_entry.entry_type = "URI/DOMAIN"
      @dispute_entry.save
    end
    it 'should not auto resolve if there is an error' do

    end

    ################################PRE CONVICTION REQUIREMENT TESTING ################################################

    it 'should not auto resolve if umbrella popularity > 0' do

      expect(Umbrella::SecurityInfo).to receive(:query_info).with(address: target_address).and_return(umbrella_popular_good).at_least(:once)

      expect(AutoResolve.process_baseline_requirements([], @dispute_entry)).to eql ({:action=>:do_not_resolve, :log=>["Umbrella popularity rating: 100.0: result of pass: true"]})

      #integration test
      dispute_entry = AutoResolve.attempt_ai_conviction([], @dispute_entry)
      expect(dispute_entry.status).to eql(DisputeEntry::NEW)
      expect(dispute_entry.auto_resolve_log).to eql("Umbrella popularity rating: 100.0: result of pass: true")

    end

    # 2.  Complaints has at least one hit, VT and Umbrella acquit, produces NEW ticket.
    it 'should not auto resolve if has sds allow list rulehits' do

      expect(Umbrella::SecurityInfo).to receive(:query_info).with(address: target_address).and_return(umbrella_popular_bad).at_least(:once)

      expect(AutoResolve.process_baseline_requirements(['vsvd', 'wlh', 'plcbo'], @dispute_entry)).to eql ({:action=>:do_not_resolve, :log=>["Umbrella popularity rating: 0.0: result of pass: false", "allow list hits from SDS detected: vsvd,wlh"]})

      #integration test
      dispute_entry = AutoResolve.attempt_ai_conviction(['vsvd', 'wlh', 'plcbo'], @dispute_entry)
      expect(dispute_entry.status).to eql(DisputeEntry::NEW)
      expect(dispute_entry.auto_resolve_log).to eql("Umbrella popularity rating: 0.0: result of pass: false<br><br>allow list hits from SDS detected: vsvd,wlh")

    end

    # 3.  Complaints has no hits, VT convicts, Umbrella acquits, produces malicious status.
    it 'should not auto resolve if has reptool allow list record' do

      expect(Umbrella::SecurityInfo).to receive(:query_info).with(address: target_address).and_return(umbrella_popular_bad).at_least(:once)

      expect(RepApi::Whitelist).to receive(:get_whitelist_info).with({:entries => [target_address]}).and_return(reptool_whitelist_good).at_least(:once)

      expect(AutoResolve.process_baseline_requirements(['plcbo'], @dispute_entry)).to eql ({:action=>:do_not_resolve, :log=>["Umbrella popularity rating: 0.0: result of pass: false", "no sds rulehits detected against allow list", "ACTIVE entry on Reptool whitelist, manual review."]})

      #integration test
      dispute_entry = AutoResolve.attempt_ai_conviction(['plcbo'], @dispute_entry)
      expect(dispute_entry.status).to eql(DisputeEntry::NEW)
      expect(dispute_entry.auto_resolve_log).to eql("Umbrella popularity rating: 0.0: result of pass: false<br><br>no sds rulehits detected against allow list<br><br>ACTIVE entry on Reptool whitelist, manual review.")

    end






    ################################END PRE CONVICTION REQUIREMENT TESTING ################################################








    it 'should auto resolve if virustotal trusted hits are >= 1' do

      expect(Umbrella::SecurityInfo).to receive(:query_info).with(address: target_address).and_return(umbrella_popular_bad).at_least(:once)
      expect(Virustotal::Scan).to receive(:scan_hashes).with(address: target_address).and_return(virus_total_conviction_hash).at_least(:once)
      expect(RepApi::Whitelist).to receive(:get_whitelist_info).and_raise(RepApi::RepApiNotFoundError, "HTTP response 404").at_least(:once)


      response = AutoResolve.process_baseline_requirements(['plcbo'], @dispute_entry)

      expect(response).to eql ({:action=>:attempt_to_resolve, :log=>["Umbrella popularity rating: 0.0: result of pass: false", "no sds rulehits detected against allow list", "no entry with reptool whitelist, continuing."]})

      response = AutoResolve.process_conviction_requirements(@dispute_entry.hostlookup, response[:log])

      expect(response).to eql({:action=>:commit_malware, :log=>["Umbrella popularity rating: 0.0: result of pass: false", "no sds rulehits detected against allow list", "no entry with reptool whitelist, continuing.", "vt results: Kaspersky,Avira,Forcepoint ThreatSeeker,Fortinet\n", "trusted vt hits: 2\n"]})

      #integration test
      dispute_entry = AutoResolve.attempt_ai_conviction(['plcbo'], @dispute_entry)

      expect(dispute_entry.status).to eql(DisputeEntry::STATUS_RESOLVED)
      expect(dispute_entry.resolution).to eql(DisputeEntry::STATUS_RESOLVED_FIXED_FN)
      expect(dispute_entry.auto_resolve_log).to eql("Umbrella popularity rating: 0.0: result of pass: false<br><br>no sds rulehits detected against allow list<br><br>no entry with reptool whitelist, continuing.<br><br>vt results: Kaspersky,Avira,Forcepoint ThreatSeeker,Fortinet\n<br><br>trusted vt hits: 2\n")
    end


    it 'should auto resolve if umbrella rating is malicious' do
      expect(Umbrella::SecurityInfo).to receive(:query_info).with(address: target_address).and_return(umbrella_popular_bad).at_least(:once)
      expect(Virustotal::Scan).to receive(:scan_hashes).with(address: target_address).and_return(virus_total_clean_hash).at_least(:once)
      expect(RepApi::Whitelist).to receive(:get_whitelist_info).and_raise(RepApi::RepApiNotFoundError, "HTTP response 404").at_least(:once)
      expect(Umbrella::Scan).to receive(:scan_result).with(address: target_address).and_return(umbrella_scan_bad).at_least(:once)

      response = AutoResolve.process_baseline_requirements(['plcbo'], @dispute_entry)

      expect(response).to eql ({:action=>:attempt_to_resolve, :log=>["Umbrella popularity rating: 0.0: result of pass: false", "no sds rulehits detected against allow list", "no entry with reptool whitelist, continuing."]})

      response = AutoResolve.process_conviction_requirements(@dispute_entry.hostlookup, response[:log])

      expect(response).to eql({:action=>:commit_malware, :log=>["Umbrella popularity rating: 0.0: result of pass: false",
                                                                "no sds rulehits detected against allow list",
                                                                "no entry with reptool whitelist, continuing.",
                                                                "vt results: \n",
                                                                "trusted vt hits: 0\n",
                                                                "umbrella rating returned -1"]})
      #integration test
      dispute_entry = AutoResolve.attempt_ai_conviction(['plcbo'], @dispute_entry)

      expect(dispute_entry.status).to eql(DisputeEntry::STATUS_RESOLVED)
      expect(dispute_entry.resolution).to eql(DisputeEntry::STATUS_RESOLVED_FIXED_FN)
      expect(dispute_entry.auto_resolve_log).to eql("Umbrella popularity rating: 0.0: result of pass: false<br><br>no sds rulehits detected against allow list<br><br>no entry with reptool whitelist, continuing.<br><br>vt results: \n<br><br>trusted vt hits: 0\n<br><br>umbrella rating returned -1")

    end

    # 6.  Complaints has no hits, VT acquits, Umbrella check disabled produces NEW ticket.
    it 'should auto resolve if overall virustotal hits are > 5 ' do

      expect(Umbrella::SecurityInfo).to receive(:query_info).with(address: target_address).and_return(umbrella_popular_bad).at_least(:once)
      expect(Virustotal::Scan).to receive(:scan_hashes).with(address: target_address).and_return(virus_total_bad_untrusted_hash).at_least(:once)
      expect(RepApi::Whitelist).to receive(:get_whitelist_info).and_raise(RepApi::RepApiNotFoundError, "HTTP response 404").at_least(:once)
      expect(Umbrella::Scan).to receive(:scan_result).with(address: target_address).and_return(umbrella_scan_good).at_least(:once)

      response = AutoResolve.process_baseline_requirements(['plcbo'], @dispute_entry)

      expect(response).to eql ({:action=>:attempt_to_resolve, :log=>["Umbrella popularity rating: 0.0: result of pass: false", "no sds rulehits detected against allow list", "no entry with reptool whitelist, continuing."]})

      response = AutoResolve.process_conviction_requirements(@dispute_entry.hostlookup, response[:log])

      expect(response).to eql({:action=>:commit_malware, :log=>["Umbrella popularity rating: 0.0: result of pass: false",
                                                                "no sds rulehits detected against allow list",
                                                                "no entry with reptool whitelist, continuing.",
                                                                "vt results: Botvrij.eu,Feodo Tracker,CLEAN MX,DNS8,NotMining,VX Vault\n",
                                                                "trusted vt hits: 0\n",
                                                                "umbrella rating returned 1",
                                                                "total vt hits > 5, committing to reptool."]})
      #integration test
      dispute_entry = AutoResolve.attempt_ai_conviction(['plcbo'], @dispute_entry)
      expect(dispute_entry.status).to eql(DisputeEntry::STATUS_RESOLVED)
      expect(dispute_entry.resolution).to eql(DisputeEntry::STATUS_RESOLVED_FIXED_FN)
      expect(dispute_entry.auto_resolve_log).to eql("Umbrella popularity rating: 0.0: result of pass: false<br><br>no sds rulehits detected against allow list<br><br>no entry with reptool whitelist, continuing.<br><br>vt results: Botvrij.eu,Feodo Tracker,CLEAN MX,DNS8,NotMining,VX Vault\n<br><br>trusted vt hits: 0\n<br><br>umbrella rating returned 1<br><br>total vt hits > 5, committing to reptool.")





    end

    # 7.  Complaints has no hits, VT acquits, Umbrella check fails to connect produces NEW ticket.
    xit '' do

      expect(Virustotal::Scan).to receive(:scan_hashes).with(address: target_address).and_return(JSON.parse(virus_total_clear_json))
      allow(Umbrella::Scan).to receive(:scan_result).with(address: target_address).and_return(umbrella_conviction_response)

      auto_resolve = AutoResolve.create_from_payload('IP', target_address, [], dispute_entry)

      expect(auto_resolve.resolved?).to be_falsey
      expect(auto_resolve.internal_comment).to include('VT: -;')
    end

    # 8.  Complaints has no hits, VT check disabled, Umbrella convicts, produces malicious status.
    xit '' do

      allow(Virustotal::Scan).to receive(:scan_hashes).with(address: target_address).and_return(JSON.parse(virus_total_conviction_json))
      expect(Umbrella::Scan).to receive(:scan_result).with(address: target_address).and_return(umbrella_conviction_response)

      auto_resolve = AutoResolve.create_from_payload('IP', target_address, [], dispute_entry)

      expect(auto_resolve.resolved?).to be_truthy
      expect(auto_resolve.malicious?).to be_truthy
      expect(auto_resolve.internal_comment).to include('Umbrella: malicious domain.')
    end

    # 9.  Complaints has no hits, VT check fails to connect, Umbrella convicts, produces malicious status.
    xit '' do

      expect(Virustotal::Scan).to receive(:scan_hashes).with(address: target_address).and_raise(Curl::Err::ConnectionFailedError)
      expect(Umbrella::Scan).to receive(:scan_result).with(address: target_address).and_return(umbrella_conviction_response)

      auto_resolve = AutoResolve.create_from_payload('IP', target_address, [], dispute_entry)

      expect(auto_resolve.resolved?).to be_truthy
      expect(auto_resolve.malicious?).to be_truthy
      expect(auto_resolve.internal_comment).to include('Umbrella: malicious domain.')
    end

    # 10. Complaints has no hits, VT check disabled, Umbrella acquits, produces NEW ticket.
    xit '' do

      allow(Virustotal::Scan).to receive(:scan_hashes).with(address: target_address).and_return(JSON.parse(virus_total_conviction_json))
      expect(Umbrella::Scan).to receive(:scan_result).with(address: target_address).and_return(umbrella_conviction_response)

      auto_resolve = AutoResolve.create_from_payload('IP', target_address, [], dispute_entry)

      expect(auto_resolve.resolved?).to be_truthy
      expect(auto_resolve.malicious?).to be_truthy
      expect(auto_resolve.internal_comment).to include('Umbrella: malicious domain.')
    end

    # 11. Complaints has no hits, VT check fails to connect, Umbrella acquits, produces NEW ticket.
    xit '' do

      allow(Virustotal::Scan).to receive(:scan_hashes).with(address: target_address).and_raise(Curl::Err::ConnectionFailedError)
      expect(Umbrella::Scan).to receive(:scan_result).with(address: target_address).and_return(umbrella_conviction_response)

      auto_resolve = AutoResolve.create_from_payload('IP', target_address, [], dispute_entry)

      expect(auto_resolve.resolved?).to be_truthy
      expect(auto_resolve.malicious?).to be_truthy
    end

    # 12. Complaints has no hits, VT check disabled, Umbrella check disabled produces NEW ticket.
    xit '' do

      allow(Virustotal::Scan).to receive(:scan_hashes).with(address: target_address).and_return(JSON.parse(virus_total_conviction_json))
      allow(Umbrella::Scan).to receive(:scan_result).with(address: target_address).and_return(umbrella_conviction_response)

      auto_resolve = AutoResolve.create_from_payload('IP', target_address, [], dispute_entry)

      expect(auto_resolve.resolved?).to be_falsey
    end

    # 13. Complaints has no hits, VT check disabled, Umbrella check fails to connect produces NEW ticket.
    xit '' do

      allow(Virustotal::Scan).to receive(:scan_hashes).with(address: target_address).and_return(JSON.parse(virus_total_conviction_json))
      # expect(Umbrella::Scan).to receive(:scan_result).with(address: target_address).and_raise(Curl::Err::ConnectionFailedError)

      auto_resolve = AutoResolve.create_from_payload('IP', target_address, [], dispute_entry)

      expect(auto_resolve.resolved?).to be_falsey
    end

    # 14. Complaints has no hits, VT check fails to connect, Umbrella check disabled produces NEW ticket.
    xit '' do

      # expect(Virustotal::Scan).to receive(:scan_hashes).with(address: target_address).and_raise(Curl::Err::ConnectionFailedError)
      allow(Umbrella::Scan).to receive(:scan_result).with(address: target_address).and_return(umbrella_conviction_response)

      auto_resolve = AutoResolve.create_from_payload('IP', target_address, [], dispute_entry)

      expect(auto_resolve.resolved?).to be_falsey
    end

    # 15. Complaints has no hits, VT check fails to connect, Umbrella check fails to connect produces NEW ticket.
    xit '' do

      # expect(Virustotal::Scan).to receive(:scan_hashes).with(address: target_address).and_raise(Curl::Err::ConnectionFailedError)
      allow(Umbrella::Scan).to receive(:scan_result).with(address: target_address).and_raise(Curl::Err::ConnectionFailedError)

      auto_resolve = AutoResolve.create_from_payload('IP', target_address, [], dispute_entry)

      expect(auto_resolve.resolved?).to be_falsey
    end

  end
end
