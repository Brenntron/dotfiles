################################################################################
# FUNCTIONS FOR POPULATING THE ENRICH SECTION
################################################################################
#data is loaded separately and fed into the Research Data, similar to wbrs

window.get_enrichment_service = (query_item, query_type) ->
  data = {'query_item': query_item, 'query_type', query_type}
  std_msg_ajax(
    url: '/escalations/api/v1/escalations/cloud_intel/enrichment_service/query/'
    method: 'GET'
    data: data
    success: (response) ->
      return response
  )

window.setup_enrichment_section = () ->

  #TODO: determine query_type somehow?

  if $('#research-tab').length || $('.reputation-research-search-wrapper').length
    $('.research-table-row').each ->

      ip_uri = $(this).find('.entry-data-content').text().trim()
      # enrichment services uses a separate API call - needs to be handled w/ a js promise (1-2 sec lag)
      enrich_promise = new Promise (resolve, reject) ->
        enrich_json = get_enrichment_service(ip_uri)  # this is the actual api call
        if enrich_json then resolve enrich_json

      enrich_promise.then (result) ->
        console.log result
