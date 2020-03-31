namespace 'AC.WebCat', (exports) ->

  categories1 = [
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
    'nact - Not Actionable',
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

  categories3 = {
    'adlt - Adult': 6,
    'adv - Advertisements': 27,
    'alc - Alcohol': 77,
    'art - Arts': 2,
    'astr - Astrology': 74,
    'auct - Auctions': 88,
    'busi - Business and Industry': 19,
    'chat - Chat and Instant Messaging': 40,
    'plag - Cheating and Plagiarism': 51,
    'cprn - Child Abuse Content': 64,
    'csec - Computer Security': 65,
    'comp - Computers and Internet': 3,
    'date - Dating': 55,
    'card - Digital Postcards': 82,
    'food - Dining and Drinking': 61,
    'diy - DIY Projects': 97,
    'dyn - Dynamic and Residential': 91,
    'edu - Education': 1,
    'ent - Entertainment': 93,
    'extr - Extreme': 75,
    'fash - Fashion': 76,
    'fts - File Transfer Services': 71,
    'filt - Filter Avoidance': 25,
    'fnnc - Finance': 15,
    'free - Freeware and Shareware': 68,
    'gamb - Gambling': 49,
    'game - Games': 7,
    'gov - Government and Law': 11,
    'hack - Hacking': 50,
    'hate - Hate Speech': 16,
    'hlth - Health and Nutrition': 9,
    'lol - Humor': 79,
    'hunt - Hunting': 98,
    'ilac - Illegal Activities': 22,
    'ildl - Illegal Downloads': 84,
    'drug - Illegal Drugs': 47,
    'infr - Infrastructure': 18,
    'voip - Internet Telephony': 67,
    'job - Job Search': 4,
    'ling - Lingerie and Swimsuits': 31,
    'lotr - Lotteries': 34,
    'mil - Military': 99,
    'cell - Mobile Phones': 70,
    'natr - Nature': 13,
    'news - News': 58,
    'ngo - Non-governmental Organisations': 87,
    'nsn - Non-sexual Nudity': 60,
    'nact - Not Actionable': 103,
    'comm - Online Communities': 24,
    'meet - Online Meetings': 100,
    'osb - Online Storage and Backup': 66,
    'trad - Online Trading': 28,
    'pem - Organisation Email': 85,
    'prnm - Paranormal': 101,
    'park - Parked Domains': 92,
    'p2p - Peer File Transfer': 56,
    'pers - Personal Sites': 81,
    'pvpn - Personal VPN': 102,
    'img - Photo Search and Images': 90,
    'pol - Politics': 83,
    'porn - Pornography': 54,
    'pnet - Professional Networking': 89,
    'rest - Real Estate': 45,
    'ref - Reference': 17,
    'rel - Religion': 86,
    'saas - SaaS and B2B': 80,
    'kids - Safe for Kids': 57,
    'sci - Science and Technology': 12,
    'srch - Search Engines and Portals': 20,
    'sxed - Sex Education': 52,
    'shop - Shopping': 5,
    'snet - Social Networking': 69,
    'socs - Social Science': 14,
    'scty - Society and Culture': 10,
    'swup - Software Updates': 53,
    'sprt - Sports and Recreations': 8,
    'aud - Streaming Audio': 73,
    'vid - Streaming Video': 72,
    'tob - Tobacco': 78,
    'trns - Transportation': 44,
    'trvl - Travel': 46,
    'weap - Weapons': 36,
    'whst - Web Hosting': 37,
    'tran - Web Page Translation': 63,
    'mail - Web-based Email': 38
  }



  exports.getAUPCategories = ->
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    $.ajax(
      url: "/escalations/api/v1/escalations/webcat/complaints/category_list"
      method: 'GET'
      headers: headers
      success: (response) ->
        return response
      error: (response) ->
        return response
    )


  exports.createSelectOptions = ->

    cats_promise = new Promise (resolve, reject) =>
      categories2 = AC.WebCat.getAUPCategories()
      if categories2
        resolve categories2  # resolve goes to .then() below

    cats_promise.then (result) =>
      categories2 = result
      options2 = []
      for x, y of categories2
        value_name = x.split(' - ')[1]
        code = x.split(' - ')[0]
        options2.push {category_id: y, category_name: value_name, category_code: code}
      return options2

  exports.getCategoryIds = (category_names) ->


    cats_promise = new Promise (resolve, reject) => 
      categories2 = AC.WebCat.getAUPCategories()
      if categories2
        resolve categories2

    cats_promise.then (result) =>
      categories2 = result
      category_ids = []

      for name in category_names
        for x, y of categories2
          value_name = x.split(' - ')[1]

          if name == value_name
            category_ids.push(y)

      return category_ids