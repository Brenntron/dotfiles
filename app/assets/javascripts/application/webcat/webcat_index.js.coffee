## FUNCTIONS FOR BUILDING WEBCAT INDEX TABLE ###

$ ->
  # call below and related functions only if we're on webcat index
  if $('#complaints-index').length

    # Create index table
    url = $('#complaints-index').data('source')
    $.when(pull_user_preference_filter()).done ->
      build_complaints_table(url)

#### New complaints index table setup
build_complaints_table = (url) ->
  complaint_table = $('#complaints-index').DataTable(
    initComplete: ->
      # Get display prefs
      get_display_prefs()

      input = $('.dataTables_filter input').unbind()
      self = @api()

      $searchButton = $('<button class="dt-button dt-search-button esc-tooltipped" title="Search">').click(->
        self.search(input.val()).draw()
        return
      )
      $clearButton = $('<button class="dt-button dt-search-clear-button esc-tooltipped" title="Clear">').click(->
        input.val ''
        $searchButton.click()
        return
      )
      $('.dataTables_filter').append $clearButton, $searchButton

      # Make the datatables search prettier
      $('#complaints-index_filter input').addClass('restricted-table-search-input')

      # properly init these search/clear icons
      $('.dt-button').tooltipster
        theme: [
          'tooltipster-borderless'
          'tooltipster-borderless-customized'
          'tooltipster-borderless-comment'
        ]

    lengthMenu: [[25, 50, 100, 150, 200], [25, 50, 100, 150, 200]]
    processing: true
    serverSide: true
    stateSave: true
    select: true
    ajax:
      url: url
      data: build_data()
      error: () ->
        ###
          If there is an error with the build_data call, the localstorage and url will be blown away
          This will reset the search and filters
        ###
        console.log 'There has been an error calling the backend data'
        webcat_refresh()

      complete: ->

        # Grab current categories per entry
        rows = $('#complaints-index').find('.cat-index-main-row')
        get_current_cats(rows)
        create_ind_res_dialogs()

        $('#complaints-index tbody tr.cat-index-main-row .nested-col-table tr td').click ->
          # allows individual selection of rows while clicking in nested data, is a little buggy with the multiselect
          if $(this).hasClass('non-selectable')
            return
          else
            main_row = $(this).parents('tr.cat-index-main-row')[0]
            row_id = $(main_row).attr('id')
            if $(main_row).hasClass('selected')
              complaint_table.row("##{row_id}").deselect()
            else
              complaint_table.row("##{row_id}").select()

        # set listeners for bulk changes
        $('#complaints-index').DataTable().on('select', (_e, dt, _type, indexes) ->
          bulk_resolution_select_handler(dt, indexes)
        ).on('deselect', (_e, dt, _type, indexes) ->
          bulk_resolution_deselect_handler(dt, indexes)
        )

    createdRow: (row, data) ->
      $(row).addClass('cat-index-main-row')
      $(row).attr('data-categories', data.category)
      $(row).attr('data-status', data.status)

    drawCallback: () ->
      console.log 'complaint drawcallback'
      if localStorage.webcat_reset_page
        localStorage.removeItem('webcat_reset_page')
      #         trying to figure out why we are redrawing the table here
      #          setTimeout () ->
      #            $('#complaints-index').DataTable().page(0).draw( true )
      #          , 100
      #
      if localStorage.webcat_search_name
        { webcat_search_type, webcat_search_name, webcat_search_conditions } = localStorage
        ### check variables below
            text_check makes sure that the table doesn't have the named search with the same name being saved now
            search_name_check makes sure that the search is being saved as a named search
            Not super complicated, but that if statement was looking gross and confusing
        ###
        text_check = !window.find_saved_search_by_name(webcat_search_name)
        search_name_check = webcat_search_name != ''

        if webcat_search_type == 'advanced' && search_name_check && text_check
          temporary_search_link(webcat_search_name, webcat_search_conditions)

    pagingType: 'full_numbers'
    dom: '<"datatable-top-tools no-margin-datatable-top-tool"lf>t<ip>'
    language: {
      search: "_INPUT_"
      searchPlaceholder: "Search within table"
    }
    # default ordering - keep on hidden age column
    order: [ 10, 'dec' ]
    columnDefs: [
      {
        targets: [10,11,12,13,14,15,16,17]
        visible: false
      }
      {
        targets: [0,1,2,3,4,5,6,7,8,9]
        orderable: false
      }
    ]
    columns: [
      {
        data: 'age'
        className: 'ticket-col'
        render: (data, type, full, meta) ->
          age_class = ''
          unless full.status == 'COMPLETED' || full.status == 'RESOLVED'
            if full.age_int > 43200
              age_class = 'ticket-age-over12hr'
            else if full.age_int > 10800
              age_class = 'ticket-age-over3hr'

          if full.channel?
            if full.channel == 'talosintel'
              if full.complaint_source == 'talos-intelligence'
                complaint_channel = 'TI Webform'
              else if full.complaint_source == 'talos-intelligence-api'
                complaint_channel = 'TI API'
            else
              complaint_channel = full.channel
          else
            complaint_channel = '<span class="missing-data">Channel unknown</span>'

          is_important_flags = ''
          if full.is_important == "true"
            is_important_flags += '<span class="esc-tooltipped is-important highlight-second-review" tooltip title="Important"></span>'
          if full.was_dismissed == "true"
            is_important_flags += '<span class="esc-tooltipped was-reviewed highlight-was-dismissed" tooltip title="Reviewed"></span>'

          ticket_col =
            '<table class="nested-col-table">' +
              '<tbody>' +
              '<tr class="entry-id-row"><td><a href="complaints/' + full.complaint_id + '" >' + full.entry_id + '</a></td></tr>' +
              '<tr class="age-row"><td class="' + age_class + '">' + data + '</td></tr>' +
              '<tr class="state-row"><td>' + full.status + '</td></tr>' +
              '<tr class="channel-row"><td>' + complaint_channel + '</td></tr>' +
              '<tr class="important-flag-row"><td>' + is_important_flags + '</td></tr>' +
              '</tbody>' +
              '</table>'

          return ticket_col
      }
      {
        data: 'customer_name'
        className: 'submitter-col alt-col'
        render: (data, type, full, meta) ->
          if full.platform?
            platform = full.platform
          else
            platform = ""

          if platform == "N/A" || platform == "Unknown" || platform == "Missing" || platform == ""
            platform = '<span class="missing-data platform"></span>'

          if full.company_name?
            if full.company_name != ''
              submitter = full.company_name
            else
              submitter = 'Guest'
          else
            submitter = 'Guest'

          if full.customer_name?
            if full.customer_name != ''
              name_row = '<tr class="submitter-name-row"><td>' + full.customer_name + '</td></tr>'
            else
              name_row = ''
          else
            name_row = ''

          if full.customer_email?
            if full.customer_email != ''
              email_row = '<tr class="submitter-email-row"><td>' + full.customer_email + '</td></tr>'
            else
              email_row = ''
          else
            email_row = ''

          submitter_col =
            '<table class="nested-col-table">' +
              '<tbody>' +
              '<tr class="company-row"><td>' + submitter + '</td></tr>' +
              name_row +
              email_row +
              '<tr class="platform-row"><td>' + platform + '</td></tr>' +
              '</tbody>' +
              '</table>'

          return submitter_col
      }
      {
        data: 'tags'
        className: 'tag-col'
        render: (data)->
          tag_items = '<span class="missing-data">No tags</span>'

          if data && typeof data == 'string'
            tags = data.substring( 1, data.length-1 ).replace(/&quot;/g,'');
            tag_list = tags.split(',').map ( tag ) -> return tag.trim();

            if tag_list.length >= 1
              tag_items = ''
              tag_list = tag_list.filter ( tag, index )-> return tag_list.indexOf( tag ) == index && tag != ''
              for tag in tag_list
                item = "<span class='tag-capsule' onclick='search_for_tag(\"#{tag}\")'>" + tag + "</span>"
                tag_items += item

          return tag_items
      }
      {
        data: 'assigned_to'
        className: 'users-col'
        render: (data, type, full, meta) ->
          if data == ''
            user = '<span class="missing-data">No assignee</span>'
          else
            user = data

          users_col =
            '<table class="nested-col-table">' +
              '<tbody>' +
              '<tr class="assignee-row"><td>' + user + '</td></tr>' +
              '<tr class="reviewer-row"><td>' + full.reviewer + '</td></tr>' +
              '<tr class="second-reviewer-row"><td>' + full.second_reviewer + '</td></tr>' +
              '</tbody>' +
              '</table>'

          return users_col
      }
      {
        data: 'description'
        className: 'description-col'
        render: (data) ->
          if data?
            description = '<span onclick="copy_description(this)">' + data + '</span>'
          return description
      }
      {
        data: 'suggested_disposition'
        className: 'suggested-col alt-col'
        render: (data, type, full, meta) ->
          if data?
            cleaned_cats = []
            sugg_cats = data.split(',')
            $(sugg_cats).each ->
              cat = this
              # weird hack below, feel free to change
              unless JSON.stringify(cat) == JSON.stringify('Not in our list')
                cleaned_cats.push(cat)

          fin_cats = cleaned_cats.join(', ')
          return fin_cats
      }
      {
        data: 'uri'
        className: 'uri-col'
        render: (data, type, full, meta) ->
          if full.status == 'PENDING'
            disabled = "disabled=true"
          else
            disabled = ''

          rep = wbrs_display(full.wbrs_score)
          wbrs_score = parseFloat(full.wbrs_score).toFixed(1)
          if rep == undefined then rep = 'unknown'
          if rep == 'unknown' then wbrs_score = '--'
          icon = "<div class='reputation-icon-container'><span class='reputation-icon icon-#{rep}'></span>" + wbrs_score + "</div>"

          entry = data || full.ip_address
          domain = full.domain || full.ip_address

          # disabling domain status since it is the default
          domain_status = 'disabled'

          if (full.status == 'COMPLETED') || (full.status == 'PENDING') || (full.subdomain == '' && full.path == '')
            edit_button_status = 'disabled="disabled"'
            if (full.status == 'COMPLETED') || (full.status == 'PENDING')
              input_status = 'disabled="disabled"'
            else
              input_status = ''
          else
            edit_button_status = ''
          if full.subdomain == ''
            sub_status = 'disabled'
            sub_function = ''
            sub_val = ''
          else
            sub_status = ''
            sub_val = full.subdomain + '.' + domain
            sub_function = 'onclick="update_editURI(\'' + full.entry_id + '\', \'' + full.subdomain + '.' + domain + '\', \'subdomain\');"'
          if full.path == ''
            path_status = 'disabled'
            path_function = ''
            path_val = ''
          else
            path_status = ''
            path_function = 'onclick="update_editURI(\'' + full.entry_id + '\', \'' + full.uri + '\', \'uri\');"'
            path_val = full.uri

          if (full.status == 'COMPLETED') || (full.status == 'PENDING')
            input_uri = full.uri_as_categorized
          else
            input_uri = domain

          domain_col =
            '<table class="nested-col-table">' +
              '<tbody>' +
              '<tr>' +
              '<td class="wbrs-score-col icon-' + rep + '">' + wbrs_score + '</td>' +
              '<td class="uri-ip-col">' + entry + '</td>' +
              '</tr>' +
              '<tr>' +
              '<td class="quick-edit-uri-tool-col non-selectable">' +
              '<span class="dropdown">' +
              '<button class="edit-button" id="quick_edit_uri_' + full.entry_id + '" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false"' + edit_button_status + '></button>' +
              '<div id="quick_edit_dropdown_' + full.entry_id + '" class="dropdown-menu quick-edit-uri-dropdown" aria-labelledby="quick_edit_uri_' + full.entry_id + '">' +
              '<ul>' +
              '<li class="quick-domain ' + domain_status + '" data-val="' + domain + '">domain</li>' +
              '<li class="quick-subdomain ' + sub_status + '" data-val="' + sub_val + '" ' + sub_function + '>subdomain</li>' +
              '<li class="quick-uri ' + path_status + '" data-val="' + path_val + '" ' + path_function + '>original uri</li>' +
              '</ul>' +
              '</div>' +
              '</td>' +
              '<td class="edit-uri-col non-selectable">' +
              '<input class="nested-table-input complaint-uri-input" id="edit_uri_input_' +
              full.entry_id + '" type="text" data-domain="' + domain + ' "value="' + input_uri + '"' + input_status + '/>' +
              '</td></tr>' +
              '</tbody>' +
              '</table>'

          return domain_col
      }
      {
        data: null
        className: 'tools-col'
        render: (data, type, full, meta) ->
          history_url = full.uri || full.ip_address
          history_button =
            '<button class="history-button esc-tooltipped" id="entry-history-' + full.entry_id + '" ' +
              'onclick="history_dialog(\'' + full.entry_id + '\', \'' + history_url + '\')" ' +
              'title="Domain History"></button>'

          whois_url = full.domain || full.ip_address
          whois_button =
            '<button class="whois-button esc-tooltipped" id="whois-' + full.entry_id + '" ' +
              'onclick="WebCat.RepLookup.whoIsLookup(\'' + whois_url + '\')"' +
              'title="Whois Information"></button>'

          lookup_url = full.subdomain + '.' + full.domain || full.ip_address
          lookup_button =
            '<a class="button-wrapper-link" href="https://www.google.com/search?q=site%3A' + lookup_url +
              '" target="_blank"><button id="google-' + full.entry_id + '" class="lookup-button esc-tooltipped" ' +
              'title="Google Search"></button></a>'

          visit_url = history_url
          if full.wbrs_score <= -6
            visit_button =
              '<button id="open-' + full.entry_id + '" class="open-all" disabled></button>'
          else
            visit_button =
              '<a class="button-wrapper-link" href="http://' + visit_url + '" target="_blank"><button id="open-' + full.entry_id +
                '" class="open-all esc-tooltipped" title="Open in New Tab"></button></a>'

          return history_button + whois_button + lookup_button + visit_button
      }
      {
        data: null
        className: 'categories-col alt-col'
        render: (data, type, full, meta) ->
          domain = full.domain || full.ip_address
          if full.status == 'PENDING'
            disabled = "disabled=true"
          else
            disabled = ''

          cat_table =
            '<table class="nested-col-table">' +
              '<tbody>' +
              '<tr><td id="current_cat_' + full.entry_id + '" class="current-cat-col"></td></tr>' +
              '<tr><td class="edit-cat-col non-selectable">' +
              '<select id="input_cat_' + full.entry_id + '" name="input_cat_' +
              full.entry_id + '" class="nested-table-input" placeholder="Enter categories / confidence order" ' + disabled + '>' +
              '</select>' +
              '</td></tr>' +
              '</tbody>' +
              '</table>'

          return cat_table
      }
      {
        data: 'status'
        className: 'resolution-col'
        render: (data, type, full, meta) ->
          # Internal comment
          if (full.internal_comment == null) || (full.internal_comment == '')
            comment = '<span class="missing-data">No internal comment.</span>'
          else
            comment = full.internal_comment

          # Resolution comment (for customer)
          observable = full.uri || full.ip_address
          dialog_title = 'Customer Response for: ' + observable
          if (full.resolution_comment == null) || (full.resolution_comment == '')
            res_comment = 'No response created or sent to customer.'

          res_comment_dialog_html =
            '<div class="resolution-comment-dialog hide" id="resolution_comment_dialog_' + full.entry_id + '" title="' + dialog_title + '">' +
              '<div class="dialog-content-wrapper"><div class="row"><div class="col-xs-12">' +
              '<label class="content-label-sm full-row-label">Resolution Email Template</label>' +
              '<select class="response-template-select" id="entry-email-response-to-customers-select_' + full.entry_id + '"></select>' +
              '</div></div><div class="row"><div class="col-xs-12">' +
              '<label class="content-label-sm full-row-label">Response to Customer</label>' +
              '<textarea class="email-response-input" id="entry-email-response-to-customers_' + full.entry_id + '" name="customer_facing_comment" type="text"></textarea>' +
              '<label class="content-label-sm full-row-label">*Edits to the above textarea will be saved upon submitting the entry. Selecting a different template or resolution will replace any text added above.</label>' +
              '</div></div></div>' +
            '</div>'

          res_submitted_dialog_html =
            '<div class="resolution-comment-dialog hide submitted-resolution-dialog" id="resolution_comment_dialog_' + full.entry_id + '" title="' + dialog_title + '">' +
              '<div class="dialog-content-wrapper"><div class="row"><div class="col-xs-12">' +
              '<label class="content-label-sm full-row-label">Email Response to Customer</label>' +
              '</div></div><div class="row"><div class="col-xs-12">' +
              '<div id="entry-email-response-to-customers_' + full.entry_id + '">' + res_comment + '</div>' +
              '</div></div></div>' +
              '</div>'


          if data == 'PENDING'
            submit_res_wrapper =
              '<div class="submit-res-wrapper pending-ticket-res-wrapper">' +
                '<div class="res-radio-row">' +
                '<div class="res-radio-wrapper">' +
                '<input type="radio" class="review_radio_button" name="resolution_review' + full.entry_id + '" value="commit" id="commit' + full.entry_id + '">' +
                '<label for="commit' + full.entry_id + '">Commit</label></div>' +
                '<div class="res-radio-wrapper">' +
                '<input type="radio" class="review_radio_button" name="resolution_review' + full.entry_id + '" value="decline" id="decline' + full.entry_id + '">' +
                '<label for="decline' + full.entry_id + '">Decline</label></div>' +
                '<div class="res-radio-wrapper">' +
                '<input type="radio" class="review_radio_button" name="resolution_review' + full.entry_id + '" value="ignore" checked="checked" id="ignore' + full.entry_id + '">' +
                '<label for="ignore' + full.entry_id + '">Ignore (Bulk change only)</label></div>' +
                '</div>' +
                '<div class="submit-row">' +
                '<span class="dropdown internal-comment-wrapper">' +
                '<button class="comment-button" id="internal_comment_button' + full.entry_id + '" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false"></button>' +
                '<div id="internal_comment_dropdown_' + full.entry_id + '" class="dropdown-menu dropdown-menu-right internal-comment-dropdown" aria-labelledby="internal_comment_button' + full.entry_id + '">' +
                '<div class="dropdown-reverse-header">Internal Comment</div>' +
                '<div class="dropdown-comment" id="internal_comment_' + full.entry_id + '">' + comment + '</div>' +
                '</div>' +
                '</span>' +
                '<button class="resolution-comment-button" id="resolution_comment_button' + full.entry_id + '" onclick="open_ind_res_dialog(' + full.entry_id + ');"></button>' +
                '<button class="tertiary submit_changes" id="submit_changes_' + full.entry_id + '" disabled=true onclick="submit_changes(' + full.entry_id + ')">Submit</button>' +
                '</div>' +
                res_submitted_dialog_html +
                '</div>'
          else
            if data == 'COMPLETED'

              fixed_check = ''
              unchanged_check = ''
              invalid_check = ''
              if full.resolution == 'FIXED'
                fixed_check = 'checked="checked"'
              if full.resolution == 'UNCHANGED'
                unchanged_check = 'checked="checked"'
              if full.resolution == 'INVALID'
                invalid_check = 'checked="checked"'

              submit_res_wrapper =
                '<div class="submit-res-wrapper completed-ticket-res-wrapper">' +
                  '<div class="res-radio-row">' +
                  '<div class="res-radio-wrapper">' +
                  '<input type="radio" class="resolution_radio_button" name="resolution' + full.entry_id + '" value="UNCHANGED" disabled="true" ' + unchanged_check + ' id="unchanged' + full.entry_id + '">' +
                  '<label for="unchanged' + full.entry_id + '">Unchanged</label></div>' +
                  '<div class="res-radio-wrapper">' +
                  '<input type="radio" class="resolution_radio_button" name="resolution' + full.entry_id + '" value="FIXED" disabled="true" ' + fixed_check + ' id="fixed' + full.entry_id + '">' +
                  '<label for="fixed' + full.entry_id + '">Fixed</label></div>' +
                  '<div class="res-radio-wrapper">' +
                  '<input type="radio" class="resolution_radio_button" name="resolution' + full.entry_id + '" value="INVALID" disabled="true" ' + invalid_check + ' id="invalid' + full.entry_id + '">' +
                  '<label for="invalid' + full.entry_id + '">Invalid</label></div>' +
                  '</div>' +
                  '<div class="submit-row">' +
                  '<span class="dropdown internal-comment-wrapper">' +
                  '<button class="comment-button" id="internal_comment_button' + full.entry_id + '" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false"></button>' +
                  '<div id="internal_comment_dropdown_' + full.entry_id + '" class="dropdown-menu dropdown-menu-right internal-comment-dropdown" aria-labelledby="internal_comment_button' + full.entry_id + '">' +
                  '<div class="dropdown-reverse-header">Internal Comment</div>' +
                  '<div class="dropdown-comment" id="internal_comment_' + full.entry_id + '">' + comment + '</div>' +
                  '</div></span>' +
                  '<button class="resolution-comment-button" id="resolution_comment_button' + full.entry_id + '" onclick="open_ind_res_dialog(' + full.entry_id + ');"></button>' +
                  '<button class="tertiary submit_changes" id="reopen_' + full.entry_id + '" onclick="reopenComplaint(' + full.entry_id + ')">Reopen</button>' +
                  '</div>' +
                  res_submitted_dialog_html +
                  '</div>'

            else
              submit_res_wrapper =
                '<div class="submit-res-wrapper open-ticket-res-wrapper">' +
                  '<div class="res-radio-row">' +
                  '<div class="res-radio-wrapper">' +
                  '<input type="radio" class="resolution_radio_button" name="resolution' + full.entry_id + '" value="UNCHANGED" id="unchanged' + full.entry_id + '">' +
                  '<label for="unchanged' + full.entry_id + '">Unchanged</label></div>' +
                  '<div class="res-radio-wrapper">' +
                  '<input type="radio" class="resolution_radio_button" name="resolution' + full.entry_id + '" value="FIXED" checked id="fixed' + full.entry_id + '">' +
                  '<label for="fixed' + full.entry_id + '">Fixed</label></div>' +
                  '<div class="res-radio-wrapper">' +
                  '<input type="radio" class="resolution_radio_button" name="resolution' + full.entry_id + '" value="INVALID" id="invalid' + full.entry_id + '">' +
                  '<label for="invalid' + full.entry_id + '">Invalid</label></div>' +
                  '</div>' +
                  '<div class="submit-row">' +
                  '<span class="dropdown internal-comment-wrapper">' +
                  '<button class="comment-button" id="internal_comment_button' + full.entry_id + '" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false"></button>' +
                  '<div id="internal_comment_dropdown_' + full.entry_id + '" class="dropdown-menu dropdown-menu-right internal-comment-dropdown" aria-labelledby="internal_comment_button' + full.entry_id + '">' +
                  '<div class="dropdown-reverse-header">Internal Comment</div>' +
                  '<textarea id="internal_comment_' + full.entry_id + '" placeholder="Internal note for choosing categories" class="internal-comment">' + full.internal_comment + '</textarea>' +
                  '</div>' +
                  '</span>' +
                  '<button class="resolution-comment-button" id="resolution_comment_button' + full.entry_id + '" onclick="open_ind_res_dialog(' + full.entry_id + ');"></button>' +
                  '<button class="tertiary submit_changes" id="submit_changes_' + full.entry_id + '" onclick="submit_changes(' + full.entry_id + ')">Submit</button>' +
                  '</div>' +
                  res_comment_dialog_html +
                  '</div>'

          return submit_res_wrapper
      }
      # The below columns are for sorting only and should never be visible
      {
        data: 'age_int'
      }
      {
        data: 'entry_id'
      }
      {
        data: 'uri'
        render: (data, type, full, meta) ->
          entry = data || full.ip_address
          return entry
      }
      {
        data: 'status'
      }
      {
        data: 'resolution'
      }
      {
        data: 'wbrs_score'
      }
      {
        data: 'company_name'
      }
      {
        data: 'assigned_to'
      }

    ]
  )




