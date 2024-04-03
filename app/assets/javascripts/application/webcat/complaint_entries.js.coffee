#set empty string header so it can be updated on document ready
headers = ''

get_whois_data = (domain) ->
  $.ajax(
    method: 'GET'
    url: '/escalations/api/v1/escalations/cloud_intel/whois/lookup'
    headers: headers
    data:
      name: domain
    success: (response) ->
      if response?
        parsed_data = WebCat.RepLookup.parseIcannData(response.data)

        for datum_key, datum_value of parsed_data
          switch datum_key
            when 'registrant organization' then $('#registrant_organization').append(datum_value)
            when 'registrant country' then $('#registrant_country').append(datum_value)
            when 'registrant state/province' then $('#registrant_state').append(datum_value)
            when 'nserver'
              for nserver in datum_value
                row = "<tr><td>#{nserver}</td></tr>"

                $('#ce_nserver_tbody').append(row)
      else
        message = "No available responses. The IP address may be unallocated or its whois server is unavailable."

        std_msg_error("Error retrieving WHOIS query.", [message])
    error: (response) ->
      if response?
        { responseJSON } = response

        if !responseJSON
          std_msg_error("Error retrieving WHOIS query.","")
        else
          std_msg_error("Error retrieving WHOIS query.", [responseJSON.message])

        return $.each(response.responseJSON, (key, value) ->
          console.error value
        )
  )

get_current_categories = (entry_id) ->
  $.ajax(
    url: '/escalations/api/v1/escalations/webcat/complaint_entries/retrieve_current_categories'
    method: 'POST'
    headers: headers
    data:
      'id': entry_id
    success: (response) ->
      { current_category_data : current_categories, sds_category, sds_domain_category } = JSON.parse(response)
      wbrs_table_rows = ""
      current_categories = if Object.keys(current_categories).length > 0
                             current_categories
                           else
                             {
                               "1.0": {
                                 "category_id": 2,
                                 "desc_long": "Galleries and exhibitions; artists and art; photography; literature and books; performing arts and theater; musicals; ballet; museums; design; architecture.  Cinema and television are classified as Entertainment.",
                                 "descr": "Arts",
                                 "mnem": "art",
                                 "is_active": true,
                                 "confidence": 1,
                                 "top_certainty": 1000,
                                 "certainties": [
                                   {
                                     "category_id": 2,
                                     "certainty": 1000,
                                     "source_mnemonic": "cipr_multi",
                                     "source_description": "Multicat Cisco/IronPort Rules"
                                   }
                                 ]
                               }
                             }
      if Object.keys(current_categories).length > 0
        $.each current_categories, (conf, current_category) ->
          # For $.each returning non-false is the same as a continue statement in a for loop
          return 'continue' unless current_category.is_active

          { confidence, mnem: mnemonic, top_certainty, certainties } = current_category
          wbrs_table_rows = ""

          if certainties?
            certainties.forEach (certainty) ->
              { certainty: source_certainty, source_description, source_mnemonic } = certainty

              wbrs_table_rows += "<tr>
                                     <td>
                                       #{source_certainty}
                                     </td>
                                     <td>
                                       #{source_mnemonic}
                                     </td>
                                     <td>
                                       #{source_description}
                                     </td>
                                   </tr>"
          else
            wbrs_table_rows += "<tr>
                                  <td>
                                    #{confidence}
                                  </td>
                                  <td>
                                    #{mnemonic}
                                  </td>
                                  <td>
                                    #{top_certainty}
                                  </td>
                                </tr>"

        $('#ce_wbrs_categories_table > tbody').append(wbrs_table_rows)
      if sds_category? || sds_domain_category?
        sds_table_row = "<td>#{sds_category}</td><td>#{sds_domain_category}</td>"

        $('#ce_sds_categories_table > tbody').append(sds_table_row)
    error: (errorResponse) ->
      std_api_error(errorResponse, "Current Categories for this Entry could not be retrieved.", reload: false)
  )

get_domain_history = (domain) ->
  $.ajax(
    url: '/escalations/api/v1/escalations/webcat/complaint_entries/get_domain_history'
    method: 'GET'
    headers: headers
    data:
      'domain': domain
    success: (response) ->
      data = response.data
      recent_data = data.at(-1)
      description = recent_data.description

      # remove baseline domain entry
      data.splice(0, 1)

      $('#ce_domain_history_table').DataTable
        data: data
        ordering: false
        info: false
        paging: false
        searching: false
        stateSave: false
        columns: [
          {
            data: 'action'
          }
          {
            data: 'confidence'
          }
          {
            data: 'time_of_action'
          }
          {
            data: 'user'
          }
          {
            data: null
            render: (data) ->
              { category } = data

              if category?
                return "<p>#{category}</p>"
              else
                return ''
          }
        ]
    error: (errorResponse) ->
      std_api_error(errorResponse, "Domain History for this Entry could not be retrieved.", reload: false)
    )

