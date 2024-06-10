if !!~ window.location.pathname.indexOf '/escalations/webcat/complaint_entries/'
  #set empty string header so it can be updated on document ready
  current_user_id = 0
  entry_id = 0
  headers = ''
  initial_status = ''
  resolution_option = ''
  review_option = ''
  # We do not want unsubmitted changes to persist across page reloads
  # So we store themm in memory
  change_store = do () ->
    changes = []

    {
      add: (change) ->
        if changes.indexOf(change) < 0
          changes.push change
      category_changed: () ->
        changes.some (change) ->
          change.includes('category')
      getChanges: () ->
        changes
      hasChange: (change) ->
        change_index = changes.indexOf(change)

        return change_index > -1
      remove: (change) ->
        change_index = changes.indexOf(change)

        if change_index > -1
          changes.splice(change_index, 1)
    }

  verifySubmit = () ->
    if initial_status == 'PENDING'
      return true if ['commit', 'decline'].includes(review_option) && canReview()
    else
      submitted_ip_uri = $('.ce-ip-uri-input').val()

      # All resolution options, as well as the commit review option, requite a user comment
      # and a submittable ip or uri. If the tickets makes it to PENDING without a user comment
      # then it can only be declined.
      return false unless submitted_ip_uri

      # The fixed resolution requires a change to the category list and at least one category.
      can_submit = if resolution_option == 'FIXED' && change_store.category_changed() && $('#ce_categories_select')[0].selectize.items.length > 0
                     true
                   else if ['UNCHANGED', 'INVALID'].includes(resolution_option) && change_store.getChanges().length == 0
                     true
                   else
                     false

      return can_submit

  canReview = () ->
    allow_self_review = $('#self_review')

    # #self_review only appears if the current user is the assignee.
    # If there is no #self_review, then the current user is a reviewer and can review.
    if allow_self_review.length > 0
      return allow_self_review.prop('checked')
    else
      true

  toggleSubmitButton = () ->
    can_submit = verifySubmit()
    $('.ce-submit-button').prop('disabled', !can_submit)

  window.set_tags = (tags, entry_status) ->
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
      onItemAdd: (value) ->
        change_store.add("tags: #{value}")

        can_submit = verifySubmit()

        $('.ce-submit-button').prop('disabled', !can_submit)
        window.prevent_close(can_submit.toString())
      onItemRemove: (value) ->
        change_store.remove("tags: #{value}")

        can_submit = verifySubmit()

        $('.ce-submit-button').prop('disabled', !can_submit)
        window.prevent_close(can_submit.toString())
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

  window.set_complaint_entry_data = (category_data, entry_status) ->
    ce_current_categories = if category_data? then category_data.split(',') else []
    selectize = null

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

        selectize = $('#ce_categories_select').selectize {
          persist: false,
          create: false,
          maxItems: 5,
          closeAfterSelect: true,
          valueField: 'category_id',
          labelField: 'category_name',
          searchField: ['category_name', 'category_code'],
          options: cat_options,
          items: category_ids,
          onItemAdd: (value) ->
            # User shouldn't be able to change cats in pending, but just in case
            unless entry_status == 'PENDING'
              if change_store.hasChange("removed category: #{value}")
                change_store.remove("removed category: #{value}")
              else
                change_store.add("category: #{value}")

              can_submit = verifySubmit()

              $('.ce-submit-button').prop('disabled', !can_submit)
              window.prevent_close(can_submit.toString())
          onItemRemove: (value) ->
            unless entry_status == 'PENDING'
              # Track adding categories and removing existing categories
              if change_store.hasChange("category: #{value}")
                change_store.remove("category: #{value}")
              else
                change_store.add("removed category: #{value}")

              can_submit = verifySubmit()

              $('.ce-submit-button').prop('disabled', !can_submit)
              window.prevent_close(can_submit.toString())
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

        selectize[0].selectize.disable() if entry_status == 'PENDING'
      )

  window.set_lookup = (lookup) ->
    get_ce_show_domain_history(lookup)
