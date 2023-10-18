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


# Whois lookup dialog
window.domain_whois = (IP_Domain) ->
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/escalations/api/v1/escalations/webcat/complaint_entries/domain_whois'
    method: 'POST'
    headers: headers
    data: {'lookup': IP_Domain}
    success: (response) ->
      info = $.parseJSON(response)
      if info.error
        notice_html = "<p>Something went wrong: #{info.error}</p>"
        alert(info.error)
      else
        dialog_content = $(format_domain_info(info))
        if $("#complaint_button_dialog").length
          complaint_dialog = this

          $('#complaint_button_dialog').html("")
          $('body').innerHTML=""

          $('body').append(complaint_dialog)
          $('#complaint_button_dialog').append(dialog_content[0])
          $('#complaint_button_dialog').dialog
            autoOpen: true
            minWidth: 400
            position: { my: "right bottom", at: "right bottom", of: window }
        else
          complaint_dialog = '<div id="complaint_button_dialog" title="Domain Information"></div>'
          $('body').append(complaint_dialog)
          $('#complaint_button_dialog').append(dialog_content[0])
          $('#complaint_button_dialog').dialog
            autoOpen: true
            minWidth: 400
            position: { my: "right bottom", at: "right bottom", of: window }
    error: (response) ->
      notice_html = "<p>Something went wrong: #{response.responseText}</p>"
  , this)


name_servers =(server_list)->
  if undefined == server_list
    ''
  else
    text = ""
    for server in server_list
      text += server + '<br>'
    text

format_domain_info = (info)->
  '<div class="dialog-content-wrapper">' +
    '<h5>Domain Name</h5>' +
    '<p>' + info['domain'] + '</p>' +
    '<hr class="thin">' +
    '<h5>Registrant </h5>' +
    '<table class="nested-dialog-table">' +
    '<tr>' +
    '<td class="table-side-header">' +
    'Organization' +
    '</td>' +
    '<td>' +
    info['organisation'] +
    '</tr><tr>' +
    '<td class="table-side-header">' +
    'Country' +
    '</td>' +
    '<td>' +
    info['registrant_country'] +
    '</td>' +
    '</tr><tr>' +
    '<td class="table-side-header">' +
    'State/Province' +
    '</td>' +
    '<td>' +
    info['registrant_state/province'] +
    '</td>' +
    '</tr>' +
    '</table>' +
    '<hr class="thin">' +
    '<h5>Name Servers</h5>'+
    name_servers(info['nserver']) +
    '<hr class="thin">' +
    '<h5> Dates</h5>'+
    '<table class="nested-dialog-table">' +
    '<tr>' +
    '<td class="table-side-header">' +
    'Created' +
    '</td>' +
    '<td>' + info['created'] + '</td>'+
    '</tr><tr>' +
    '<td class="table-side-header">' +
    'Last updated' +
    '</td>' +
    '<td>' +
    info['changed'] +
    '</td>' +
    '</tr><tr>' +
    '<td class="table-side-header">' +
    'Expiry_date' +
    '</td>' +
    '<td>' +
    info['registry_expiry_date'] +
    '</td>' +
    '</tr>' +
    '</table>' +
    '</div>'