###
# This function builds the argument to get data from the backend for DataTables
# Depending on the search type and arguments
# build_header is called at the bottom of this function to format the search header
###
build_data = () ->
  # check local storage first
  { webcat_search_type, webcat_search_name, webcat_search_conditions } = localStorage
  { search } = location

  try
    webcat_search_conditions = JSON.parse webcat_search_conditions
  catch e
    webcat_search_conditions = {}

  if search != ''
    webcat_search_type = 'standard'
    urlParams = new URLSearchParams(location.search);

  if webcat_search_type?
    switch(webcat_search_type)
      when 'advanced'
        data = {
          search_type: webcat_search_type
          search_name : webcat_search_name
          search_conditions: webcat_search_conditions
        }
      when 'contains'
        data = {
          search_type: webcat_search_type
          search_conditions: webcat_search_conditions
        }
      when 'standard'
        urlParams = new URLSearchParams(location.search);
        refresh_localStorage()
        data = {
          search_type: webcat_search_type
          search_name: urlParams.get('f')
        }
      when 'named'
        data = {
          search_type: webcat_search_type
          search_name: webcat_search_name
        }

    build_header(data)
    return data

  else
    # check users chosen default filter
    fav = $('.favorite-search-icon-active')
    if fav.length > 0
      link = $(fav[0]).prev()
      address = $(link).attr('href')
      filter = address.split('=').pop();

      refresh_localStorage()
      data = {
        search_type: 'standard'
        search_name: filter
      }
      build_header(data)
      return data


