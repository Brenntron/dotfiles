################################################################################
# FUNCTIONS FOR POPULATING THE TELEMETRY HISTORY MODAL
################################################################################

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
    console.log telemetry_data
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
      stateSave: false,
      responsive: false,
      autowidth: false,
      language:
        emptyTable: "No reputation history available for this dispute entry."
      initComplete: () ->
        expand_all_reputation_history_rows()
      columns: [
        {
          data: 'created_at',
          width: '90px',
          render: (data) ->
            if data
              return moment(data, "YYYY-MM-DD HH:mm").format("YYYY-MM-DD HH:mm")
            else return ''
        }
        {
          data: 'wbrs_score'
          render: (data, type, full) ->
            if !data && data != 0
              return ''
            else
              #show rule hits next to score if any
              if full.rule_hits?
                wrapper = "<span>#{data}</span>"
                rule_hits_parsed = JSON.parse(full.rule_hits)
                wbrs_rules = []
                $(rule_hits_parsed).each (i, rule) ->
                  if rule.rule_type == 'WBRS'
                    wbrs_rules.push rule.name

                if wbrs_rules.length > 0
                  wrapper += "<span class='dispute_reputation_history_cell_wrapper'>
                           <span class='reputation_history_rule_hits'>#{wbrs_rules.join(', ')}</span></span>"
                return wrapper
              else return data
        }
        {
          data: 'sbrs_score'
          render: (data, type, full) ->
            if !data && data != 0
              return ''
            else
              #show rule hits next to score if any
              if full.rule_hits?
                wrapper = "<span>#{data}</span>"
                rule_hits_parsed = JSON.parse(full.rule_hits)

                wbrs_rules = []
                $(rule_hits_parsed).each (i, rule) ->
                  if rule.rule_type == 'SBRS'
                    wbrs_rules.push rule.name

                if wbrs_rules.length > 0
                  wrapper += "<span class='dispute_reputation_history_cell_wrapper'>
                           <span class='reputation_history_rule_hits'>#{wbrs_rules.join(', ')}</span></span>"
                return wrapper
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
      ]

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

#set up the 'child' rows for each of the Repuation History rows of data
window.format_child_row = (data) ->
  multi_wbrs_score = ''
  multi_sbrs_score = ''
  multi_threat_categories = ''
  multi_wbrs_rule_hits = []
  multi_sbrs_rule_hits = []

  #note - multi_ip_score is only wbrs at the moment
  if data.multi_ip_score?
    multi_wbrs_score = "<span>#{data.multi_ip_score}</span>"

  if data.multi_rule_hits?
    parsed_multi_rule_hits = JSON.parse(data.multi_rule_hits)
    $(parsed_multi_rule_hits).each (i, rule) ->
      if rule.rule_type == 'WBRS'
        multi_wbrs_rule_hits.push rule.name
      else if rule.rule_type == 'SBRS'
        multi_sbrs_rule_hits.push rule.name

  if multi_wbrs_rule_hits.length > 0
    multi_wbrs_score += "<span class='dispute_reputation_history_cell_wrapper'>
             <span class='reputation_history_rule_hits'>#{multi_wbrs_rule_hits.join(', ')}</span></span>"

  if multi_sbrs_rule_hits.length > 0
    multi_sbrs_score += "<span class='dispute_reputation_history_cell_wrapper'>
             <span>#{multi_sbrs_rule_hits.join(', ')}</span></span>"

  if data.multi_threat_categories?
    multi_threat_categories = JSON.parse(data.multi_threat_categories).join(', ')

  return $("<tr><td class='reputation_history_resolved_ip'>+IP</td>
         <td>#{multi_wbrs_score}</td>
         <td>#{multi_sbrs_score}</td>
         <td>#{multi_threat_categories}</td>
         </tr>").toArray()

#the child rows need to be 'expanded' right before table is re-rendered
window.expand_all_reputation_history_rows = () ->
  table = $('#reputation-history-dialog-table').DataTable()
  table.rows().every ->
    this.child(format_child_row(this.data())).show()
    $(this.node()).addClass('shown')
  $('#reputation-history-dialog').dialog('open')
  table.columns.adjust().draw()
  #set width of first column after render - annoying workaround! Otherwise the width of the columns keeps resetting.
  $('#reputation-history-dialog-table th:first-of-type').width(90)

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
