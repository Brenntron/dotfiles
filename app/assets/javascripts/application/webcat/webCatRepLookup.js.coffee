namespace 'WebCat.RepLookup', (exports) ->

  exports.getWhoisLookup = (query_entry) ->

    if sort_column == 'domain'
      sort_column = 'name'

    std_msg_ajax(
      method: 'GET'
      url: '/escalations/api/v1/escalations/cloud_intel/whois/lookup'
      data:
        name: query_entry
      success: (response) ->
        response
      error: (response) ->
        if response != null
          console.log response
          return $.each(response.responseJSON, (key, value) ->
            console.log value
          )
        return
    )

  exports.queryWhoIs = (entry_id, query_entry) ->
    successFunction = (result) ->
      if result != null
        whois = result.data
        if $("#whois_content").length
          whois_content = this
          $("#whois_content").html(whois)
          $('#whois_content').dialog('open')
        else
          whois_content = '<div id="whois_content" title="Lookup Information"></div>'
          $('body').append(whois_content)
          $('#whois_content').append(whois)
          $('#whois_content').dialog
            autoOpen: true
            minWidth: 600
            position: { my: "right bottom", at: "right bottom", of: window }
      else
        message = 'We can\'t find any results. Possibly IP address is unallocated or its whois server is not available.'
        $('#whois_content').append message

    errorFunction = (message) ->
      #loader.css('display', 'none')
      if undefined == message.responseJSON
        std_msg_error("Error retrieving WHOIS query.","")
      else
        std_msg_error("Error retrieving WHOIS query.",message.responseJSON.message)


    WebCat.RepLookup.getWhoisLookup(query_entry).then successFunction, errorFunction
    return
