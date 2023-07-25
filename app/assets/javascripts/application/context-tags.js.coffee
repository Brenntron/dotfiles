# TMI AJAX - WEBREP AND FILEREP
# TMI AJAX - WEBREP AND FILEREP
window.tmi_ajax_get_data = (query_item) ->
  query_type = determine_string_type(query_item)  # will be ip, domain, url, or sha
  data = {
    "#{query_type}": query_item
  }
  std_msg_ajax
    url: '/escalations/api/v1/escalations/cloud_intel/tag_management/read_observable'
    method: 'GET'
    data: data
    success: (response) ->
#      console.log response
      { items } = response  # list of observables

      $(items).each (i, val) ->
        { tags } = this

        # tags array
        $(tags).each (i, val) ->
          { reports, taxonomy, taxonomy_entry, suppressed_by } = this

          # issue with indexing, below works to show full set
          unless i > $(tags).length - 1
            if !taxonomy_entry
              tag_name = ""
              tag_mnemonic = ""
            else
              if !taxonomy_entry.name
                tag_name = ""
              else
                tag_name = taxonomy_entry.name
              if !taxonomy_entry.mnemonic
                tag_mnemonic = ""
              else
                tag_mnemonic = taxonomy_entry.mnemonic

            if !taxonomy
              taxonomy_name = ""
            else
              taxonomy_name = taxonomy.name

            # suppressed_by itself could be null, empty strings for source/platform/date
            if !suppressed_by
              suppressed = "no"
              suppression_source = ""
              suppression_platform = ""
              suppression_date = ""
            else
              suppressed = "yes"  # if suppressed timestamp exists, then yes it was suppressed

              if !suppressed_by.source.source
                suppression_source = ""
              else
                suppression_source = suppressed_by.source.source

              if !suppressed_by.source.processor
                suppression_platform = ""
              else
                suppression_platform = suppressed_by.source.processor

              if !suppressed_by.suppressed_ts
                suppression_date = ""
              else
                # convert unix timecode to utc date/time
                suppression_date = moment.unix(suppressed_by.suppressed_ts).utc().format('YYYY-MM-DD hh:mm:ss')

          # start a new row
          report_tr = ""

          # each report generates a tmi table row
          $(reports).each ->
            { raw_observable, source, created_ts } = this
            { source, processor } = source

            # shas wont have raw_observable value, use the sha itself
            if !raw_observable && query_type == 'sha'
              raw_observable = query_item

            # convert unix timecode to utc date/time, created means when report was created
            report_date = moment.unix(created_ts).utc().format('YYYY-MM-DD hh:mm:ss')

            # one table row for each report
            report_tr =
              "<tr class='tmi-tr tmi-tr-suppressed-#{suppressed}'>
                 <td class='tmi-cb-cell'>
                   <input type='checkbox' class='tmi-cb'></input></td>
                 <td class='tmi-observable'>
                   <span class='observable-container esc-tooltipped' title='#{raw_observable}'>#{raw_observable}</span></td>
                 <td class='tmi-tag-name'>#{tag_name}</td>
                 <td class='tmi-mnemonic'>#{tag_mnemonic}</td>
                 <td class='tmi-taxonomy'>#{taxonomy_name}</td>
                 <td class='tmi-source'>#{source}</td>
                 <td class='tmi-processor'>#{processor}</td>
                 <td class='tmi-report-date'>#{report_date}</td>
                 <td class='tmi-suppressed tmi-red'>#{suppressed}</td>
                 <td class='tmi-suppression-source tmi-gray'>#{suppression_source}</td>
                 <td class='tmi-suppression-platform tmi-gray'>#{suppression_platform}</td>
                 <td class='tmi-suppression-date tmi-gray'>#{suppression_date}</td></tr>"

            # default is no with red cell and gray cells to the right
            if suppressed == 'yes'
              report_tr = report_tr.replace(/tmi-red/g,'')
              report_tr = report_tr.replace(/tmi-gray/g,'')

            # created ts is unique enough for now, fix this though to something even more unique
            $('.tmi-tbody').append(report_tr)  # add to dom


#    error: (response) ->
#      std_msg_error("Error", [response.responseJSON], reload: false)
#      console.log response



