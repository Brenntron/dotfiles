module RulesHelper

  TOP_SERVICES = ['http', 'imap', 'pop3', 'ftp-data', 'smtp',
                  'dns', 'netbios-ssn', 'ssl', 'ftp', 'sunrpc']

  OTHER_SERVICES = ['dcerpc', 'mysql', 'telnet', 'snmp', 'irc',
                    'openvpn', 'sip', 'ntp', 'kerberos', 'ldap',
                    'rtsp', 'netbios-ns', 'java_rmi', 'dhcp', 'ircd',
                    'ssdp', 'netbios-dgm', 'vnc-server', 'ssh', 'printer',
                    'drda', 'rtmp', 'syslog', 'nntp', 'tftp',
                    'rdp', 'teamview', 'wins', 'netware', 'postgresql',
                    'ident', 'ldp', 'rtp', 'igmp', 'gopher']

  CLASSIFICATION = ActiveSupport::HashWithIndifferentAccess.new(
      :'not-suspicious'                 => 'Not Suspicious Traffic',
      :'unknown'                        => 'Unknown Traffic',
      :'bad-unknown'                    => 'Potentially Bad Traffic',
      :'attempted-recon'                => 'Attempted Information Leak',
      :'successful-recon-limited'       => 'Information Leak',
      :'successful-recon-largescale'    => 'Large Scale Information Leak',
      :'attempted-dos'                  => 'Attempted Denial of Service',
      :'successful-dos'                 => 'Denial of Service',
      :'attempted-user'                 => 'Attempted User Privilege Gain',
      :'unsuccessful-user'              => 'Unsuccessful User Privilege Gain',
      :'successful-user'                => 'Successful User Privilege Gain',
      :'attempted-admin'                => 'Attempted Administrator Privilege Gain',
      :'successful-admin'               => 'Successful Administrator Privilege Gain',
      :'rpc-portmap-decode'             => 'Decode of an RPC Query',
      :'shellcode-detect'               => 'Executable code was detected',
      :'string-detect'                  => 'A suspicious string was detected',
      :'suspicious-filename-detect'     => 'A suspicious filename was detected',
      :'suspicious-login'               => 'An attempted login using a suspicious username was detected',
      :'system-call-detect'             => 'A system call was detected',
      :'tcp-connection'                 => 'A TCP connection was detected',
      :'trojan-activity'                => 'A Network Trojan was detected',
      :'unusual-client-port-connection' => 'A client was using an unusual port',
      :'network-scan'                   => 'Detection of a Network Scan',
      :'denial-of-service'              => 'Detection of a Denial of Service Attack',
      :'non-standard-protocol'          => 'Detection of a non-standard protocol or event',
      :'protocol-command-decode'        => 'Generic Protocol Command Decode',
      :'web-application-activity'       => 'access to a potentially vulnerable web application',
      :'web-application-attack'         => 'Web Application Attack',
      :'misc-activity'                  => 'Misc activity',
      :'misc-attack'                    => 'Misc Attack',
      :'icmp-event'                     => 'Generic ICMP event',
      :'inappropriate-content'          => 'Inappropriate Content was Detected',
      :'policy-violation'               => 'Potential Corporate Privacy Violation',
      :'default-login-attempt'          => 'Attempt to login by a default username and password',
      :'sdf'                            => 'Senstive Data',
      :'file-format'                    => 'Known malicious file or file based exploit',
      :'malware-cnc'                    => 'Known malware command and control traffic',
      :'client-side-exploit'            => 'Known client side exploit attempt'
  )

  def get_summary(rule)
    if rule && rule.rule_doc && rule.rule_doc.summary.present?
      rule.rule_doc.summary
    else
      RuleDoc::DEFAULT_SUMMARY_TEXT
    end
  end

  def get_contributor(rule)
    if rule && rule.rule_doc && rule.rule_doc.contributors.present?
      rule.rule_doc.contributors
    else
      RuleDoc::DEFAULT_CONTRIBUTOR_TEXT
    end
  end

  def doc_status(rule)
    case
      when !rule.doc_complete?
        'X'
      when rule.doc_updated?
        '->'
      else
        ''
    end
  end
end
