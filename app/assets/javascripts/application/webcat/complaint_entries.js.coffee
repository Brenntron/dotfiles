if !!~ window.location.pathname.indexOf '/escalations/webcat/complaint_entries/'
  #set empty string header so it can be updated on document ready
  headers = ''
  entry_id = 0

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
      onItemAdd: ->
        # User shouldn't be able to change cats in pending, but just in case
        unless entry_status == 'PENDING'
          store_entry_changes(entry_id, 'submit')

          if verifyMasterSubmit() == true
            $('.ce-submit-button').prop('disabled', false)
            window.prevent_close('true')
          else
            $('.ce-submit-button').prop('disabled', true)
            window.prevent_close()
      onItemRemove: ->
        unless entry_status == 'PENDING'
          store_entry_changes(entry_id, 'submit')

          if verifyMasterSubmit() == true
            $('.ce-submit-button').prop('disabled', false)
            window.prevent_close('true')
          else
            $('.ce-submit-button').prop('disabled', true)
            window.prevent_close()
    }

    # $('#edit_tags').on 'click', () ->
    #   $ce_tags = $('#ce_tags')
    #
    #   if $ce_tags.is(':visible')
    #     $ce_tags.hide()
    #     $('#ce_tags_select')[0].selectize.enable()
    #     $('.ce-tags-select').removeClass('hidden')
    #   else
    #     $('.ce-tags-select').addClass('hidden')
    #     $('#ce_tags_select')[0].selectize.disable()
    #     $ce_tags.show()

  window.set_complaint_entry_data = (category_data, ce_entry_status) ->
    ce_current_categories = if category_data? then category_data.split(', ') else []

    AC.WebCat.getAUPCategories()
      .then((response) ->
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
            onItemAdd: ->
              # User shouldn't be able to change cats in pending, but just in case
              unless entry_status == 'PENDING'
                store_entry_changes(entry_id, 'submit')

                if verifyMasterSubmit() == true
                  $('.ce-submit-button').prop('disabled', false)
                  window.prevent_close('true')
                else
                  $('.ce-submit-button').prop('disabled', true)
                  window.prevent_close()
            onItemRemove: ->
              unless entry_status == 'PENDING'
                store_entry_changes(entry_id, 'submit')

                if verifyMasterSubmit() == true
                  $('.ce-submit-button').prop('disabled', false)
                  window.prevent_close('true')
                else
                  $('.ce-submit-button').prop('disabled', true)
                  window.prevent_close()
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
            onItemAdd: ->
              # User shouldn't be able to change cats in pending, but just in case
              unless entry_status == 'PENDING'
                store_entry_changes(entry_id, 'submit')

                if verifyMasterSubmit() == true
                  $('.ce-submit-button').prop('disabled', false)
                  window.prevent_close('true')
                else
                  $('.ce-submit-button').prop('disabled', true)
                  window.prevent_close()
            onItemRemove: ->
              unless entry_status == 'PENDING'
                store_entry_changes(entry_id, 'submit')

                if verifyMasterSubmit() == true
                  $('.ce-submit-button').prop('disabled', false)
                  window.prevent_close('true')
                else
                  $('.ce-submit-button').prop('disabled', true)
                  window.prevent_close()
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

  window.webcat_complaint_drop_down = () ->
    # deselect all statuses
    $('.status-radio-wrapper').removeClass 'selected'
    $('.webcat-ticket-status-radio').prop 'checked', false

    # close comment dropdowns
    $('.webcat-non-resolution-submit-wrapper').removeClass 'selected'
    $('#show-ticket-resolution-submenu').hide()

    # select the current status in the drodpwon (NEW is not an option so that won't select anything)
    status = $('#show-edit-ticket-status-button').text().trim()
    radio = $(".webcat-ticket-status-radio[data-status='#{status}'] ")
    radio.prop("checked", true)
    wrapper = radio.parent()
    wrapper.addClass('selected')

  render_whois_table = (domain) ->
    whois_callback = (formattedData) ->
      $('#whois_loader').hide()
      $('#ce_whois_table').hide()
      $('#whois_data_container').append formattedData
    error_callback = () ->
      $('#whois_loader').hide()

    AC.WebCat.Whois.get_whois_data(domain, whois_callback, error_callback)

  get_current_categories = () ->
    error_callback = (errorResponse) ->
      std_api_error(errorResponse, "Current Categories for this Entry could not be retrieved.", reload: false)

    AC.WebCat.get_current_categories(entry_id, false, error_callback)

  get_domain_history = (domain) ->
    $.ajax(
      url: '/escalations/api/v1/escalations/webcat/complaint_entries/get_domain_history'
      method: 'GET'
      headers: headers
      data:
        'domain': domain
      success: (response) ->
        data = response.data

        # remove baseline domain entry
        data.splice(0, 1)

        $('#ce_domain_history_loader').hide()

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
              data: 'description'
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
        $('#ce_domain_history_loader').hide()
      )

  get_entry_history = () ->
    std_msg_ajax(
      url: '/escalations/api/v1/escalations/webcat/complaint_entries/history'
      method: 'POST'
      headers: headers
      data:
        'id': entry_id
      success: (response) ->
        parsed_response = $.parseJSON(response)

        if parsed_response.error
          std_msg_error(response.error, [])
          console.error(response)
          $('#ce_entry_history_loader').hide()
        else
          formatted_entry_history = parsed_response.entry_history.complaint_history.map((historical_data) ->
            formatted_history_data = {}
            formatted_history_data['time'] = historical_data[0]
            formatted_history_data['sortable_time'] = moment(historical_data[0], 'MMMM D, YYYY at HH:mm A')
            formatted_history_data['user'] = historical_data[1]['whodunnit']

            delete historical_data[1]['whodunnit']

            formatted_history_data['changes'] = historical_data[1]

            return formatted_history_data
          )

          $('#ce_entry_history_loader').hide()

          $('#ce_entry_history_table').DataTable
            data: formatted_entry_history
            dom: 'fi<"datatable-top-tools no-margin-datatable-top-tool"l>tipr'
            ordering: true
            order: [[ 3, 'desc' ]]
            info: false
            drawCallback: () ->
              # for longer descriptions let user toggle full vs truncated
              $('.truncated-description').on 'click', () ->
                toggle_truncation($(this))
            pageLength: 10
            searching: false
            stateSave: false
            columnDefs: [
              {
                targets: [ 0 ]
                orderData: 3
                width: '15%'
              }
              {
                targets: [ 1 ],
                width: '10%'
              }
              {
                targets: [ 2 ],
                width: '75%'
              }
            ]
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
                  changes = data.changes
                  detail_segments = []

                  for key, value of changes
                    # The second item in the value array is the updated value in the changeset. The first item is the original value.
                    updated_value = value[1]

                    continue unless updated_value

                    detail_span = if updated_value.length > 500
                                    truncated_detail = updated_value.substring(0, 500)
                                    "<span class='description-wrapper'>
                                      #{truncated_detail}
                                    </span>
                                    <span class='truncated-description'
                                          data-truncated='#{truncated_detail}'
                                          data-full='#{updated_value}'>
                                      &hellip;
                                    </span>"
                                  else
                                    "<span class='description-wrapper'>#{updated_value}</span>"

                    detail_segments.push("<span class='bold'>#{key}:</span> #{detail_span} <br>")

                  return detail_segments.join('')
              }
              {
                data: 'sortable_time'
                visible: false
              }
            ]
          $('#ce_entry_history_table')
      error: (response) ->
        std_msg_error(response.error, [])
        console.error(response)
        $('#ce_entry_history_loader').hide()
    )

  get_xbrs_history = (url) ->
    $.ajax(
      url: '/escalations/api/v1/escalations/webcat/complaint_entries/xbrs'
      method: 'POST'
      headers: headers
      data:
        'url': url
      success: (response) ->
        data = response.data

        if data.error?
          console.error(data.error)
          std_msg_error(data.error, [])
          $('#ce_xbrs_history_loader').hide()
        else
          for datum in data
            datum['sortable_time'] = moment(datum.time, 'MMMM D, YYYY at HH:mm A')

          $('#ce_xbrs_history_loader').hide()

          $('#ce_xbrs_history_table').DataTable({
            data: data
            dom: 'fi<"datatable-top-tools no-margin-datatable-top-tool"l>tipr'
            ordering: true
            order: [[ 6, 'desc' ]]
            info: false
            pageLength: 10
            searching: false
            stateSave: false
            columnDefs: [
              {
                targets: [ 0 ]
                orderData: 6
              }
            ]
            columns: [
              {
                data: 'time'
              }
              {
                data: 'score'
              }
              {
                data: 'v2'
              }
              {
                data: 'v3'
              }
              {
                data: 'threatCats'
              }
              {
                data: 'ruleHits'
              }
              {
                data: 'sortable_time'
                visible: false
              }
            ]
          })
      error: (error) ->
        console.error(error)
        std_msg_error(error, [])
        $('#ce_xbrs_history_loader').hide()
    )

  get_related_history = (domain) ->
    # TODO: implement this when the related history endpoint exists.
    $('#ce_related_history_loader').hide()
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

  check_for_customer_show_page_webcat = () ->
    submitter_type = $(".submitter-type-wrapper p").text().toLowerCase()
    is_customer = false

    if submitter_type == 'customer'
      is_customer = true

    is_customer

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
          show_message('error', "#{path} could not open due to low WBRS Scores.", false, '#alert_message')
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

  window.update_uri_input = (value, type) ->
    $input = $('.ce-ip-uri-input')
    $domain = $('#ce_ip_uri_domain')
    $subdomain = $('#ce_ip_uri_subdomain')
    $original = $('#ce_ip_uri_original')

    $input.val(value)

    if ['original uri', 'subdomain'].includes(type)
      $domain.prop('disabled', false)

      switch type
        when 'original uri'
          $original.prop('disabled', true)

          unless $('#ce_ip_uri_subdomain').attr('data-val') == ''
            $subdomain.prop('disabled', false)

          break
        when 'subdomain'
          $subdomain.prop('disabled', true)

          unless $('#ce_ip_uri_original').attr('data-val') == ''
            $original.prop('disabled', false)

          break
    else
      $domain.prop('disabled', true)

      unless $subdomain.attr('data-val') == ''
        $subdomain.prop('disabled', false)
      unless $original.attr('data-val') == ''
        $original.prop('disabled', false)

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
        cat_ids = null
        # slight differences in data sent
        { uri } = data.complaint_entry
        category_names = []
        comment = $('.ce-internal-comment-textarea').val()
        commit = ''
        resolution_msg = $('ce-customer-comment-textarea').val()

        # slight differences in data sent
        if status == 'PENDING'
          status = ''
          commit = $('input[name=resolution]:checked').val()
          # we are disabling the button if ignore is checked, but just in case
          if commit == 'ignore'
            return
        else
          status = $('input[name=resolution]:checked').val()

        if $('#ce_categories_select').val() != null
          cat_ids = $('#ce_categories_select').val().toString()

        $('#ce_categories_select').next('.selectize-control').find('.item').each ->
          category_names.push($(this).text())

        entry_data = {
          'id': entry_id,
          'prefix': uri,
          'categories': cat_ids,
          'category_names': category_names.toString(),
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
          remove_entry_from_changes(entry_id, 'review')
          process_review(entry_data)
        else
          remove_entry_from_changes(entry_id, 'submit')
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
          show_message('error', "Submittions failed: #{data.error}", false, '#alert_message')
        else
          show_message('success', 'Submitted. Refresh to see new results.', false, '#alert_message')
      error: (response) ->
        msg = response.resonseJSON.error

        std_msg_error("Error submitting entry", msg, reload: false)
        remove_entry_from_changes(data.entry_id, 'submit')
        console.error(msg)
    , this)

  # Sending individual reviewed (PENDING) entry info to the backend
  process_review = (entry_data) ->
    headers = { 'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val() }
    std_msg_ajax(
      url: '/escalations/api/v1/escalations/webcat/complaint_entries/update_pending'
      method: 'POST'
      headers: headers
      data: {
        data: [entry_data]
      }
      success: (response) ->
        show_message('success', 'Submitted. Refresh to see new results.', false, '#alert_message')
        remove_entry_from_changes(data.entry_id, 'submit')
      error: (response) ->
        msg = response.resonseJSON.error
        console.error(msg)
        std_msg_error("Error submitting reviewed entries", msg, reload: false)
    , this)

  window.reopen_complaint = () ->
    std_msg_ajax(
      url: '/escalations/api/v1/escalations/webcat/complaint_entries/reopen_complaint_entry'
      method: 'POST'
      data: { 'complaint_entry_id': entry_id }
      success: (response) ->
        $button = $('.ce-submit-button')

        $('#RE-OPENED').prop('checked', true)

        $('.resolution-radio-button').each ->
          $(this).prop('disabled', false)
        $('#ce_categories_select')[0].selectize.enable()
        $('.ce-input').prop('disabled', false)

        store_entry_changes(entry_id, 'submit')
        $button.attr('onclick', "submit_changes(#{entry_id});")
        $button.text('submit')
        $button.removeAttr('disabled')

      error: (response) ->
        console.error(response)
        std_msg_error(response,"", reload: false)
    )

  $ ->
    domain_title = $('#domain_title')[0].innerText.replace(/(\r\n|\n|\r)/gm, "") # remove newlines
    entry_id = Number($('#complaint_entry_id')[0].innerText)
    headers = 'Token': $('input[name="token"]').val(),'Xmlrpc-Token': $('input[name="xml_token"]').val()
    resolution = $('.ce-radio-group > .resolution-radio-button:checked').val()

    get_current_categories()
    get_entry_history()

    get_domain_history(domain_title)
    get_related_history(domain_title)
    render_whois_table(domain_title)
    get_xbrs_history(domain_title)

    get_resolution_templates(resolution, 'individual', [entry_id])

    # Show page resolution select
    $('.show-action .webcat-ticket-status-radio').click ->
      if $(this).is(':checked')
        wrapper = $(this).parent()
        $('.show-action .status-radio-wrapper').removeClass('selected')
        $(wrapper).addClass('selected')

      if $(this).attr('id') == 'RESOLVED'
        $('#show-ticket-resolution-submenu').show()
        stat_comment = $('#ticket-non-res-submit').find('.ticket-status-comment')
        $('#ticket-non-res-submit').hide()
        $(stat_comment).val('')
        # check first resolution checkbox (and Fixed-FP parent) if none checked after opening
        if !($("input.ticket-resolution-radio").is(':checked'))
          $('input#FIXED').prop('checked', true)
          is_customer = check_for_customer_show_page_webcat()
          populate_resolved_webcat_templates('Fixed - FP: Sudden Spike', is_customer)
      else
        $('#ticket-non-res-submit').show()
        res_comment = $('.resolution-comment-wrapper').find('.ticket-status-comment')
        $('.ticket-resolution-radio').prop('checked', false)
        $('#show-ticket-resolution-submenu').hide()
        $(res_comment[0]).val('')

      store_entry_changes(entry_id, 'submit')

    $(document).on 'change', '.resolution_radio_button, .ce-input', ->
      $('.ce-submit-button').prop('disabled', false)
      store_entry_changes(entry_id, 'submit')
