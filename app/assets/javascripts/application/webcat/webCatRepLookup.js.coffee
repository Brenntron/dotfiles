namespace 'WebCat.RepLookup', (exports) ->

  exports.getLookup = (query_url, query_entry, offset = 0, sort_column = 'ip', sort_type = 'asc') ->

    if sort_column == 'domain'
      sort_column = 'name'

    data_lookup =
      'query': query_url
      'query_entry': query_entry
      'offset': offset
      'order': sort_column + ' ' + sort_type


    $.ajax {
      url: '/escalations/sb_api/query_lookup'
      method: 'GET'
      crossDomain: true
      dataType: 'json'
      data: data_lookup
      success: (response) ->
        response
      error: (response) ->
        if response != null
          console.log response
          return $.each(response.responseJSON, (key, value) ->
            console.log value
          )
        return

    }, this

  exports.queryWhoIs = (query_entry) ->
    successFunction = (result) ->
      $('#loader-modal').modal 'hide'
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
      $('#loader-modal').modal 'hide'
      std_msg_error("Error retrieving WHOIS query.","")

    $('#loader-modal').modal({
      backdrop: 'static',
      keyboard: false
    })
    WebCat.RepLookup.getLookup('/api/v2/whois/', query_entry).then successFunction, errorFunction
    return
