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
      table = $(this).find('.enrich-webrep-table-data-present tbody')
      enrich_toolbar_cell = $(this).find('.enrich-cell')

      # enrichment services uses a separate API call - needs to be handled w/ a js promise (1-2 sec lag)
      enrich_promise = new Promise (resolve, reject) ->
        enrich_json = get_enrichment_service(ip_uri)  # this is the actual api call
        if enrich_json then resolve enrich_json

      enrich_promise.then (response) ->

        combined_tags = []

        #look for data in context_tags, email_context_tags and web_context_tags
        if response?.data?.context_tags.length > 0
          combined_tags = combined_tags.concat(response.data.context_tags)

        if response?.data?.email_context_tags.length > 0
          combined_tags = combined_tags.concat(response.data.email_context_tags)

        if response?.data?.web_context_tags.length > 0
          combined_tags = combined_tags.concat(response.data.web_context_tags)

        if combined_tags.length > 0
          $(combined_tags).each (index, tag) ->

            #get the Name and Description from each tag
            if tag.mapped_taxonomy?.name[0].text?
              name = tag.mapped_taxonomy.name[0].text
            else name = ''

            #set first returned name as toolbar value
            if index == 0
              $(enrich_toolbar_cell).text(name)

            if tag.mapped_taxonomy?.description[0].text?
              description = tag.mapped_taxonomy.description[0].text
            else description = ''

            wrapper = $("<tr></tr>")
            name_wrapper = $("<td class='enrich-cell-name'></td>")
            $(name_wrapper).text(name) #escaping to prevent xss attacks

            description_wrapper = $("<td class='enrich-cell-description'></td>")
            $(description_wrapper).text(description) #escaping to prevent xss attacks

            #Create new row in Enrich table
            $(wrapper).append name_wrapper
            $(wrapper).append description_wrapper
            $(table).append wrapper

        else
          $('.enrich-webrep-table-data-present').hide()
          $('.enrich-webrep-table-data-missing').show()
