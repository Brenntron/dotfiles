################################################################################
# FUNCTIONS FOR POPULATING THE TELEMETRY HISTORY SECTION
################################################################################
#data is loaded separately and fed into the Research Data, similar to wbrs and Prevalence

window.get_observable_history_data = (dispute_entry_id) ->
  std_msg_ajax(
    url: "/escalations/api/v1/escalations/webrep/disputes/get_telemetry_history/#{dispute_entry_id}"
    method: 'GET'
    success: (response) ->
      return response
    error: (response) ->
      std_msg_error('Error Gathering Telemetry data', [response.responseJSON.message])
  )

window.create_observable_history_popup = (id) ->

  get_observable_history_data(id).then (response) ->
    telemetry_data = JSON.parse(response.data)
    console.log telemetry_data
    table = $('#observable-history-dialog-table')

    $(table).DataTable
      data: telemetry_data
      info: false,
      ordering: true,
      paging: false,
      searching: false,
      columns: [
        {
          data: 'created_at'
        }
        {
          data: 'wbrs_score'
        }
        {
          data: 'sbrs_score'
        }
        {
          data: 'threat_categories'
        }
        {
          data: 'rule_hits'
          render: (data, type, full, meta) ->
            #figure out how to grab each rule hit
            return data
        }
        {
          data: 'multi_ip_score'
        }
        {
          data: 'multi_rule_hits'
        }
        {
          data: 'multi_threat_categories'
        }
      ]

    $('#observable-history-dialog').dialog('open')


window.get_observable_history = () ->
  if ($('.dispute_check_box:checked').length == 1)
    id = $('.dispute_check_box:checked').attr('data-entry-id')
    create_observable_history_popup(id)
  else if ($('.dispute_check_box:checked').length > 1)
    std_msg_error('Too many rows selected', ['A single row must be selected to view observable history'])
  else if ($('.dispute_check_box:checked').length < 1)
    std_msg_error('No rows selected', ['A single row must be selected to view observable history'])

$ ->
  ## init observable history dialog
  $('#observable-history-dialog').dialog
    autoOpen: false,
    minWidth: 520,
    minHeight: 560,
    resizable: false,

    classes: {
      "ui-dialog": "form-dialog"
    },
    position: { my: "top center", at: "top center", of: window }
