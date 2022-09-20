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
        #multiple entries are possible in each so loop through to grab them all
        if response?.data?.context_tags.length > 0
          $(response.data.context_tags).each (index, tag) ->
            combined_tags = combined_tags.concat(tag)

        if response?.data?.email_context_tags.length > 0
          $(response.data.email_context_tags).each (index, tag) ->
            combined_tags = combined_tags.concat(tag)

        if response?.data?.web_context_tags.length > 0
          $(response.data.web_context_tags).each (index, tag) ->
            combined_tags = combined_tags.concat(tag)

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

            #look for any exteranl reference data
            combined_external_refs = []
            if tag.mapped_taxonomy?.external_references?
              if tag.mapped_taxonomy?.external_references.length > 0
                $(tag.mapped_taxonomy?.external_references).each (index, external_ref) ->
                  combined_external_refs = combined_external_refs.concat external_ref

            wrapper = $("<tr></tr>")
            name_wrapper = $("<td class='enrich-cell-name'></td>")
            $(name_wrapper).text(name) #escaping to prevent xss attacks

            description_wrapper = $("<td class='enrich-cell-description'></td>")
            $(description_wrapper).text(description) #escaping to prevent xss attacks

            external_ref_wrapper = $("<td class='enrich-cell-external-references'></td>")

            #if any external references are returned show column and append data
            if combined_external_refs.length > 0

              $('.enrich-webrep-external-references-col').show()

              $(combined_external_refs).each (index, external_ref) ->
                individual_wrapper = $("<span class='enrich-external-ref' id='enrich-external-ref-#{index}'></span>")
                link_wrapper = ''

                if external_ref.source?
                  source = external_ref.source
                else source = ''

                if external_ref.url?
                  url = external_ref.url
                else url = ''

                if source != '' && url != ''
                  link_wrapper = $("<a href=#{url} class='enrich-external-reference-link' target='blank'></a>")
                  $(link_wrapper).text(source)

                $(individual_wrapper).append link_wrapper
                $(external_ref_wrapper).append individual_wrapper

            #Create new row in Enrich table
            $(wrapper).append name_wrapper
            $(wrapper).append description_wrapper
            $(wrapper).append external_ref_wrapper
            $(table).append wrapper

        else
          $('.enrich-webrep-table-data-present').hide()
          $('.enrich-webrep-table-data-missing').show()