get_entry_history = (entry_id) ->
  std_msg_ajax(
    url: '/escalations/api/v1/escalations/webcat/complaint_entries/history'
    method: 'POST'
    headers: headers
    data:
      'id': entry_id
    success: (response) ->
      parsed_response = $.parseJSON(response)

      if parsed_response.error
        alert(response.error)
      else
        formatted_entry_history = parsed_response.entry_history.complaint_history.map((historical_data) ->
          formatted_history_data = {}
          formatted_history_data['time'] = historical_data[0]
          formatted_history_data['user'] = historical_data[1]['whodunnit']

          delete historical_data[1]['whodunnit']

          formatted_history_data['details'] = historical_data[1]

          return formatted_history_data
        )

        $('#ce_entry_history_table').DataTable
          data: formatted_entry_history
          ordering: false
          info: false
          paging: false
          searching: false
          stateSave: false
          columns: [
            {
              data: 'time'
            }
            {
              data: 'user'
            }
            {
              data: null
              render: (data) ->
                details = data.details
                detail_segments = []

                for key, value of details
                  detail_segments.push("<span class='bold'>#{key}</span>: #{value} <br>")

                return detail_segments.join('')
            }
          ]
        $('#ce_entry_history_table')
    error: (response) ->
  )

get_xbrs_history = (domain) ->
  $.ajax(
    url: "/escalations/api/v1/escalations/webcat/complaints/get_xbrs_domain_history"
    method: 'GET'
    headers: headers
    data:
      'domains': domain
    success: (response) ->
      data = JSON.parse response

      if data.error?
        std_msg_error(data.error, [])
      else
        domainKey = Object.keys(data)[0]

        for entry in data[domainKey]
          entry.domain = domainKey

          subdomain_array = domainKey.split('.')[0]
          entry.subdomain = if subdomain_array.length > 1 then subdomain_array[0] else ''

          # separate on first occurrence of '/' to capture the path
          path_array = domainKey.split(/\/(.*)/)
          entry.path = if path_array.length > 1 then path_array[1]  else ''

          entry.operation = if entry.operation? then entry.operation else ''

        data = data[domainKey]

        console.log 'xbrs history data: ', data

        $('#ce_xbrs_history_table').DataTable({
          data: data
          ordering: false
          info: false
          paging: false
          searching: false
          stateSave: false
          columns: [
            {
              data: null
              render: (data) ->
                if data.aups.length > 0
                  cats = $.unique(data.aups.map((aup) -> aup.cat)).toString().split(',').join(', ')
                  return "<p>#{cats}</p>"
                else
                  return "<p class='missing-data'>N/A</p>"
            }
            {
              data: 'time'
            }
            {
              data: 'subdomain'
            }
            {
              data: 'domain'
            }
            {
              data: 'path'
            }
            {
              data: 'operation'
            }
          ]
        })
    error: (error) ->
  )

get_related_history = (domain) ->
  # TODO: implement this when the related history endpoint exists.
  $('#ce_related_history_table').DataTable({
    data: {}
    ordering: false
    info: false
    paging: false
    searching: false
    stateSave: false
    columns: [
      {
        data: 'subdomain'
      }
      {
        data: 'domain'
      }
      {
        data: 'path'
      }
      {
        data: 'categories'
      }
      {
        data: 'user/source'
      }
      {
        data: 'last modified'
      }
    ]
  })

$ ->
  if !!~ window.location.pathname.indexOf '/escalations/webcat/complaint_entries/'
    headers = 'Token': $('input[name="token"]').val(),'Xmlrpc-Token': $('input[name="xml_token"]').val()
    resolution = $('.ce-radio-group > .resolution-radio-button:checked').val()
    entry_id = Number($('#complaint_entry_id')[0].innerText)
    domain_title = $('#domain_title')[0].innerText.replace(/(\r\n|\n|\r)/gm, "") # remove newlines

    get_resolution_templates(resolution, 'individual', [entry_id])
    get_current_categories(entry_id)
    get_whois_data(domain_title)
    get_domain_history(domain_title)
    get_entry_history(entry_id)
    get_xbrs_history(domain_title)
    get_related_history(domain_title)
