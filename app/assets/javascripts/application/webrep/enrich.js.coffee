################################################################################
# FUNCTIONS FOR POPULATING THE WEBREP ENRICHMENT SECTION
################################################################################
#data is loaded separately and fed into the Research Data, similar to wbrs

#track first tag processed and show it as the Enrichment toolbar header status
create_index = 0

window.get_enrichment_service = (query_item, query_type) ->
  data = {'query_item': query_item, 'query_type', query_type}
  std_msg_ajax(
    url: '/escalations/api/v1/escalations/cloud_intel/enrichment_service/query/'
    method: 'GET'
    data: data
    success: (response) ->
      return response
  )

##create each enrichment section under webrep research tab
create_webrep_enrichment_section = (tags, context, enrich_toolbar_cell, table) ->

  $(tags).each (index, tag) ->
    name = ''
    description = ''
    taxonomy = ''

    if tag.mapped_taxonomy?.name[0].text?
      name = tag.mapped_taxonomy.name[0].text

    if tag.mapped_taxonomy?.description[0].text?
      description = tag.mapped_taxonomy.description[0].text

    if tag.taxonomy_name?
      taxonomy = tag.taxonomy_name

    create_index++
    #set first returned name as toolbar value
    if create_index == 1
      $(enrich_toolbar_cell).text(name)

    #look for any external reference data
    combined_external_refs = []
    if tag.mapped_taxonomy?.external_references?
      if tag.mapped_taxonomy?.external_references.length > 0
        $(tag.mapped_taxonomy?.external_references).each (index, external_ref) ->
          combined_external_refs = combined_external_refs.concat external_ref

    #create new table row
    wrapper = $("<tr></tr>")

    context_wrapper = $("<td class='enrich-cell-context'>#{context}</td>")

    taxonomy_wrapper = $("<td class='enrich-cell-taxonomy'></td>")
    $(taxonomy_wrapper).text(taxonomy) #escaping to prevent xss attacks

    name_wrapper = $("<td class='enrich-cell-name'></td>")
    $(name_wrapper).text(name) #escaping to prevent xss attacks

    description_wrapper = $("<td class='enrich-cell-description'></td>")
    $(description_wrapper).text(description) #escaping to prevent xss attacks

    external_ref_wrapper = $("<td class='enrich-cell-external-references'></td>")

    #if any external references are returned show column and append data
    if combined_external_refs.length > 0

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

    #Create new row in Enrichment table
    $(wrapper).append context_wrapper
    $(wrapper).append taxonomy_wrapper
    $(wrapper).append name_wrapper
    $(wrapper).append description_wrapper
    $(wrapper).append external_ref_wrapper
    $(table).append wrapper

window.setup_enrichment_section = () ->

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

        email_context_tags = []
        web_context_tags = []
        enrichment_context_tags = []

        #look for data in context_tags, email_context_tags and web_context_tags
        #multiple entries are possible in each so loop through to grab them all
        if response?.data?.email_context_tags.length > 0
          email_context_tags = response.data.email_context_tags

        if response?.data?.web_context_tags.length > 0
          web_context_tags = response.data.web_context_tags

        if response?.data?.context_tags.length > 0
          enrichment_context_tags = response.data.context_tags

        if email_context_tags.length > 0 || web_context_tags.length > 0 || enrichment_context_tags.length > 0

          if email_context_tags.length > 0
            create_webrep_enrichment_section(email_context_tags, 'Email',  enrich_toolbar_cell, table)

          if web_context_tags.length > 0
            create_webrep_enrichment_section(web_context_tags, 'Web',  enrich_toolbar_cell, table)

          #need to pass the tags, context, enrich_toolbar_cell and table to function
          if enrichment_context_tags.length > 0
            create_webrep_enrichment_section(enrichment_context_tags, 'Enrichment',  enrich_toolbar_cell, table)

        else
          $('.enrich-webrep-table-data-present').hide()
          $('.enrich-webrep-table-data-missing').show()