###
  # Depending on the data, this function builds the search header
  # With the search header the reset filter button is attached
  # If the search_type is 'named' or 'advanced', a subheader with
  # search definitions will be made with the build_subheader function
###
build_header = (data) ->
  console.log 'building header'
  container = $('#webcat_searchref_container')
  if data != undefined && container.length > 0
    reset_icon = "<span #{if current_page_is_favourite() then 'hidden style="display: none"' else ''} id='refresh-filter-button' class='reset-filter esc-tooltipped' title='Clear Search Results' onclick='webcat_refresh()'></span>"
    {search_type, search_name} = data

    try
      webcat_search_conditions = JSON.parse localStorage.webcat_search_conditions
    catch e
      webcat_search_conditions = {}

    if search_type == 'standard'
      search_name = search_name.toLowerCase().replace('complaints', 'tickets')

      if !search_name.endsWith('tickets')
        search_name += ' tickets'

      new_header =
        '<div>' +
          '<span class="text-capitalize">' + search_name.replace(/_|%20/g, " ") + ' </span>' +
          reset_icon +
          '</div>'

    else if search_type == 'advanced'
      new_header =
        '<div>Results for Advanced Search ' +
          reset_icon +
          '</div>'
      build_subheader(webcat_search_conditions)
    else if search_type == 'named'
      new_header =
        '<div>Results for "' + search_name + '" Saved Search' +
          reset_icon +
          '</div>'
      el = localStorage.webcat_search_conditions
      if !el.includes('temp_row')
        subheader = $("##{el} .saved-search")[0].dataset.search_conditions
      else
        last_row = $('#saved-search-tbody')[0].lastElementChild
        subheader = $(last_row).find('.saved-search').attr('data-search_conditions')
      build_subheader(subheader)
    else if search_type == 'contains'
      new_header =
        '<div>Results for "' + webcat_search_conditions.value + '" '+
          reset_icon +
          '</div>'
    else
      new_header = 'All Tickets'
    $('#webcat-index-title')[0].innerHTML = new_header
  else
    $('#webcat-index-title')[0].innerHTML = 'All Tickets'



