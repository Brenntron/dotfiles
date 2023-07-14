# WEBREP TMI
# WEBREP TMI

# part 1 of tmi
window.tmi_ajax_webrep = (query_item) ->
  query_type = determine_string_type(query_item)

  switch query_type
    when 'ip' then data = { ip: query_item }
    when 'domain' then data = { domain: query_item }
    when 'sha' then data = { sha: query_item }
    when 'url' then data = { url: query_item }

  std_msg_ajax
    url: '/escalations/api/v1/escalations/cloud_intel/tag_management/read_observable'
    method: 'GET'
    data: data
    success: (response) ->
#      console.log response
#      observable = tag_name = mnemonic = taxonomy = source = processor = report_date = suppressed = suppression_source = suppression_platform = suppression_date = ''

      # list of observables
      { items } = response

      # if no items exist, show the no-data message
      if !items
        $('.tmi-main-content').addClass('hidden')
      else
        $('.tmi-main-content').removeClass('hidden')

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
              "<tr class='tmi-tr'>
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
            $('.tmi-tbody').append(report_tr)

#    error: (response) ->
#      std_msg_error("Error", [response.responseJSON], reload: false)
#      console.clear()
#      console.log 'ERROR ON TMI LOOKUP'
#      console.log response



# WEBREP ENRICHMENT
# WEBREP ENRICHMENT

# part 1 of enrichment (enrich and prev data come from same place)
window.enrich_ajax_webrep = (query_item, query_type) ->
  data = {'query_item': query_item, 'query_type': query_type}
  std_msg_ajax
    url: '/escalations/api/v1/escalations/cloud_intel/enrichment_service/query/'
    method: 'GET'
    data: data
    success: (response) ->
      return response
    complete: () ->
      $('.enrichment-loader, .prevalence-loader').addClass('hidden')


# part 2 of enrichment, set up enrichment based on url passed in
window.setup_context_tables_webrep = (action) ->
  # clear inited datatables to cleanly reinit on data refresh
  if $('.tab-context-tags').hasClass('dt-inited')
    $('#webrep-tmi-dt').DataTable().destroy()
    $('#webrep-enrichment-dt').DataTable().destroy()
    $('#webrep-prevalence-dt').DataTable().destroy()

  # are we updating existing stuff?
  if action == 'update'
    # hide the tables in general
    $('.tmi-main-content, .enrichment-table, .prevalence-table').addClass('hidden')
    $('.tmi-loader, .enrichment-loader, .prevalence-loader').removeClass('hidden')

    # reset the tables
    $('.tmi-table tbody, .enrichment-table tbody, .prevalence-table tbody').empty()

    # use this url or ip
    entry = $('.ctt-entry-select option:selected').attr('data-entry')

  # if not an update action, its a first action
  else
    entry = $(".research-table-row:first").find(".entry-data-content").text().trim()

  # enrichment services uses a separate api call - needs to be handled w/ a js promise (2-3 sec lag)
  enrich_promise = new Promise (resolve, reject) ->
    enrich_json = enrich_ajax_webrep(entry)  # this is the actual api call
    if enrich_json
      resolve enrich_json

  # when promised response comes back, continue with data
  enrich_promise.then (response) ->
    $('.tmi-main-content, .enrichment-table, .prevalence-table').removeClass('hidden')

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
    tmi_enrich_prev_dt_inits()


# part 3 of enrichment
window.create_webrep_enrichment_section = (tags, context) ->
  $('.webrep-enrichment-table').removeClass('hidden')
  enrich_tbody = $('.webrep-enrichment-table tbody')

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
  $('.webrep-prevalence-table').removeClass('hidden')
  prevalence_tbody = $('.webrep-prevalence-table tbody')

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



# FILEREP ENHANCEMENT
# FILEREP ENHANCEMENT
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

# part 2
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
    tmi_enrich_prev_dt_inits()


# group taxonomies by id for enrichment section on filerep
window.group_by_tag_filerep = (array, key) ->
  array.reduce (acc, obj) ->
    property = obj[key]
    acc[property] = acc[property] || []
    acc[property].push obj
    acc
  , {}