# WEBREP ENRICHMENT
# WEBREP ENRICHMENT (enrich and prev data come from same place)
window.enrich_ajax_webrep = (query_item, query_type) ->
  data = {'query_item': query_item, 'query_type': query_type}
  std_msg_ajax
    url: '/escalations/api/v1/escalations/cloud_intel/enrichment_service/query/'
    method: 'GET'
    data: data
    success: (response) ->
      return response


window.tmi_enrich_prev_dt_inits = (action, curr_entry) ->
  # are we updating existing stuff?
  if action == 'update'
    $('#tmi-dt').DataTable().destroy()
    $('#enrichment-dt').DataTable().destroy()
    $('#prevalence-dt').DataTable().destroy()
    $('.tmi-main-content, .enrichment-table, .prevalence-table').addClass('hidden')  # hide the tables in general
    $('.tmi-table tbody, .enrichment-table tbody, .prevalence-table tbody').empty()  # reset the table rows

  # tmi promise for that separate api call (sep from enrich api)
  tmi_promise = new Promise (resolve, reject) ->
    tmi_built = tmi_ajax_get_data(curr_entry)
    if tmi_built
      resolve tmi_built

  # when promised response comes back, continue with data
  tmi_promise.then (response) ->
    tmi_dt_init()  # ensure dt init after api call resolved

  # enrichment services uses a separate api call
  enrich_promise = new Promise (resolve, reject) ->
    enrich_json = enrich_ajax_webrep(curr_entry)
    if enrich_json
      resolve enrich_json

  enrich_promise.then (response) ->
    $('.enrichment-table, .prevalence-table, .tmi-main-content').removeClass('hidden')

    email_context_tags = []
    web_context_tags = []
    enrichment_context_tags = []

    #look for data in context_tags, email_context_tags and web_context_tags, multiple entries are possible in each so loop through to grab them all
    if response?.data?.email_context_tags.length > 0 then email_context_tags = response.data.email_context_tags
    if response?.data?.web_context_tags.length > 0 then web_context_tags = response.data.web_context_tags
    if response?.data?.context_tags.length > 0 then enrichment_context_tags = response.data.context_tags

    # create functions below do the add-to-dom
    if email_context_tags.length > 0 || web_context_tags.length > 0 || enrichment_context_tags.length > 0
      if email_context_tags.length > 0
        create_webrep_enrichment_section(email_context_tags, 'Email')

      if web_context_tags.length > 0
        create_webrep_enrichment_section(web_context_tags, 'Web')

      #need to pass the tags, context, enrich_toolbar_cell and table to function
      if enrichment_context_tags.length > 0
        create_webrep_enrichment_section(enrichment_context_tags, 'Enrichment')

    # prevalence data comes bundled with enrich data, may as well pass it from on here
    if response?.data?.prevalence?.responses?
      create_webrep_prevalence_section(response.data.prevalence.responses)

    # init the dts on ct tab now
    enrich_prev_dt_init()


window.create_webrep_enrichment_section = (tags, context) ->
  $('.enrichment-table').removeClass('hidden')
  enrich_tbody = $('.enrichment-table tbody')

  $(tags).each (index, tag) ->
    name = ''
    description = ''
    taxonomy = ''

    if tag.mapped_taxonomy?.name[0].text? then name = tag.mapped_taxonomy.name[0].text
    if tag.mapped_taxonomy?.description[0].text? then description = tag.mapped_taxonomy.description[0].text
    if tag.taxonomy_name? then taxonomy = tag.taxonomy_name

    #look for any external reference data
    combined_external_refs = []
    if tag.mapped_taxonomy?.external_references?
      if tag.mapped_taxonomy?.external_references.length > 0
        $(tag.mapped_taxonomy?.external_references).each (index, external_ref) ->
          combined_external_refs = combined_external_refs.concat external_ref

    #create new table row
    curr_row = $("<tr></tr>")
    context_cell = $("<td class='enrich-cell-context'>#{context}</td>")
    taxonomy_cell = $("<td class='enrich-cell-taxonomy'></td>")
    $(taxonomy_cell).text(taxonomy)

    name_cell = $("<td class='enrich-cell-name'></td>")
    $(name_cell).text(name)

    description_cell = $("<td class='enrich-cell-description'><p></p></td>")
    $(description_cell).find('p').text(description)

    external_ref_cell = $("<td class='enrich-cell-external-references'></td>")

    #if any external references are returned show column and append data
    if combined_external_refs.length > 0
      $(combined_external_refs).each (index, external_ref) ->
        individual_span = $("<span class='enrich-external-ref' id='enrich-external-ref-#{index}'></span>")
        link_wrapper = ''
        source = ''
        url = ''
        external_id = ''

        if external_ref.source? then source = external_ref.source
        if external_ref.url? then url = external_ref.url
        if external_ref.external_id? then external_id = external_ref.external_id

        if source != '' && url != ''
          link_tag = $("<a href=#{url} class='enrich-external-reference-link' target='blank'></a>")

          #use ID as link text if that is available
          if external_id != ''
            $(link_tag).text(external_id)
          else
            $(link_tag).text(source)

        $(individual_span).append(link_tag)
        $(external_ref_cell).append(individual_span)

    #Create new row in Enrichment table
    $(curr_row).append(context_cell)
    $(curr_row).append(taxonomy_cell)
    $(curr_row).append(name_cell)
    $(curr_row).append(description_cell)
    $(curr_row).append(external_ref_cell)

    # append a table row
    $(enrich_tbody).append(curr_row)  # ADD TO DOM


