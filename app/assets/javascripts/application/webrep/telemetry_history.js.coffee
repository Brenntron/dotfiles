################################################################################
# FUNCTIONS FOR POPULATING THE TELEMETRY HISTORY SECTION
################################################################################
#data is loaded separately and fed into the Research Data, similar to wbrs and Enrichment

window.get_telemetry_history = (dispute_entry_id) ->
  std_msg_ajax(
    url: "/escalations/api/v1/escalations/webrep/disputes/get_telemetry_history/#{dispute_entry_id}"
    method: 'GET'
    success: (response) ->
      return response
    error: (response) ->
      std_msg_error('Error Gathering Telemetry data', [response.responseJSON.message])
  )


window.setup_telemetry_section = () ->
  if $('#research-tab').length || $('.reputation-research-search-wrapper').length
    $('.research-table-row').each ->
      table_body = $(this).find('.telemetry-history-webrep-table-data-present tbody')
      data_entry_id = $(this).attr('data-entry-id')

      # enrichment services uses a separate API call - needs to be handled w/ a js promise (1-2 sec lag)
      telemetry_promise = new Promise (resolve, reject) ->
        telemetry_json = get_telemetry_history(data_entry_id)  # this is the actual api call
        if telemetry_json
          resolve telemetry_json

      telemetry_promise.then (response) ->

        console.log response.data
        data = JSON.parse(response.data)
        console.log data
        if data.length > 0
          $(data).each (i, row) ->
            console.log row
            console.log row.rule_hits





$(document).ready( ()->
  setup_telemetry_section()
)