# init these dts, keep in sep function for when promise resolves elsewhere (api call is delayed).
window.tmi_enrich_prev_dt_inits = () ->
  $('.tmi-loader, .enrichment-loader, .prevalence-loader').addClass('hidden')  # remove loaders

  # FIX THIS, SETTIMEOUT IS HACKY
  # FIX THIS, SETTIMEOUT IS HACKY
  # tiny delay to ensure tmi data exists before dt init
  setTimeout ->
    # dt init the tmi dt (and save to a var for col toggling)
    tmi_table = $('#webrep-tmi-dt').DataTable
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
    # tmi_table from above is used below, show or hide columns in tmi table
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
  , 2000


  # dt init the enrich dt
  $('#webrep-enrichment-dt').DataTable
    paging: false
    searching: false
    info: false

  # dt init the prev dt
  $('#webrep-prevalence-dt').DataTable
    paging: false
    searching: false
    info: false

  # set a dom flag that dts have been inited, so we can re-init properly on change entry
  if $('.tab-context-tags').hasClass('dt-inited') == false
    $('.tab-context-tags').addClass('dt-inited')



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
  # webrep - tmi kick things off on webrep, we need the first ip/domain/url entry on this case
  if $('.tab-ctt-webrep').length > 0
    if $('.top-case-info .dispute-entry-ip-uri').length > 0
      top_url = $('.top-case-info .dispute-entry-ip-uri').text().trim()  # get url or ip
      tmi_ajax_webrep(top_url)  # example is 'aol.com'

    # on webrep, if user clicks the 'select an entry' element
    $('.tab-ctt-webrep .ctt-entry-select').change ->
      curr_url = $(this).find('option:selected').attr('data-entry')

      tmi_ajax_webrep(curr_url)  # do tmi stuff
      setup_context_tables_webrep('update')  # do enrich and prev stuff

    # show the choose-an-entry if multiple entries exist on webrep dispute case
    num_of_disputes = parseInt($('.top-case-info .dispute-entry-count').text().trim())

    if num_of_disputes > 1
      $('.ctt-choose-an-entry').removeClass('hidden')

      # build select for choose-an-entry
      $('.research-table-row').each ->
        curr_entry = $(this).find('.entry-data-content').text().trim()  # entry can be url/ip/domain
        curr_option = "<option class='mult-entry-option' data-entry='#{curr_entry}'>#{curr_entry}</option>"
        $(".ctt-entry-select").append(curr_option)

    # enrichment functions are defined, build it out on initial page load
    setup_context_tables_webrep()


  # filerep - tmi kick things off on filerep, we need the sha
  else if $('.tab-ctt-filerep').length > 0
    curr_sha = $('#sha256_hash').text().trim()  # get url or ip
    tmi_ajax_webrep(curr_sha)










# add tags dialog stuff goes here
$ ->
  # this just inits the dialog html, the props are used when dialog() is called later
  $('#add-context-tags-dialog').dialog(
    autoOpen: false
    dialogClass: 'add-context-tags-dialog'
    width: 600
    height: 600
    minWidth: 600
    minHeight: 400
  )



# initialize and open the tags dialog!!
window.add_context_tags_dialog = () ->
  console.log 'addtags() is ran, lets build the taxonomy tag tree'

  # open the dialog
  $('#add-context-tags-dialog').dialog('open')

  # ajax call to get list of taxonomies
  std_msg_ajax
    url: '/escalations/api/v1/escalations/cloud_intel/tag_management/taxonomy_map'
    method: 'GET'
    success: (response) ->
      console.log 'TAG TREE DATA BELOW'
      console.log response

      # taxonomies is an array of top-level nodes
      { taxonomies } = response

      # for each taxonomy, add to ul
      $(taxonomies).each (i, val) ->
        { name, entries, taxonomy_id } = this
        taxonomy_option = "<option class='taxonomy-#{taxonomy_id}'>#{name}</option>"
        $('.taxonomy-select').append(taxonomy_option)

#        top_node =
#          "<div class='tree-node top-node top-node-#{taxonomy_id}'>
#             <input class='node-select' type='checkbox'>
#             <span class='tree-text'>#{name}</span>
#           </div>"

#        $('#context-tags-tree').append(top_node)
#
#        $(entries).each ->
#          { entry_id, name } = this
#          child_node =
#            "<div class='tag-#{taxonomy_id}-#{entry_id}'>
#               <input type='checkbox'>
#               <span'>#{name}</span>
#             </div>"
#
#          $('#context-tags-tree').append(child_node)