# WEBREP PREVALENCE
# WEBREP PREVALENCE
window.create_webrep_prevalence_section = (prevalence_data) ->
  $('.prevalence-table').removeClass('hidden')
  prevalence_tbody = $('.prevalence-table tbody')

  response_key = Object.keys(prevalence_data)[0]

  data = prevalence_data[response_key]
  if data.count != 0
    total_row = $("<tr></tr>")
    $(total_row).append($("<td>Total</td>"))

    total_count = $("<td></td>")
    $(total_count).text(data.count)
    $(total_row).append(total_count)

    total_first_seen = $("<td></td>")
    $(total_first_seen).text(data.first_seen)
    $(total_row).append(total_first_seen)

    total_last_seen = $("<td></td>")
    $(total_last_seen).text(data.last_seen)
    $(total_row).append(total_last_seen)

    $(prevalence_tbody).append(total_row)

    dataset_keys = Object.keys(data.datasets)

    for key in dataset_keys
      new_row = $("<tr></tr>")

      dataset = $("<td></td>")
      $(dataset).text(key)
      $(new_row).append(dataset)

      count = $("<td></td>")
      $(count).text(data.datasets[key].count)
      $(new_row).append(count)

      first_seen = $("<td></td>")
      $(first_seen).text(data.datasets[key].first_seen)
      $(new_row).append(first_seen)

      last_seen = $("<td></td>")
      $(last_seen).text(data.datasets[key].last_seen)
      $(new_row).append(last_seen)

      $(prevalence_tbody).append(new_row)


# FILEREP ENRICHMENT
# FILEREP ENRICHMENT
window.enrich_ajax_filerep = (sha256_hash) ->
  std_msg_ajax(
    method: 'GET'
    data: {'query_item': sha256_hash, 'query_type':'sha'}
    url: '/escalations/api/v1/escalations/cloud_intel/enrichment_service/query/'
    success_reload: false
    success: (response) ->
      email_context_tags = []
      web_context_tags = []
      enrichment_context_tags = []

      if response?.data?.email_context_tags.length > 0 then email_context_tags = response.data.email_context_tags
      if response?.data?.web_context_tags.length > 0 then web_context_tags = response.data.web_context_tags
      if response?.data?.context_tags.length > 0 then enrichment_context_tags = response.data.context_tags

      #check if any data returned and show section
      if email_context_tags.length > 0 || web_context_tags.length > 0 || enrichment_context_tags.length > 0
        if email_context_tags.length > 0 then create_filerep_enrich_section(email_context_tags, 'Email')
        if web_context_tags.length > 0 then create_filerep_enrich_section(web_context_tags, 'Web')
        if enrichment_context_tags.length > 0 then create_filerep_enrich_section(enrichment_context_tags, 'Enrichment')

      if response?.data?.prevalence?
        create_filerep_prevalence_section(response.data.prevalence.responses)

    error: (response) ->
      std_msg_error('Error with Enrichment Service', ['There was an error.'])

  )

window.create_filerep_enrich_section = (tags, context) ->
  #organize tags by taxonomy_id if there are multiple
  if tags.length > 1
    taxonomy_object = group_by_tag_filerep(tags, 'taxonomy_id')
    taxonomy_array = Object.entries(taxonomy_object)
  else taxonomy_array = [tags]

  #loop through each group of tags and put each in their own section
  $(taxonomy_array).each (i, group) ->

