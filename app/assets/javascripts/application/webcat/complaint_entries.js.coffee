#set empty string header so it can be updated on document ready
headers = ''
wbrs_confidence = 0
wbrs_certainty = 0

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

update_wbrs_data = () ->
  $categories_table = $('#ce_categories_data_table')

  return unless $.fn.dataTable.isDataTable($categories_table)

  wbrs_data = $categories_table.DataTable().row(0).data()
  wbrs_data.wbrs_certainty = wbrs_certainty
  wbrs_data.wbrs_confidence = wbrs_confidence

  $('#ce_categories_data_table').DataTable().row(0).data(wbrs_data)

get_suggested_categories = (domain) ->
  $.ajax(
    url: '/escalations/api/v1/escalations/webrep/disputes/current_content_categories'
    method: 'POST'
    headers: headers
    data:
      'uri': [ domain ]
    success: (response) ->
      cat_names = []

      $(response.data).each ->
        if this[0].url == domain
          categories = this[0].categories

          if Object.keys(categories).length > 0
            jQuery.each categories, (id, category) ->
              cat_names.push(category.descr)

      cat_names = cat_names.join(', ')
      category_message = if cat_names.length > 0
                           "<p id='ce_suggested_categories'>#{cat_names}</p>"
                         else
                           "<p class='missing-data' id='ce_suggested_categories'>'No suggested categories available.'</p>"

      $('#ce_suggested_categories_wrapper').append(category_message)
    error: (errorResponse) ->
      std_api_error(errorResponse, "Suggested Categories for this Entry could not be retrieved.", reload: false)
  )

get_current_categories = (domain) ->
  $.ajax(
    url: '/escalations/api/v1/escalations/webcat/complaint_entries/retrieve_current_categories_by_url'
    method: 'POST'
    headers: headers
    data:
      'domain': domain
    success: (response) ->
      parsed_response = JSON.parse response
      { sds_category, sds_domain_category } = parsed_response
      data = [
        {
          source: 'WBRS',
          conf: wbrs_confidence,
          categories: '',
          certainty: wbrs_certainty
        },
        {
          source: 'SDS URI',
          conf: '',
          categories: sds_category,
          certainty: ''
        },
        {
          source: 'SDS Domain',
          conf: '',
          categories: sds_domain_category,
          certainty: ''
        }
      ]

      $('#ce_categories_data_table').DataTable(
        data: data
        ordering: false
        info: false
        paging: false
        searching: false
        stateSave: false
        columns: [
          {
            data: 'source'
          }
          {
            data: 'conf'
          }
          {
            data: 'categories'
          }
          {
            data: 'certainty'
          }
        ]
      )
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
      wbrs_score = recent_data.score
      rep = wbrs_display(wbrs_score)

      $('#ce_description_wrapper').append("<p id='ce_description'>#{description}</p>")
      $('#ce_wbrs_score_wrapper').append("<div><span class='webcat-research-svg icon-#{rep}'></span><p id='ce_wbrs_score'>#{wbrs_score}</p></div>")

      wbrs_certainty = recent_data.certainty
      wbrs_confidence = recent_data.confidence

      update_wbrs_data()

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
    get_current_categories(domain_title)
    get_suggested_categories(domain_title)
    get_whois_data(domain_title)
    get_domain_history(domain_title)
    get_entry_history(entry_id)
    get_xbrs_history(domain_title)
    get_related_history(domain_title)