# FOR REFERENCE BELOW ONLY! DELETE ALL OF THIS WHEN TMI IS NEAR-FINAL
# FOR REFERENCE BELOW ONLY! DELETE ALL OF THIS WHEN TMI IS NEAR-FINAL
# FOR REFERENCE BELOW ONLY! DELETE ALL OF THIS WHEN TMI IS NEAR-FINAL
window.rulegroups_dialog = (button) ->
  $(button).addClass('active')

  $('#edit-rulegroups-dialog').dialog('open')

  # Only need to fetch if we haven't already done that
  unless $('#rulegroups-tree').length > 0
    fetch_rulegroups_tree()

#  turn_off_button = (button) ->
#    debugger
#    $(button).removeClass('active')

  fetch_rulegroups_tree = () ->
    $.atlas_ajax
      url: '/api/v2/research/rule_groups'
      method: 'GET'
      success: (response) ->
        root_id = response.root
        root_data = response.lookup[root_id]
        tree_nodes_raw = response.lookup

        # grab initial 'children' (top parents) to start creating useful tree structure
        grab_children(tree_nodes_raw, root_data)
        data_tree = root_data.children

        # this will pull in all decendents & their data into the parent.children array
        find_kids(data_tree, tree_nodes_raw)

        # loop through data to construct UI Tree
        tree = build_tree(data_tree)

        # turn off loader
        $('#rule-group-tree .inline-loader-wrapper').hide()
        $('#rule-group-tree').append(tree)


  # Make sure there are children to grab
  find_kids = (array, tree_nodes_raw) ->
    for node in array
      if node.type == 'branch'
        grab_children(tree_nodes_raw, node)
        find_kids(node.children, tree_nodes_raw)

  # Get the van ready
  grab_children = (tree, parent) ->
    children_arry = []
    for child in parent.children
# use this to grab children from the tree \o/
      child_data = tree[child]
      children_arry.push(child_data)

    # replace array of children keys with array of children data
    Object.assign(parent.children, children_arry)
    return parent

  ## Build the UI Tree!
  build_tree = (data_tree) ->
    tree = '<ul id="rulegroups-tree">'
    for node in data_tree
      branch = build_a_branch(node)
      if node.type == 'branch'
        nested_branches = build_nested_branches(node.children)
        branch += nested_branches
      branch += '</li>'
      tree += branch
    tree += '</ul>'
    return tree

  build_nested_branches = (children) ->
    nested_branches = '<ul class="nested-tree-list collapsed">'
    branches = []
    for child in children
      branch = build_a_branch(child)

      #need to check if this has children
      if child.type == 'branch'
        sub_branches = build_nested_branches(child.children)
        branch += sub_branches
      branch += '</li>'
      branches.push(branch)

    # put branches in alphabetical order
    sorted_branches = branches.sort()
    nested_branches += sorted_branches.join('')
    nested_branches += '</ul>'
    return nested_branches

  build_a_branch = (node) ->
    if node.type == 'branch'
      branch = '<li data-name="' + node.name + '" data-id="' + node.groupid + '">'
      branch += '<input hidden="hidden" type="checkbox" class="tree-toggle" id="tree-toggle-' + node.groupid + '" onclick="toggle_branch(this)"/>'
      branch += '<label class="tree-toggle-label" for="tree-toggle-' + node.groupid + '" />'
    else
      branch = '<li data-name="' + node.name + '" class="leaf-node-spacer" data-id="' + node.groupid + '">'

    branch +=
      '<input type="checkbox" class="node-select" id="node-select-' + node.groupid + '" data-fqn="' + node.fqn + '" onclick="select_nodes(this)"/>' +
        '<span class="tree-text tooltipped" title="' + node.description + '">' + node.name + '</span>'
    # close branch elsewhere in case there are nested branches
    return branch


# Hide / show branches
window.toggle_branch = (button) ->
  ul = $(button).siblings('.nested-tree-list')
  if $(button).hasClass('tree-toggle-open')
    $(button).removeClass('tree-toggle-open')
    $(ul).addClass('collapsed')
  else
    $(button).addClass('tree-toggle-open')
    $(ul).removeClass('collapsed')

# Selecting checkboxes (should toggle all sub branches)
window.select_nodes = (checkbox) ->
  ul = $(checkbox).siblings('.nested-tree-list')
  checkboxes = $(ul).find('.node-select')
  if $(checkbox).prop('checked') == true
    $(checkboxes).prop('checked', true)
    $($(checkbox).parent('li')).addClass('selected')
    $($(checkboxes).parent('li')).addClass('selected')
  else
    $(checkboxes).prop('checked', false)
    $($(checkbox).parent('li')).removeClass('selected')
    $($(checkboxes).parent('li')).removeClass('selected')