#single objects have different structure than multiple entries
    if group.length > 1
      tag_group = $(group)[1]
    else tag_group = group

    taxonomy_name = tag_group[0].taxonomy_name

    #create section wrapper
    section_wrapper = $("<div class='enrich-filerep-section-wrapper'></div>")
    section_header = "<h4 class='enrich-filerep-section-header data-report-label'>#{context}</h4>"
    taxonomy_header = "<div class='filerep-enrich-taxonomy-header-wrapper data-report-content'><label class='filerep-enrich-taxonomy-label'>Taxonomy:</label><h5 class='filerep-enrich-taxonomy-header'>#{taxonomy_name}</h5></div>"
    $(section_wrapper).append section_header
    $(section_wrapper).append taxonomy_header
    #create table wrapper
    table_wrapper = $("<table class='filerep-enrich-taxonomy-table data-report-table'></table>")

    #loop through each tag in group
    $(tag_group).each (index, tag) ->
      name = ''
      description = ''

      if tag.mapped_taxonomy?.name[0].text?
        name = tag.mapped_taxonomy.name[0].text

      if tag.mapped_taxonomy?.description[0].text?
        description = tag.mapped_taxonomy.description[0].text

      #look for any external reference data
      combined_external_refs = []
      if tag.mapped_taxonomy?.external_references?
        if tag.mapped_taxonomy?.external_references.length > 0
          $(tag.mapped_taxonomy?.external_references).each (index, external_ref) ->
            combined_external_refs = combined_external_refs.concat external_ref

      #create table header if first result
      if index == 0
        table_header = "<tr class='filerep-enrich-table-header-row'><th class='filerep-enrich-table-name-th'>Name</th><th class='filerep-enrich-table-description-th'>Description</th><th class='filerep-enrich-table-external-ref-th'>External Ref</th></tr>"
        $(table_wrapper).append table_header

      name_wrapper = $("<td class='filerep-enrich-cell-name'></td>")
      $(name_wrapper).text(name)
      description_wrapper = $("<td class='filerep-enrich-cell-description'><p></p></td>")
      $(description_wrapper).find('p').text(description)
      external_ref_wrapper = $("<td class='filerep-enrich-cell-external-references'></td>")

      row_wrapper = $("<tr class='filerep-enrich-table-body-row'></tr>")
      $(row_wrapper).append name_wrapper
      $(row_wrapper).append description_wrapper
      $(row_wrapper).append external_ref_wrapper

      #if any external references are returned show column and append data
      if combined_external_refs.length > 0
        $('.enrich-webrep-external-references-col').show()
        $(combined_external_refs).each (index, external_ref) ->
          individual_wrapper = $("<span class='filerep-enrich-external-ref' id='filerep-enrich-external-ref-#{index}'></span>")
          link_wrapper = ''
          source = ''
          url = ''
          external_id = ''

          if external_ref.source?
            source = external_ref.source

          if external_ref.url?
            url = external_ref.url

          if external_ref.external_id?
            external_id = external_ref.external_id

          if source != '' && url != ''

            link_wrapper = $("<a href=#{url} class='filerep-enrich-external-reference-link' target='blank'></a>")

            #use ID as link text if that is available
            if external_id != ''
              $(link_wrapper).text(external_id)
            else
              $(link_wrapper).text(source)

          $(individual_wrapper).append(link_wrapper)
          $(external_ref_wrapper).append(individual_wrapper)

      $(table_wrapper).append(row_wrapper)

    $(section_wrapper).append(table_wrapper)


    $('.enrichment-area').append(section_wrapper)  # add to dom