# Subheader construction - used for named and advanced searches
build_subheader = (subheader) ->
  if typeof subheader == 'string'
    subheader = JSON.parse(subheader)

  container = $('#webcat_searchref_container')
  for condition_name, condition of subheader
    if condition != ''
      if condition_name == 'platform_ids' || condition_name == 'category_ids'
        continue
      if condition_name == 'id'
        condition_name = 'Entry Id'
      if condition_name == 'user_id'
        condition_name = 'Assignee'
      if condition_name == 'customer_email'
        condition_name = 'Submitter Email'
      if condition_name == 'customer_name'
        condition_name = 'Submitter Name'
      if condition_name == 'company_name'
        condition_name = 'Submitter Org'
      if condition_name == 'ip_or_uri'
        condition_name = 'Complaint'
      condition_name = condition_name.replace(/_/g, " ").toUpperCase()
      condition_name_HTML = '<span class="search-condition-name text-uppercase">' + condition_name + ': </span>'
      if typeof condition == 'object'
        condition_HTML = '<span>' + condition.from  + ' - ' + condition.to+ '</span>'
      else
        condition_HTML = '<span>' + condition + '</span>'

      container.append('<span class="search-condition">' + condition_name_HTML + condition_HTML + '</span>')


window.pull_user_preference_filter = () ->
  return if window.location.pathname != '/escalations/webcat/complaints'
  std_msg_ajax(
    method: 'POST'
    url: '/escalations/api/v1/escalations/user_preferences/'
    data: { name: 'webcat_complaints_filter' }
    success: (response) ->
      return unless response?
      name = JSON.parse(response).name
      set_icon_for_favorite_filter(name)
  )


set_icon_for_favorite_filter = (filter_name) ->
  filter_dropdown = $("#filter-dropdown > #filter-cases-list a[href='#{filter_name}']")
  saved_search = window.find_saved_search_by_name(filter_name)

  if filter_dropdown.length > 0
    filter_dropdown.parent().find('.favorite-search-icon').removeClass('favorite-search-icon').addClass('favorite-search-icon-active')
  else if saved_search
    saved_search.parent().find('.favorite-search-icon').removeClass('favorite-search-icon').addClass('favorite-search-icon-active')
