namespace 'AC.WebCat', (exports) ->

  categories = [
    'adlt - Adult',
    'adv - Advertisements',
    'alc - Alcohol',
    'art - Arts',
    'astr - Astrology',
    'auct - Auctions',
    'busi - Business and Industry',
    'chat - Chat and Instant Messaging',
    'plag - Cheating and Plagiarism',
    'cprn - Child Abuse Content',
    'csec - Computer Security',
    'comp - Computers and Internet',
    'date - Dating',
    'card - Digital Postcards',
    'food - Dining and Drinking',
    'diy - DIY Projects',
    'dyn - Dynamic and Residential',
    'edu - Education',
    'ent - Entertainment',
    'extr - Extreme',
    'fash - Fashion',
    'fts - File Transfer Services',
    'filt - Filter Avoidance',
    'fnnc - Finance',
    'free - Freeware and Shareware',
    'gamb - Gambling',
    'game - Games',
    'gov - Government and Law',
    'hack - Hacking',
    'hate - Hate Speech',
    'hlth - Health and Nutrition',
    'lol - Humor',
    'hunt - Hunting',
    'ilac - Illegal Activities',
    'ildl - Illegal Downloads',
    'drug - Illegal Drugs',
    'infr - Infrastructure',
    'voip - Internet Telephony',
    'job - Job Search',
    'ling - Lingerie and Swimsuits',
    'lotr - Lotteries',
    'mil - Military',
    'cell - Mobile Phones',
    'natr - Nature',
    'news - News',
    'ngo - Non-governmental Organisations',
    'nsn - Non-sexual Nudity',
    'comm - Online Communities',
    'meet - Online Meetings',
    'osb - Online Storage and Backup',
    'trad - Online Trading',
    'pem - Organisation Email',
    'prnm - Paranormal',
    'park - Parked Domains',
    'p2p - Peer File Transfer',
    'pers - Personal Sites',
    'pvpn - Personal VPN',
    'img - Photo Search and Images',
    'pol - Politics',
    'porn - Pornography',
    'pnet - Professional Networking',
    'rest - Real Estate',
    'ref - Reference',
    'rel - Religion',
    'saas - SaaS and B2B',
    'kids - Safe for Kids',
    'sci - Science and Technology',
    'srch - Search Engines and Portals',
    'sxed - Sex Education',
    'shop - Shopping',
    'snet - Social Networking',
    'socs - Social Science',
    'scty - Society and Culture',
    'swup - Software Updates',
    'sprt - Sports and Recreations',
    'aud - Streaming Audio',
    'vid - Streaming Video',
    'tob - Tobacco',
    'trns - Transportation',
    'trvl - Travel',
    'weap - Weapons',
    'whst - Web Hosting',
    'tran - Web Page Translation',
    'mail - Web-based Email'
  ]

  exports.createSelectOptions = ->
    options = []
    for x in categories
      value_name = x.split(' - ')[1]
      options.push {value: value_name, text: x}
    return options