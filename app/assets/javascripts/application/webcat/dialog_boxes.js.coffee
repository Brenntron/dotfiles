## WEBCAT DIALOG BOXES FUNCTIONS - INCLUDES HISTORY AND LOOKUP DATA ##


# History functions

# Complaint history dialog box.
# Includes tabs for domain history, complaint entry history,
# and xbrs history of the url.
window.history_dialog = (id, url) ->

  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  std_msg_ajax(
    url: '/escalations/api/v1/escalations/webcat/complaint_entries/history'
    method: 'POST'
    headers: headers
    data: {'id': id}
    success: (response) ->
      json = $.parseJSON(response)
      if json.error
        alert(json.error)
      else
        history_dialog_content =
          "<div class='cat-history-dialog dialog-content-wrapper'>
               <h4>#{url}</h4>
              <ul class='nav nav-tabs dialog-tabs' role='tablist'>
               <li class='nav-item active' role='presentation'>
                <a class='nav-link' role='tab' data-toggle='tab' href='#domain-history-tab' aria-controls='domain-history-tab'>
                   Domain History
                </a>
               </li>
              <li class='nav-item' role='presentation'>
                <a class='nav-link' role='tab' data-toggle='tab' href='#complaint-history-tab' aria-controls='complaint-history-tab'>
                   Complaint Entry History
                </a>
              </li>
               <li class='nav-item' role='presentation'>
                <a class='nav-link' role='tab' data-toggle='tab' href='#xbrs-history-tab' aria-controls='xbrs-history-tab' onclick='get_xbrs_history(\"#{url}\", this)'>
                  XBRS Timeline
                </a>
               </li>
            </ul>
            <div class='tab-pane active' role='tabpanel' id='domain-history-tab'>
            <h5>Domain History</h5>"

        if json.entry_history.domain_history.length < 1
          history_dialog_content += '<span class="missing-data">No domain history available.</span>'
        else
          history_dialog_content +=
            '<table class="history-table"><thead><tr><th>Action</th><th>Confidence</th><th>Description</th><th>Time</th><th>User</th><th>Category</th></tr></thead>' +
              '<tbody>'
          # Build domain history table
          for entry in json.entry_history.domain_history
            history_dialog_content +=
              '<tr>' +
                '<td>' + entry['action'] + '</td>' +
                '<td>' + entry['confidence'] + '</td>' +
                '<td>' + entry['description'] + '</td>' +
                '<td>' + entry['time'] + '</td>' +
                '<td>' + entry['user'] + '</td>' +
                '<td>' + entry['category']['descr'] + '</td>' +
                '</tr>'
          # End domain history table
          history_dialog_content += '</tbody></table>'

        # End domain history tab start Complaint Entry Tab
        history_dialog_content +=
          '</div>' +
            '<div class="tab-pane" role="tabpanel" id="complaint-history-tab">' +
            '<h5>Complaint Entry History</h5>'

        if json.entry_history.complaint_history.length < 1
          history_dialog_content += '<span class="missing-data">No complaint entry history available.</span>'
        else
          history_dialog_content +=
            '<table class="history-table"><thead><th>Time</th><th>User</th><th>Details</th></thead>' +
              '<tbody>'

          # Build the complaint history table
          entry_row = ""
          for entry in json.entry_history.complaint_history
            entry_row = "<tr><td>" + entry[0] + '</td>'
            details_col = ""
            i = 0
            for change_key, change_entry of entry
              i = i + 1
              if i > 1
                for key, value of change_entry
                  if key == "whodunnit"
                    entry_row += "<td>" + value + "</td>"
                  else
                    details_col += '<span class="bold">' + key + ":</span> " + value[0] + " - " + value[1] + "<br/>"
            entry_row += '<td>' + details_col + '</td></tr>'
            history_dialog_content += entry_row
          # End complaint history table
          history_dialog_content += '</tbody></table></div>'


        # End complaint history table tab
        # Start XBRS Tab
        history_dialog_content +=
          "
           <div class='tab-pane' role='tabpanel' id='xbrs-history-tab'>
            <h5>XBRS Timeline</h5>
              <table class=''history-table xbrs-history-table' id='webcat-xbrs-history'></table>
            </div>
           "

        # Only one history dialog open at a time - content gets swapped out
        if $("#history_dialog").length
          history_dialog = this
          $("#history_dialog").html(history_dialog_content)
          $('#history_dialog').dialog('open')
        else
          history_dialog = '<div id="history_dialog" title="History Information"></div>'
          $('body').append(history_dialog)
          $("#history_dialog").html(history_dialog_content)
          $('#history_dialog').dialog
            autoOpen: false
            minWidth: 800
            position: { my: "right top", at: "right top", of: window }
          $('#history_dialog').dialog('open')
    error: (response) ->
      notice_html = "<p>Something went wrong: #{response.responseText}</p>"
  , this)


