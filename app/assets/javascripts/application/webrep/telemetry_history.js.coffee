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


window.get_observable_history = () ->
  if ($('.dispute_check_box:checked').length == 1)
    id = $('.dispute_check_box:checked').attr('data-entry-id')
    create_observable_history_popup(id)
  else if ($('.dispute_check_box:checked').length > 1)
    std_msg_error('Too many rows selected', ['A single row must be selected to view observable history'])
  else if ($('.dispute_check_box:checked').length < 1)
    std_msg_error('No rows selected', ['A single row must be selected to view observable history'])