# FILEREP PREVALENCE
# FILEREP PREVALENCE
window.create_filerep_prevalence_section = (prevalence_data) ->
  response_key = Object.keys(prevalence_data)[0]
  data = prevalence_data[response_key]
  if data.count == 0
    $('.prevalence-filerep-data-missing').show()
  else
    total_section_wrapper = $("<div class='enrich-filerep-section-wrapper'></div>")
    table_wrapper = $("<table class='data-report-table'></table>")
    table_body = $("<tbody></tbody>")
    table_header = "<thead><tr class='filerep-enrich-table-header-row'><th class='filerep-prevalence-table-count-th'>Count</th><th class='filerep-prevalence-table-first-seen-th'>First Seen</th><th class='filerep-prevalence-table-last-seen-th'>Last Seen</th></tr></thead>"
    $(table_wrapper).append table_header

    total_row = $("<tr></tr>")

    total_count_td = $("<td></td>")
    $(total_count_td).text(data.count)
    $(total_row).append(total_count_td)

    total_first_seen_td = $("<td></td>")
    $(total_first_seen_td).text(data.first_seen)
    $(total_row).append(total_first_seen_td)

    total_last_seen_td = $("<td></td>")
    $(total_last_seen_td).text(data.last_seen)
    $(total_row).append(total_last_seen_td)

    $(table_body).append(total_row)
    $(table_wrapper).append(table_body)
    $(total_section_wrapper).append(table_wrapper)

    $('.prevalence-area').append(total_section_wrapper)

    dataset_section_wrapper = $("<div class='enrich-filerep-section-wrapper'></div>")
    dataset_section_header = "<h4 class='enrich-filerep-section-header data-report-label'>Datasets</h4>"
    $(dataset_section_wrapper).append(dataset_section_header)
    dataset_table_wrapper = $("<table class='data-report-table'></table>")
    dataset_table_body = $("<tbody></tbody>")

    table_header = "<thead><tr class='filerep-enrich-table-header-row'><th class='filerep-prevalence-table-dataset-th'>Dataset</th><th class='filerep-prevalence-table-disposition-th'>Disposition</th><th class='filerep-prevalence-table-count-th'>Count</th><th class='filerep-prevalence-table-first-seen-th'>First Seen</th><th class='filerep-prevalence-table-last-seen-th'>Last Seen</th></tr></thead>"
    $(dataset_table_wrapper).append(table_header)
    dataset_keys = Object.keys(data.datasets)

    for key in dataset_keys
      dispositions = data.datasets[key].dispositions
      disposition_keys = Object.keys(dispositions)

      for d_key in disposition_keys
        dataset_row = $("<tr></tr>")

        dataset_td = $("<td class='filerep-prevalence-table-dataset-td'></td>")
        $(dataset_td).text(key)
        $(dataset_row).append(dataset_td)

        dataset_disposition_td = $("<td class='filerep-prevalence-table-disposition-td'></td>")
        $(dataset_disposition_td).text(d_key)
        $(dataset_row).append(dataset_disposition_td)

        dataset_count_td = $("<td class='filerep-prevalence-table-count-td'></td>")
        $(dataset_count_td).text(dispositions[d_key].count)
        $(dataset_row).append(dataset_count_td)

        dataset_first_seen_td = $("<td class='filerep-prevalence-table-first-td'></td>")
        $(dataset_first_seen_td).text(dispositions[d_key].first_seen)
        $(dataset_row).append(dataset_first_seen_td)

        dataset_last_seen_td = $("<td class='filerep-prevalence-table-last-td'></td>")
        $(dataset_last_seen_td).text(dispositions[d_key].last_seen)
        $(dataset_row).append(dataset_last_seen_td)

        $(dataset_table_body).append(dataset_row)

    $(dataset_table_wrapper).append(dataset_table_body)
    $(dataset_section_wrapper).append(dataset_table_wrapper)

    $('.prevalence-area').append(dataset_section_wrapper)  # add to dom

    # init the enrich and prev tables now that both exist
    enrich_prev_dt_init()


# group taxonomies by id for enrichment section on filerep
window.group_by_tag_filerep = (array, key) ->
  array.reduce (acc, obj) ->
    property = obj[key]
    acc[property] = acc[property] || []
    acc[property].push obj
    acc
  , {}



# init the tmi dt (save to var for col toggling), applies to webrep + filerep
window.tmi_dt_init = () ->
  tmi_table = $('#tmi-dt').DataTable
    paging: false
    searching: false
    info: false
    order: [[ 7, 'desc']]
    columnDefs: [
      {
        targets: [ 0 ]
        orderable: false
        sortable: false
      }
    ]

  # show or hide columns in tmi table
  $('.toggle-col-tmi').each ->
    checkbox = $(this).find('input')
    column = tmi_table.column($(this).attr('data-column'))  # uses tmi_table defined above
    if $(checkbox).prop('checked') then column.visible(true)
    else column.visible(false)
    # click anywhere in the li to toggle
    $(this).click ->
      $(checkbox).prop('checked', !checkbox.prop('checked'))
      column.visible(!column.visible())
    # or click the cb specifically to toggle
    $(checkbox).click ->
      $(checkbox).prop('checked', !checkbox.prop('checked'))