## Fetches XBRS history of a url on click of the XBRS tab in history
window.get_xbrs_history = (url, tab) ->
  wrapper = $(tab).parents('.dialog-content-wrapper')[0]
  xbrs_table = $("#webcat-xbrs-history")
  xbrs_msg = $(wrapper).find('.xbrs-no-data-msg')[0]
  # Clear table of residual data
  $(xbrs_table).empty()
  if xbrs_msg?
    $(xbrs_msg).remove()
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  std_msg_ajax(
    url: '/escalations/api/v1/escalations/webcat/complaint_entries/xbrs'
    method: 'POST'
    headers: headers
    data: {'url': url}
    success: (response) ->
      if response.data.length < 1
        $('<span class="missing-data xbrs-no-data-msg">No XBRS history available.</span>').insertBefore(xbrs_table)
      else
        $(xbrs_table).append(document.createElement('thead'))
        $(xbrs_table).append(document.createElement('tbody'))
        thead = $(xbrs_table).find('thead')
        tbody = $(xbrs_table).find('tbody')
        table_headers = ['Timestamp', 'Scrore', 'V2 Content Cat', 'V3 Content Cats', 'Threat Cats', 'Rule Hits']

        parsed_rows = []
        thead_row = ''

        table_headers.forEach (header)->
          thead_row += "<th> #{header}</th>"
        thead.append(thead_row)

        response.data.forEach (row)->
          data_row = ""

          for key, value of row
            data_row += "<td>#{value || '-'}</td>"

          tbody.append("<tr>#{data_row}</tr>")

    error: (response) ->
      notice_html = "<p>Something went wrong: #{response.responseText}</p>"
  , this)





$ ->

  # initialize bulk resolution dialog
  $('#index_change_resolution_dialog').dialog
    autoOpen: false
    classes: { 'ui-dialog': 'index-change-resolution-dialog'}
    width: 450
    minHeight: 300
    position:
      my: 'center top'

  get_resolution_templates('UNCHANGED', 'bulk')

  # Update bulk response templates
  $('.bulk-resolution-radio').change ->
    resolution = $(this).val()
    get_resolution_templates(resolution, 'bulk')

  # Populate current resolution comment after changing resolution template
  $('#email-response-to-customers-select').on 'change', (i, e) ->
    comment = $('#email-response-to-customers-select option:selected').attr('data-body')
    $('#email-response-to-customers').val comment

  window.open_ind_res_dialog = (entry_id) ->
    target_dialog_id = 'resolution_comment_dialog_' + entry_id
    button_id = '#resolution_comment_button' + entry_id
    $('.resolution-comment-button').removeClass('active')

    $(".resolution-comment-dialog").each ->
      dialog_id = $(this).attr('id')
      if dialog_id != target_dialog_id
        $('#' + dialog_id).dialog('close')
      else
        $('#' + dialog_id).dialog('open')
    $(button_id).addClass('active')

  # Update inline customer comments when selecting new template
  $('.response-template-select').change ->
    # get id of this select
    comment = $(this).find(":selected").attr("data-body")
    id = $(this).attr('id').replace('entry-email-response-to-customers-select_', '')
    $("#entry-email-response-to-customers_#{id}").val(comment)

  # Update individual response templates and text when a user selects a different resolution
  $('.resolution_radio_button').change ->
    resolution = $(this).val()
    lc_res = resolution.toLowerCase()
    entry_id = $(this).attr('id').replace(lc_res, '')
    get_resolution_templates(resolution, 'individual', [entry_id])


window.create_ind_res_dialogs = () ->
  fixed_res = []
  unchanged_res = []
  invalid_res = []

  $(".resolution-comment-dialog").each ->
    $(this).dialog
      autoOpen: false
      minWidth: 500
      classes: {
        "ui-dialog": "resolution-response-dialog"
      }
      close: () ->
        $('.resolution-comment-button').removeClass('active')

    # hide class keeps generated html from displaying before the dialogs are initialized
    $(this).removeClass('hide')

    # no need to call templates for submitted entries
    unless $(this).hasClass('submitted-resolution-dialog')
      entry_id = $(this).attr('id').replace('resolution_comment_dialog_', '')
      selected_res = $('[name="resolution' + entry_id + '"]:checked').val()
      if selected_res == 'FIXED'
        fixed_res.push(entry_id)
      else if selected_res == 'UNCHANGED'
        unchanged_res.push(entry_id)
      else
        invalid_res.push(entry_id)

  # grab needed templates once per needed resolution type
  if fixed_res.length > 0
    fixed_templates = get_resolution_templates('FIXED', 'individual', fixed_res)
  if unchanged_res.length > 0
    get_resolution_templates('UNCHANGED', 'individual', unchanged_res)
  if invalid_res.length > 0
    get_resolution_templates('INVALID', 'individual', invalid_res)





# fetches the resolution templates from the backend when called
window.get_resolution_templates = (resolution, dialog_type, entry_ids) ->
  std_msg_ajax(
    method: 'GET'
    url: "/escalations/api/v1/escalations/webcat/resolution_message_templates"
    data: {resolution: resolution}
    dataType: 'json'
    success_reload: false
    success: (response) ->
      templates = JSON.parse response

      template_options = ''
      text_area = ''
      email_text = ''

      # split out template options
      if templates.length > 0
        $(templates).each (index, template) ->
          template_option =
            "<option class='webcat-resolution-template-option' val='" + template.name +
            "' data-body='" + template.body +
            "' data-description='" + template.description + "' >" +
            template.name +
            "</option>"
          template_options = template_options + template_option
          email_text = templates[0].body
      else
        template_options = '<option>No templates available for ' + resolution + ' resolution</option>'

      # add to the dialogs
      if dialog_type == 'bulk'
        select = $('#email-response-to-customers-select')
        text_area = $("#email-response-to-customers")
        select.empty()
        select.append(template_options)
        $(text_area).val(email_text)

      else # dialog_type == 'individual'
        # add options to each dialog
        $(entry_ids).each ->
          entry_id = this
          select = $('#entry-email-response-to-customers-select_' + entry_id)
          text_area = $("#entry-email-response-to-customers_" + entry_id)
          select.empty()
          select.append(template_options)
          $(text_area).val(email_text)

      error: (response) ->
        std_api_error(response, "There was an error fetching the resolution message templates", reload: false)
  )
