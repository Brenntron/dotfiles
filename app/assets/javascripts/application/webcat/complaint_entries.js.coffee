if !!~ window.location.pathname.indexOf '/escalations/webcat/complaint_entries/'
  #set empty string header so it can be updated on document ready
  headers = ''
  entry_id = 0

  window.set_headers = () ->
    headers = 'Token': $('input[name="token"]').val(),'Xmlrpc-Token': $('input[name="xml_token"]').val()

  window.set_entry_id = () ->
    entry_id = Number($('#complaint_entry_id')[0].innerText)

  window.set_tags = (tags) ->
    split_tags = tags.split(', ')
    createTagOptions = ->
      tags = $('#complaint_tag_list')[0]
      if tags
        tag_list = tags.value
        array = tag_list.split(',')
        options = []
        for x in array
          options.push { name: x }
        return options

    $('#ce_tags_select').selectize {
      persist: false,
      create: (input) ->
        { name: input }
      maxItems: null,
      closeAfterSelect: false,
      valueField: 'name'
      labelField: 'name'
      searchField: 'name'
      options: createTagOptions(),
      items: split_tags,
    }

    $('#edit_tags').on 'click', () ->
      $ce_tags = $('#ce_tags')

      if $ce_tags.is(':visible')
        $ce_tags.hide()
        $('#ce_tags_select')[0].selectize.enable()
        $('.ce-tags-select').removeClass('hidden')
      else
        $('.ce-tags-select').addClass('hidden')
        $('#ce_tags_select')[0].selectize.disable()
        $ce_tags.show()

  window.set_complaint_entry_data = (category_data, ce_entry_status) ->
    ce_current_categories = if category_data? then category_data.split(', ') else []

    $.ajax(
      url: "/escalations/api/v1/escalations/webcat/complaints/category_list"
      method: 'GET'
      headers: headers
      success: (response) ->
        all_categories = response
        category_ids = []
        cat_options = []
        cleaned_cats = []

        if ce_current_categories
          cleaned_cats = ce_current_categories
          #splice together 'Conventions, Conferences and Trade Shows' due to extra comma
          if ce_current_categories.includes('Conferences and Trade Shows')
            $(cleaned_cats).each (i, category) ->
              if category == 'Conventions'
                cleaned_cats.splice(i, 1)
              else if category == ' Conferences and Trade Shows'
                i2 = i - 1
                cleaned_cats.splice(i2, 1, 'Conventions, Conferences and Trade Shows')

        for key, value of all_categories
          cat_code = key.split(' - ')[1]
          value_name = key.split(' - ')[0]
          cat_options.push({ category_id: value, category_name: value_name, category_code: cat_code })

        # find the category ids that match the current cats on the entry
        for name in cleaned_cats
          for x, y of all_categories
            value_name = x.split(' - ')[0]
            if name.trim() == value_name
              category_ids.push(y)

        if ce_entry_status == 'COMPLETED'
          # need to initialize the selectize function but disable it here if entry is completed
          $completed_selectize = $('#ce_categories_select').selectize {
            persist: true,
            create: false,
            maxItems: 5,
            closeAfterSelect: true,
            valueField: 'category_id',
            labelField: 'category_name',
            searchField: ['category_name', 'category_code'],
            options: cat_options,
            items: category_ids,
          }
          select_complete = $completed_selectize[0].selectize
          select_complete.disable()
        else
          $('#ce_categories_select').selectize {
            persist: false,
            create: false,
            maxItems: 5,
            closeAfterSelect: true,
            valueField: 'category_id',
            labelField: 'category_name',
            searchField: ['category_name', 'category_code'],
            options: cat_options,
            items: category_ids,
            score: (input) ->
              #  Adding some customization for autofill
              #  restricting on certain cats to avoid accidental categorization
              #  (replaces selectize's built-in `getScoreFunction()` with our own)
              (item) ->
                if item.category_code == 'cprn' ||
                  item.category_code == 'xpol' ||
                  item.category_code == 'xita' ||
                  item.category_code == 'xgbr' ||
                  item.category_code == 'xdeu' ||
                  item.category_code == 'piah'
                    item.category_code == input ? 1 : 0
                else if item.category_name.toLowerCase().startsWith(input.toLowerCase())
                  1
                else if item.category_name.toLowerCase().includes(input.toLowerCase()) ||
                  item.category_code.toLowerCase().includes(input.toLowerCase())
                    0.9
                else
                  0
          }
        )


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
          ordering: true
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
        console.error(errorResponse)
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
            ordering: true
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
          object_keys = Object.keys(data)

          data = if object_keys.length > 0
                   domainKey = Object.keys(data)[0]

                   for entry in data[domainKey]
                     entry.domain = domainKey

                     subdomain_array = domainKey.split('.')[0]
                     entry.subdomain = if subdomain_array.length > 1 then subdomain_array[0] else ''

                     # separate on first occurrence of '/' to capture the path
                     path_array = domainKey.split(/\/(.*)/)
                     entry.path = if path_array.length > 1 then path_array[1]  else ''

                     entry.operation = if entry.operation? then entry.operation else ''

                   data[domainKey]
                 else
                   []

          $('#ce_xbrs_history_table').DataTable({
            data: data
            ordering: true
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
      ordering: true
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

  window.open_ip_uri = () ->
    std_msg_ajax(
      method: 'POST'
      url: '/escalations/api/v1/escalations/webcat/complaints/view_complaint'
      data:
        complaint_entry_id: entry_id
      success: (response) ->
        data = $.parseJSON(response).data
        { viewable, uri, wbrs_score, ip_address } = data.complaint_entry
        ipv4_regex = /^(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]\d|\d)(?:\.(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]\d|\d)){3}$/gm
        path = ''

        unless ip_address?
          path = "http://#{uri}"
        else if ipv4_regex.test(selected_row.ip_address)
          # Because IPv6 includes colons an IPv6 must be wrapped in square brackets if it's used as a hostname.
          path = "http://#{ip_address}"
        else
          path = "http://[#{ip_address}]"

        if parseInt(wbrs_score) <= -6
          show_message('error', "#{path} could not open due to low WBRS Scores.")
        else if viewable
          window.open(path, '_blank')
        else
          show_message('error', 'Complaint Address is not viewable.', false, '#alert_message')
    )

  window.google_it = () ->
    std_msg_ajax(
      method: 'POST'
      url: '/escalations/api/v1/escalations/webcat/complaints/view_complaint'
      data:
        complaint_entry_id: entry_id
      success: (response) ->
        data = $.parseJSON(response).data
        { uri, ip_address } = data.complaint_entry
        path = ''

        unless ip_address?
          path = uri
        else
          path = ip_address

        window.open("https://www.google.com/search?q=#{path}", '_blank')
    )

  window.submit_show_page_changes = (entry_id) ->
    std_msg_ajax(
      method: 'POST'
      url: '/escalations/api/v1/escalations/webcat/complaints/view_complaint'
      data:
        complaint_entry_id: entry_id
      success: (response) ->
        data = $.parseJSON(response).data
        { curr_status: status } = data.complaint
        { uri } = data.complaint_entry

        # slight differences in data sent
        if curr_status == 'PENDING'
          status = ''
          commit = $('input[name=resolution]:checked').val()
          # we are disabling the button if ignore is checked, but just in case
          if commit == 'ignore'
            return
        else
          commit = ''
          status = $('input[name=resolution]:checked').val()

        comment = $('.ce-internal-comment-textarea').val()
        resolution_msg = $('ce-customer-comment-textarea').val()

        if $('#ce_categories_select-selectized').val() != null
          cat_ids = $('#ce_categories_select-selectized').val().toString()
        else
          cat_ids = null
        category_name = $('#ce_categories_select-selectized').next('.selectize-control').find('.item')
        category_names = []
        category_name.each ->
          category_names.push($(this).text())
        category_names = category_names.toString()

        entry_data = {
          'id': entry_id,
          'prefix': uri,
          'categories': cat_ids,
          'category_names': category_names,
          'status': status,
          'commit': commit,
          'comment': comment,
          'resolution_comment': resolution_msg,
          'uri_as_categorized': uri
        }

        # check data here before submitting
        # If resolution is set to fixed, make sure it has categories applied
        if entry_data.categories == null && entry_data.status == "FIXED"
          std_msg_error("Must include at least one category.","", reload: false)
          return
        else if entry_data.status == "INVALID" && entry_data.categories != null
          std_msg_error("Cannot include categories with an INVALID resolution.", "", reload: false)
          return

        # need number of cols for replacement temp col
        visible_cols = $('#complaints-index thead th').length

        if curr_status == 'PENDING'
          process_review(entry_data)
        else
          process_entry(entry_data)
          # submit for real
    )

  # Sending individual entry info to the backend
  process_entry = (entry_data) ->
    headers = { 'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val() }
    std_msg_ajax(
      url: '/escalations/api/v1/escalations/webcat/complaint_entries/update'
      method: 'POST'
      headers: headers
      data: entry_data
      success: (response) ->
        data = $.parseJSON(response)
        if data.error?
          err_msg = data.error
          msg = $('#' + data.entry_id + ' .temp-msg')
          $(msg).text('Submission failed: ' + err_msg)
        else
          msg = $('#' + data.entry_id + ' .temp-msg')
          $(msg).text('Submitted. Refresh to see new results.')
          $(msg).addClass('submitted-row')
          remove_entry_from_changes(data.entry_id, 'submit')
      error: (response) ->
        msg = response.resonseJSON.error
        std_msg_error("Error submitting entry", msg, reload: false)
    , this)


  # Sending individual reviewed (PENDING) entry info to the backend
  process_review = (entry_data) ->
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    std_msg_ajax(
      url: '/escalations/api/v1/escalations/webcat/complaint_entries/update_pending'
      method: 'POST'
      headers: headers
      data: {
        data: [entry_data]
      }
      success: (response) ->
#      debugger
        data = $.parseJSON(response)
        msg = $('#' + data.entry_id + ' .temp-msg')
        $(msg).text('Submitted. Refresh to see new results.')
        $(msg).addClass('submitted-row')
        remove_entry_from_changes(data.entry_id, 'review')
      error: (response) ->
        msg = response.resonseJSON.error
        std_msg_error("Error submitting reviewed entries", msg, reload: false)
    , this)

  $ ->
    if !!~ window.location.pathname.indexOf '/escalations/webcat/complaint_entries/'
      resolution = $('.ce-radio-group > .resolution-radio-button:checked').val()
      domain_title = $('#domain_title')[0].innerText.replace(/(\r\n|\n|\r)/gm, "") # remove newlines

      get_resolution_templates(resolution, 'individual', [entry_id])
      get_current_categories(entry_id)
      get_whois_data(domain_title)
      get_domain_history(domain_title)
      get_entry_history(entry_id)
      get_xbrs_history(domain_title)
      get_related_history(domain_title)