# init the enrichment and prevalence dts
window.enrich_prev_dt_init = () ->
  $('.enrichment-loader, .prevalence-loader, .tmi-loader').addClass('hidden')  # remove all loaders

  # dt inits for enrich and prev dts for webrep, and only if not already inited
  if $('.tab-ctt-webrep').length > 0
    $('#enrichment-dt').DataTable
      paging: false
      searching: false
      info: false

    $('#prevalence-dt').DataTable
      paging: false
      searching: false
      info: false



# determine if a string is an ip/url/domain/sha, return the type
window.determine_string_type = (curr_string) ->
  ip_regex = /^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$/gi
  sha_regex = /^[a-f0-9]{64}$/gi

  # add ip v6 handling later on when needed
  if ip_regex.test(curr_string) == true
    return 'ip'
  else if sha_regex.test(curr_string) == true
    return 'sha'
  else if curr_string.includes('.') && !curr_string.includes('/')
    return 'domain'   # at least one dot and no slash indicates domain
  else
    return 'url'



# HOUSEKEEPING STUFF, MOVE THIS INTO A FUNCTION BELOW
$ ->
  # webrep - tmi page load on webrep, we need the first ip/domain/url entry on this case
  if $('.tab-ctt-webrep').length > 0
    if $('.top-case-info .dispute-entry-ip-uri').length > 0
      curr_entry = $('.top-case-info .dispute-entry-ip-uri').text().trim()  # get url or ip
      tmi_enrich_prev_dt_inits('update', curr_entry)  # do enrich and prev stuff

    # on webrep, if user clicks the 'select an entry' element
    $('.tab-ctt-webrep .ctt-entry-select').change ->
      $('.tmi-loader, .enrichment-loader, .prevalence-loader').removeClass('hidden')
      curr_entry = $(this).find('option:selected').attr('data-entry')
      tmi_enrich_prev_dt_inits('update', curr_entry)  # do enrich and prev stuff

    # select - build options for choose-an-entry
    $('.research-table-row').each ->
      curr_entry = $(this).find('.entry-data-content').text().trim()  # entry can be url/ip/domain
      curr_option = "<option class='mult-entry-option' data-entry='#{curr_entry}'>#{curr_entry}</option>"
      $(".ctt-entry-select").append(curr_option)

    # show the choose-an-entry if multiple entries exist on webrep dispute case
    entries_str = $('.top-case-info .dispute-entry-count').text().trim()
    entries_num = parseInt(entries_str)
    if entries_num > 1
      $('.ctt-choose-an-entry').removeClass('hidden')


  # filerep - tmi kick things off on filerep, we need the sha (one sha per dispute)
  else if $('.tab-ctt-filerep').length > 0
    curr_entry = $('#sha256_hash').text().trim()  # get url or ip
    tmi_enrich_prev_dt_inits('initial', curr_entry)


