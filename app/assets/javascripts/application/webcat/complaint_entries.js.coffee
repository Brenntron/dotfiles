#set empty string header so it can be updated on document ready
headers = ''
wbrs_confidence = 0
wbrs_certainty = 0

update_wbrs_data = () ->
  $categories_table = $('#ce-categories-data-table')

  return unless $.fn.dataTable.isDataTable($categories_table)

  wbrs_data = $categories_table.DataTable().row(0).data()
  wbrs_data.wbrs_certainty = wbrs_certainty
  wbrs_data.wbrs_confidence = wbrs_confidence

  $('#ce-categories-data-table').DataTable().row(0).data(wbrs_data)

window.get_suggested_categories = (domain) ->
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
      $('#ce-suggested-categories-wrapper').append("<p id='ce-suggested-categories'>#{cat_names}</p>")
    error: (errorResponse) ->
      std_api_error(errorResponse, "Suggested Categories for this Entry could not be retrieved.", reload: false)
  )

window.get_current_categories = (domain) ->
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
      console.log 'current categories data: ', data

      $('#ce-categories-data-table').DataTable(
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

window.get_ce_domain_history = (domain) ->
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

      $('#ce-description-wrapper').append("<p id='ce-description'>#{description}</p>")
      $('#ce-wbrs-score-wrapper').append("<div><span class='webcat-research-svg icon-#{rep}'></span><p id='ce-wbrs-score'>#{wbrs_score}</p></div>")

      wbrs_certainty = recent_data.certainty
      wbrs_confidence = recent_data.confidence

      update_wbrs_data()

      # remove baseline domain entry
      data.splice(0, 1)
      console.log 'domain history data: ', data

      $('#ce-domain-history-table').DataTable
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

window.get_ce_xbrs_history = (domain) ->
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

        $('#ce-xbrs-history-table').DataTable({
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

window.get_ce_related_history = (domain) ->
  # TODO: implement this when the related history endpoint exists.

$ ->
  headers = 'Token': $('input[name="token"]').val(),'Xmlrpc-Token': $('input[name="xml_token"]').val()