#    get_related_history(lookup)
    render_whois_table(lookup)
    get_ce_show_xbrs_history(lookup)

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

  window.take_single_webcat_complaint = (assignment_type) ->
    $.ajax(
      url: '/escalations/api/v1/escalations/webcat/complaint_entries/take_entry'
      method: 'POST'
      headers: headers
      data: 'complaint_entry_ids': [entry_id], 'assignment_type': assignment_type
      success: (response) ->
        json = $.parseJSON(response)
        if json.error
          if jQuery.type(json.error) == 'array'
            std_msg_error('Error Taking Entries', [json.error.join(' ')])
          else
            std_msg_error('Error Taking Entries', [json.error])
        else
          $status = $('.status-wrapper > .top-info-data')

          if assignment_type == 'assignee' && ['NEW', 'REOPENED'].includes($status.text())
            $status.text('ASSIGNED')

          $assignee_type = $("#complaint_#{assignment_type}")

          $assignee_type.text(json.name)
          $assignee_type.removeClass('missing-data')
          $("#webcat_take_ticket_#{assignment_type}").addClass('hidden')
          $("#webcat_return_ticket_#{assignment_type}").removeClass('hidden')
      error: (response) ->
        std_msg_error('Error Taking Entries', response.responseText)
    , this)

  window.return_single_webcat_complaint = (assignment_type) ->
    $.ajax(
      url: '/escalations/api/v1/escalations/webcat/complaint_entries/return_entry'
      method: 'POST'
      headers: headers
      data: 'complaint_entry_ids': [entry_id], 'assignment_type': assignment_type
      success: (response) ->
        json = $.parseJSON(response)
        if json.error
          if jQuery.type(json.error) != 'array'
            std_msg_error('Error Returning Entries', [json.error])
          else
            std_msg_error('Error Returning Entries', [json.error.join(' ')])
        else
          $status = $('.status-wrapper > .top-info-data')

          if assignment_type == 'assignee' && $status.text() == 'ASSIGNED'
            $status.text('NEW')

          $assignee_type = $("#complaint_#{assignment_type}")
          assignment_text = switch assignment_type
            when 'assignee' then 'Unassigned'
            when 'reviewer' then 'No Reviewer'
            when 'second_reviewer' then 'No 2nd Reviewer'

          $assignee_type.text(assignment_text)
          $assignee_type.addClass('missing-data')
          $("#webcat_take_ticket_#{assignment_type}").removeClass('hidden')
          $("#webcat_return_ticket_#{assignment_type}").addClass('hidden')
      error: (response) ->
        std_msg_error('Error Returning Entries', [response.responseText])
    , this)

  window.webcat_toolbar_show_change_assignee = (assignment_type) ->
    user_id = Number($("#change_target_#{assignment_type}").val())
    is_current_user = user_id == current_user_id
    data = {
      'complaint_entry_ids': [entry_id],
      'user_id': user_id,
      'assignment_type': assignment_type
    }

    std_msg_ajax(
      url: '/escalations/api/v1/escalations/webcat/complaint_entries/change_assignee'
      method: 'POST'
      headers: headers
      data: data
      dataType: 'json'
      success: (response) ->
        $("#show_change_#{assignment_type}_dropdown").dropdown('toggle')
        json = $.parseJSON(response)

        if json.error
          if JQuery.type(json.error) != 'array'
            std_msg_error('Error Assigning Entries', [json.error])
          else
            std_msg_error('Error Assigning Entries', [json.error.join(' ')])
        else
          $status = $('.status-wrapper > .top-info-data')

          if assignment_type == 'assignee' && ['NEW', 'REOPENED'].includes($status.text())
            $status.text('ASSIGNED')

          $assignee_type = $("#complaint_#{assignment_type}")

          $assignee_type.text(json.name)
          $assignee_type.removeClass('missing-data')
          $("#webcat_take_ticket_#{assignment_type}").addClass('hidden')

          if is_current_user
            $("#webcat_return_ticket_#{assignment_type}").removeClass('hidden')
          else
            $("#webcat_return_ticket_#{assignment_type}").addClass('hidden')
        error: (response) ->
          std_msg_error('Error Assigning Entries', [response.responseText])
    )

  render_whois_table = (domain) ->
    whois_callback = (formattedData) ->
      $('#whois_loader').hide()
      $('#ce_whois_table').hide()
      $('#whois_data_container').append formattedData
    error_callback = (response) ->
      $('#whois_loader').hide()
      $('#whois_data_container').append("<p class='missing-data'>No data available</p>")
      show_message('error', "Error retrieving WHOIS query. #{response.responseJSON.message}", false, '#whois_loader')

    AC.WebCat.Whois.get_whois_data(domain, whois_callback, error_callback)

  get_current_categories = () ->
    error_callback = (errorResponse) ->
      std_api_error(errorResponse, "Current Categories for this Entry could not be retrieved.", reload: false)

    AC.WebCat.get_current_categories(entry_id, false, error_callback)

  get_ce_show_domain_history = (domain) ->
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
          dom: '<"datatable-top-tools no-margin-datatable-top-tool"l>t<ip>'
          ordering: true
          order: [[ 3, 'desc' ]]
          searching: false
          stateSave: false
          pageLength: 10
          pagingType: 'simple_numbers'
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
              data: 'category'
            }
          ]
      error: (errorResponse) ->
        console.error(errorResponse)
        std_api_error(errorResponse, "Domain History for this Entry could not be retrieved.", reload: false)
        $('#ce_domain_history_loader').hide()
      )

  get_ce_show_entry_history = () ->
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
            dom: '<"datatable-top-tools no-margin-datatable-top-tool"l>t<ip>'
            ordering: true
            order: [[ 3, 'desc' ]]
            drawCallback: () ->
              # for longer descriptions let user toggle full vs truncated
              $('.truncated-description').on 'click', () ->
                toggle_truncation($(this))
            pageLength: 10
            pagingType: 'simple_numbers'
            searching: false
            stateSave: false
            columnDefs: [
              {
                targets: [ 0 ]
                orderData: 3
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

  get_ce_show_xbrs_history = (url) ->
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

          $('#ce_xbrs_history_loader').hide()

          $('#ce_xbrs_history_table').DataTable({
            data: data
            dom: '<"datatable-top-tools no-margin-datatable-top-tool"l>t<ip>'
            ordering: true
            order: [[ 6, 'desc' ]]
            pageLength: 10
            pagingType: 'simple_numbers'
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
                render: (data) ->
                  date = moment(data)
                  formatted = date.format('LLL')
                  return formatted
              }
              {
                data: 'score'
                className: 'col-align-right'
                render: (data) ->
                  return data.toFixed(1)
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
               data: 'time'
               visible: false
             }
            ]
          })
      error: (error) ->
        console.error(error)
        std_msg_error(error, [])
        $('#ce_xbrs_history_loader').hide()
    )