# initialize and open the tags dialog
window.add_context_tags_dialog = () ->
  # open the dialog
  $('#add-context-tags-dialog').dialog('open')

  # no need to re-run ajax if already exists in dom
  unless $('.tab-context-tags').hasClass('tags-dialog-built')
    # ajax call to get list of taxonomies
    std_msg_ajax
      url: '/escalations/api/v1/escalations/cloud_intel/tag_management/taxonomy_map'
      method: 'GET'
      error: (response) ->
        $('.actd-loader-area').addClass('hidden')
        $('.actd-error-area').removeClass('hidden')

      success: (response) ->
        console.clear()
        console.log 'TAXONOMY DATA BELOW'
        console.log response

        # hide loader, show main content
        $('.actd-loader-area').addClass('hidden')
        $('.actd-tags-area').removeClass('hidden')

        # all the top-level taxonomies
        { taxonomies } = response

        all_tag_rows_html = ''

        # for each taxonomy, add an <option> and a <div> with taxonomy entries
        $(taxonomies).each (i, val) ->
          { name, entries, taxonomy_id } = this
          taxonomy_name = name

          # taxonomy select - add an <option> first
          taxonomy_option = "<option class='taxonomy-#{taxonomy_id}' data-id='#{taxonomy_id}'>#{name}</option>"
          $('.taxonomy-select').append(taxonomy_option)

          curr_taxonomy_rows_html = ''

          # taxonomy div - add all the entries for this taxonomy
          $(entries).each ->
            { entry_id, name, description, mnemonic, short_description } = this

            # full id for an entry is taxonomy_id and entry_id combined, this becomes the unique identifier
            full_id = "#{taxonomy_id}-#{entry_id}"

            if !description then description = ''



            entry_tr =
              "<tr class='tag-entry-row tag-#{full_id} taxonomy-row taxonomy-row-#{taxonomy_id}'>
                 <td class='tag-cb-col'>
                   <input class='tag-entry-cb tag-entry-cb-#{full_id}' type='checkbox' data-tax-id='#{taxonomy_id}' data-tax-name='#{taxonomy_name}' data-entry-name='#{name}' data-entry-id='#{entry_id}' onclick='add_preview_tag(\"#{full_id}\");'></td>
                 <td class='tag-name-col'><p class='tag-entry-name'>#{name}</p></td>
                 <td class='tag-mnemonic-col'><p class='tag-entry-mnemonic'>#{mnemonic}</p></td>
                 <td class='tag-taxonomy-col'><p class='tag-entry-taxonomy'>#{taxonomy_name}</p></td>
                 <td class='tag-desc-col'>
                   <p class='tag-mitre-fqn hidden'>#{short_description}</p>
                   <p class='tag-entry-description'>#{description}</p>
                   <button class='read-more-button hidden' onclick='mitre_read_more(\"#{full_id}\");'>Read More <span class='down-caret'></span></button>
                 </td>
               </tr>"


            # mitre descriptions are huge, show the mitre fqn (short_desc) and show the read more button
            if taxonomy_name.includes('MITRE') && short_description
              entry_tr = entry_tr.replace('tag-mitre-fqn hidden','tag-mitre-fqn')
              # show read more button if the description is verbose
              if description.length > 200
                entry_tr = entry_tr.replace('tag-entry-description','tag-entry-description condensed')
                entry_tr = entry_tr.replace('read-more-button hidden','read-more-button')

            all_tag_rows_html += entry_tr  # build one block of html


        
        # add one big string at once, less interaction with dom == better performance
        $('.tag-entries-area .taxonomy-table tbody').append(all_tag_rows_html)  # ADD TO DOM

        # open the dialog and dt init with all tags showing
        taxonomy_dt_init()

        # add flag to dom that the dialog is now built
        $('.tab-context-tags').addClass('tags-dialog-built')



# TAG PREVIEW CLICK HANDLERS AND STUFF
window.add_preview_tag = (curr_tag_id) ->
  # if preview tag already showing and tag cb is clicked, hide that preview tag
  if $(".tag-entry-cb-#{curr_tag_id}").prop('checked') == false && $(".preview-tag-#{curr_tag_id}").length > 0
    $(".preview-tag-#{curr_tag_id}").remove()
  else
    # stop at 5 tags to be added at once
    if $('.preview-tag-area .preview-tag').length == 5 && $('.tag-entry-cb:checked').length == 5
      std_msg_error("Maximum of 5 new tags at once.","")

    else
      $('.tag-entry-cb:checked').each ->
        taxonomy_id = $(this).attr('data-tax-id')
        taxonomy_name = $(this).attr('data-tax-name')
        entry_name = $(this).attr('data-entry-name')  # tag name is entry name
        entry_id = $(this).attr('data-entry-id')
        full_id = "#{taxonomy_id}-#{entry_id}"

        # BUILD PREVIEW TAG
        new_entry = "<div class='preview-tag preview-tag-#{full_id}' data-tax-id='#{taxonomy_id}' data-entry-id='#{entry_id}'><span class='preview-tag-name'>#{taxonomy_name}: #{entry_name}</span> <a href='javascript:void(0);' class='preview-tag-close' data-full-id='#{full_id}' title='Remove'>×</a></div>"

        # ensure no duplicate tags added
        unless $(".preview-tag-area .preview-tag-#{full_id}").length > 0
          # ADD PREVIEW TAG
          $('.preview-tag-area').append(new_entry)  # add to dom

        # PREVIEW TAG CLOSE BUTTON NOW EXISTS IN DOM, ATTACH HANDLER
        # on close click, uncheck the id for that cb
        $('.preview-tag-close').click ->
          $(this).closest('.preview-tag').remove()  # remove from dom first

          full_id = $(this).attr('data-full-id')  # uncheck the cb after
          $(".tag-entry-cb-#{full_id}").prop('checked', false)




