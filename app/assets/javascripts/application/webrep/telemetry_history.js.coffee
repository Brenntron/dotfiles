################################################################################
# FUNCTIONS FOR POPULATING THE TELEMETRY HISTORY SECTION
################################################################################
#data is loaded separately and fed into the Research Data, similar to wbrs and Prevalence

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
      table = $(this).find('.telemetry-history-webrep-table-data-present')
      missing_data_table = $(this).find('.telemetry-history-webrep-table-data-missing')
      data_entry_id = $(this).attr('data-entry-id')

      telemetry_promise = new Promise (resolve, reject) ->
        telemetry_json = get_telemetry_history(data_entry_id)  # this is the actual api call
        if telemetry_json
          resolve telemetry_json

      telemetry_promise.then (response) ->
        telemetry_data = JSON.parse(response.data)
        if telemetry_data.length > 0

          #show populated table, hide empty one
          $(table).removeClass('hidden')
          $(missing_data_table).addClass('hidden')

          $(table).DataTable
            data: telemetry_data
            info: false,
            ordering: true,
            paging: false,
            searching: false,
            columns: [
              {
                searchable: true
                sortable: true
                data: 'created_at'
              }
              {
                data: 'rule_hits'
                render: (data, type, full, meta) ->
                  #figure out how to grab each rule hit
                  return data
              }
              {
                data: 'sbrs_score'
              }
              {
                data: 'wbrs_score'
              }
            ]

          #saving here in case I need this later
          $(telemetry_data).each (i, row) ->
            console.log row
            {
              created_at,
              dispute_entry_id,
              id,
              multi_ip_score,
              mutli_rule_hits,
              multi_threat_categories,
              original_snapshop,
              rule_hits,
              sbrs_score,
              threat_categories,
              wbrs_score
            } = row


$(document).ready( ()->
  setup_telemetry_section()
)