#  get_related_history = (domain) ->
#    # TODO: implement this when the related history endpoint exists.
#    $('#ce_related_history_loader').hide()
#    $('#ce_related_history_table').DataTable({
#      data: {}
#      ordering: true
#      info: false
#      paging: false
#      searching: false
#      stateSave: false
#      columns: [
#        {
#          data: 'subdomain'
#        }
#        {
#          data: 'domain'
#        }
#        {
#          data: 'path'
#        }
#        {
#          data: 'categories'
#        }
#        {
#          data: 'user/source'
#        }
#        {
#          data: 'last modified'
#        }
#      ]
#    })

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

      $subdomain.prop('disabled', false) if $subdomain.data('val')
      $original.prop('disabled', false) if $original.data('val')

    disable_submit = !verifySubmit()

    $('.ce-submit-button').prop('disabled', disable_submit)

  window.submit_show_page_changes = (entry_id) ->
    std_msg_ajax(
      method: 'POST'
      url: '/escalations/api/v1/escalations/webcat/complaints/view_complaint'
      data:
        complaint_entry_id: entry_id
      success: (response) ->
        data = $.parseJSON(response).data
        { status: curr_status } = data.complaint
        cat_ids = null
        # slight differences in data sent
        uri = $('.ce-ip-uri-input').val()
        category_names = []
        internal_comment = $('.ce-internal-comment-textarea').val()
        commit = ''
        customer_comment = $('.ce-customer-comment-textarea').val()

        # slight differences in data sent
        if status == 'PENDING'
          status = ''
          commit = $('input[name=resolution]:checked').val()
        else
          status = $('input[name=resolution]:checked').val()

        categories_selectize = $('#ce_categories_select')[0].selectize

        if categories_selectize.items.length > 0
          cat_ids = categories_selectize.items.join(',')

        $('#ce_categories_select').next('.selectize-control').find('.item').each ->
          category_names.push($(this).text())

        entry_data = {
          'id': entry_id,
          'prefix': uri,
          'categories': cat_ids,
          'category_names': category_names.toString(),
          'status': status,
          'commit': commit,
          'comment': internal_comment,
          'resolution_comment': customer_comment,
          'uri_as_categorized': uri
        }

        # check data here before submitting
        # If resolution is set to fixed, make sure it has categories applied
        if entry_data.categories == null && entry_data.status == 'FIXED'
          std_msg_error('Must include at least one category.','', reload: false)
          return
        else if entry_data.resolution_comment == '' && entry_data.status == 'FIXED'
          std_msg_error('Must have a message to the customer.','', reload: false)
          return
        else if entry_data.uri_as_categorized == '' && entry_data.status == 'FIXED'
          std_msg_error('Must have an IP/URI.','', reload: false)
          return
        else if entry_data.status == 'INVALID' && entry_data.categories != null
          std_msg_error('Cannot include categories with an INVALID resolution.', '', reload: false)
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
    std_msg_ajax(
      url: '/escalations/api/v1/escalations/webcat/complaint_entries/update'
      method: 'POST'
      headers: headers
      data: entry_data
      success: (response) ->
        data = $.parseJSON(response)

        if data.error?
          show_message('error', "Submissions failed: #{data.error}", false, '#alert_message')
        else
          show_message('success', 'Submitted. Refreshing to see new results.', false, '#alert_message')
          setTimeout ->
            location.reload()
          , 5000

      error: (response) ->
        msg = response.resonseJSON.error

        std_msg_error("Error submitting entry", msg, reload: false)
        console.error(msg)
    , this)

  # Sending individual reviewed (PENDING) entry info to the backend
  process_review = (entry_data) ->
    std_msg_ajax(
      url: '/escalations/api/v1/escalations/webcat/complaint_entries/update_pending'
      method: 'POST'
      headers: headers
      data: {
        data: [entry_data]
      }
      success: (response) ->
        show_message('success', 'Submitted. Refreshing to see new results.', false, '#alert_message')
        setTimeout ->
          location.reload()
        , 5000
      error: (response) ->
        msg = response.resonseJSON.error
        console.error(msg)
        std_msg_error("Error submitting reviewed entries", msg, reload: false)
    , this)

  window.reopen_complaint = () ->
    $('#reopen_loader').removeClass('hidden')
    std_msg_ajax(
      url: '/escalations/api/v1/escalations/webcat/complaint_entries/reopen_complaint_entry'
      method: 'POST'
      data: { 'complaint_entry_id': entry_id }
      success: (response) ->
        $('#reopen_loader').addClass('hidden')
        show_message('success', 'Reopened. Refreshing to see new results.', false, '#alert_message')
        setTimeout ->
          location.reload()
        , 2000
      error: (response) ->
        console.error(response)
        std_msg_error(response,"", reload: false)
    )

  $ ->
    current_user_id = Number($('input[name="current_user_id"]').val())
    entry_id = Number($('#complaint_entry_id')[0].innerText)
    headers = 'Token': $('input[name="token"]').val(),'Xmlrpc-Token': $('input[name="xml_token"]').val()
    initial_status = $('.status-wrapper > .top-info-data').text()
    resolution_option = $('.resolution-radio-button:checked').val()
    resolution_comment = $('.ce-customer-comment-textarea').val()
    review_option = $('.review-radio-button:checked').val()

    get_current_categories()
    get_ce_show_entry_history()

    $(document).on 'change', '.ce-ip-uri-input', ->
      $domain = $('#ce_ip_uri_domain')
      $subdomain = $('#ce_ip_uri_subdomain')
      $original = $('#ce_ip_uri_original')
      text = $(this).val()
      domain_text = $domain.data('val')
      subdomain_text = $subdomain.data('val')
      original_text = $original.data('val')

      $domain.prop('disabled', true) if text == domain_text
      $subdomain.prop('disabled', true) if text == "#{subdomain_text}.#{domain_text}"
      $original.prop('disabled', true) if text == "#{subdomain_text}.#{domain_text}#{original_text}"


    if resolution_option
      get_resolution_templates(resolution_option, 'individual', [entry_id]).then () ->
        $('.ce-customer-comment-textarea').val(resolution_comment) if resolution_comment != ''
        $('.ce-submit-button').prop('disabled', !verifySubmit())

    $(document).on 'change', '.resolution-radio-button', ->
      resolution_option = $(this).val()
      toggleSubmitButton()

    $(document).on 'change', '.review-radio-button', ->
      review_option = $(this).val()
      toggleSubmitButton()

    $(document).on 'change', '.ce-input, #self_review', ->
      # The onItemRemove and onItemAdd events for the selectize dropdowns will handle the submit button for categories
      unless $(this).attr('id') == 'ce_categories_select'
        disable_submit = !verifySubmit()

        $('.ce-submit-button').prop('disabled', disable_submit)