# dt init the taxonomy table on initial load or change select
window.taxonomy_dt_init = () ->
  # show all seven thousand tag rows by default
  unless $(".taxonomy-table").hasClass('dataTable')
    taxonomy_table = $(".taxonomy-table").DataTable
#      dom: '<"datatable-top-tools no-margin-datatable-top-tool"lf>t<ip>'
      dom: 'lftpir'
      columnDefs: [
        {
          targets: [0]
          orderable: false
          sortable: false
        }
      ]
      order: [[1, 'asc']]
      pageLength: 10
      language: {
        search: "Tag Search"
        searchPlaceholder: "Search"
        zeroRecords: "No matching tags found"
      }

    # select change does a search and draw
    $('.taxonomy-select').change ->
      new_text = $(this).find('option:selected').text()
      taxonomy_table.columns(3).search(new_text).draw()




# read more button for mitre descriptions in dialog
window.mitre_read_more = (full_id) ->
  $(".tag-#{full_id} .tag-entry-description").toggleClass('condensed')
  $(".tag-#{full_id} .read-more-button .down-caret").toggleClass('expanded')


$ ->
  # cancel button for tags dialog
  $('.tags-cancel-button').click ->
    $('#add-context-tags-dialog').dialog('close')




# add the tag of 'dns' in taxonomy of 'intelligence types' to observable of 'cisco.com'
# actions can be 'add', 'delete', 'suppress_tag', or 'unsuppress_tag', multiple actions allowed at once
window.tags_action = (action) ->
  #  action will be add/suppress/unsuppress/delete
  console.log 'tag action to do:'
  console.log action

  # if preview tags are visible, proceed with everything
  if $('.preview-tag:visible').length == 0
    std_msg_error('No tag selected', ['Please select at least one tag.'])

  # if preview tags are visible, proceed with everything
  else if $('.preview-tag:visible').length > 0
    switch action
      when 'add' then success_msg = "Tags added to observable"
      when 'suppress' then success_msg = "Tags suppressed"
      when 'unsuppress' then success_msg = "Tags unsuppressed"
      when 'delete' then success_msg = "Tags removed from observable"

    data = {}
    items = []

    # all of below is set up for ADD tags
    # logic will need to be adjusted for suppress/remove/etc

    # every existing tag preview to be added
    $('.preview-tag-area .preview-tag').each ->
      tax_id = parseInt($(this).attr('data-tax-id'))  # endpoint needs ints
      entry_id = parseInt($(this).attr('data-entry-id'))
      curr_observable = $('.ctt-entry-select option:selected').text().trim()  # this works even when hidden

      # make tags array dynamic
      observable_type = determine_string_type(curr_observable)  # ip or sha or url or domain

      # add new item object to add to array, 'add' can change action to suppress or remove
      new_item = {
        "#{observable_type}": curr_observable
        action: action
        tags: [
          {
            taxonomy_id: tax_id
            taxonomy_entry_id: entry_id
          }
        ]
      }

      items.push(new_item)

    data.items = items

    console.log 'HERE IS YOUR DATA'
    console.log data

    # data is finished construction, send to endpoint with action specified
    std_msg_ajax
      url: '/escalations/api/v1/escalations/cloud_intel/tag_management/update_by_context'
      method: 'POST'
      data: data
      success: (response) ->
        $('#add-context-tags-dialog').dialog('close')
        std_msg_success("Success", ["#{success_msg}. Reloading page."], reload: true)



# FIX THIS, dry out and add label handler
$ ->
  $('.suppressed-context-tags-toggle').click ->
    if $(this).find('input:checkbox').prop('checked') == true
      $('.tmi-tr-suppressed-yes').removeClass('hidden')
    else
      $('.tmi-tr-suppressed-yes').addClass('hidden')

  $('.unsuppressed-context-tags-toggle').click ->
    if $(this).find('input:checkbox').prop('checked') == true
      $('.tmi-tr-suppressed-no').removeClass('hidden')
    else
      $('.tmi-tr-suppressed-no').addClass('hidden')



# tags dialog jquery init here
$ ->
  $('#add-context-tags-dialog').dialog(
    autoOpen: false
    dialogClass: 'add-context-tags-dialog'
    width: 1200
    height: 500
    minWidth: 1000
    minHeight: 500
  )

