################################################################################
# FUNCTIONS FOR POPULATING THE TELEMETRY HISTORY SECTION
################################################################################
#data is loaded separately and fed into the Research Data, similar to wbrs and Prevalence

window.get_reputation_history_data = (dispute_entry_id) ->
  std_msg_ajax(
    url: "/escalations/api/v1/escalations/webrep/disputes/get_telemetry_history/#{dispute_entry_id}"
    method: 'GET'
    success: (response) ->
      return response
    error: (response) ->
      std_msg_error('Error Gathering Telemetry data', [response.responseJSON.message])
  )

window.create_reputation_history_popup = (id, entry) ->

  get_reputation_history_data(id).then (response) ->
    telemetry_data = JSON.parse(response.data)
    table = $('#reputation-history-dialog-table')
    #Update modal title
    $('[aria-describedby="reputation-history-dialog"] .ui-dialog-title').text("Reputation History: #{entry}")

    $(table).DataTable
      data: telemetry_data
      info: false,
      ordering: true,
      destroy: true,
      paging: false,
      searching: false,
      language:
        emptyTable: "No reputation history available for this dispute entry."
      columns: [
        {
          data: 'created_at'
          render: (data) ->
            if data
              return moment(data, "YYYY-MM-DD HH:mm").format("YYYY-MM-DD HH:mm")
            else
              return ''
        }
        {
          data: 'wbrs_score'
          render: (data) ->
            if !data
              return "<span class='missing-data'>No score</span>"
            else return data
        }
        {
          data: 'sbrs_score'
          render: (data) ->
            if !data
              return "<span class='missing-data'>No score</span>"
            else return data
        }
        {
          data: 'threat_categories'
          render: (data) ->
            if data
              parsed = JSON.parse(data)
              parsed.join(', ')
            else return ''
        }
        {
          data: 'rule_hits'
          className: 'dispute_observable_history_rule_hits'
          render: (data) ->
            wrapper = ""
            parsed = JSON.parse(data)
            wbrs = []
            sbrs = []

            $(parsed).each (i, rule) ->
              if rule.rule_type == 'WBRS'
                wbrs.push rule.name
              else if rule.rule_type == 'SBRS'
                sbrs.push rule.name

            if wbrs.length > 0
              wrapper += "<div class='dispute_reputation_history_cell_wrapper'>
               <div>WBRS:</div><div>#{wbrs.join(', ')}</div></div>"

            if sbrs.length > 0
              wrapper += "<div class='dispute_reputation_history_cell_wrapper'>
               <div>SBRS:</div><div>#{sbrs.join(', ')}</div></div>"

            return wrapper
        }
        {
          data: 'multi_ip_score'
          render: (data) ->
            if !data
              return "<span class='missing-data'>No score</span>"
            else return data
        }
        {
          data: 'multi_rule_hits'
          className: 'dispute_observable_history_rule_hits'
          render: (data) ->
            wrapper = ""
            parsed = JSON.parse(data)
            wbrs = []
            sbrs = []

            $(parsed).each (i, rule) ->
              if rule.rule_type == 'WBRS'
                wbrs.push rule.name
              else if rule.rule_type == 'SBRS'
                sbrs.push rule.name

            if wbrs.length > 0
              wrapper += "<div class='dispute_reputation_history_cell_wrapper'>
               <div>WBRS:</div><div>#{wbrs.join(', ')}</div></div>"

            if sbrs.length > 0
              wrapper += "<div class='dispute_reputation_history_cell_wrapper'>
               <div>SBRS:</div><div>#{sbrs.join(', ')}</div></div>"

            return wrapper
        }
        {
          data: 'multi_threat_categories'
          render: (data) ->
            if data
              parsed = JSON.parse(data)
              parsed.join(', ')
            else return ''
        }
      ]

    $('#reputation-history-dialog').dialog('open')


window.get_reputation_history = () ->
  if ($('.dispute_check_box:checked').length == 1)
    id = $('.dispute_check_box:checked').attr('data-entry-id')
    wrapper = $('.dispute_check_box:checked').parents('.research-table-row-wrapper')[0]
    entry = $(wrapper).find('.entry-data-content')[0]
    entry_text = $(entry).text().trim()

    create_reputation_history_popup(id, entry_text)
  else if ($('.dispute_check_box:checked').length > 1)
    std_msg_error('Too many rows selected', ['A single row must be selected to view observable history'])
  else if ($('.dispute_check_box:checked').length < 1)
    std_msg_error('No rows selected', ['A single row must be selected to view observable history'])

$ ->
  ## init observable history dialog
  $('#reputation-history-dialog').dialog
    autoOpen: false,
    minWidth: 680,
    minHeight: 560,
    resizable: true,
    classes: {
      "ui-dialog": "form-dialog"
    },
    position: { my: "top center", at: "top center", of: window }
