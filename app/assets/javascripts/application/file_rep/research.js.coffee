$ ->

########### GRAB SHA NEEDED FOR REPORTS ############
#  If html body is on the show page (do not call on other pages)
  if $('body').hasClass('escalations--file_rep--disputes-controller') && $('body').hasClass('show-action')
    # On the show page we can pull the sha from the FILE OVERVIEW section
    # This prepares all the remaining functions for data fetches / updates
    sha256_hash = $('#sha256_hash')[0].innerText
    window.research_data(sha256_hash)

# load the local RL api data the first time page loads:
$(document).on 'ready',->
  window.get_local_reversinglabs_api()


# Update the research reports and the items in the db
window.refresh_research_data = (sha256_hash) ->
  sha256_hash = $('#sha256_hash')[0].innerText
  window.research_data(sha256_hash)
  window.get_local_reversinglabs_api()
  window.update_file_rep_data()



# Resubmit file sha hash to all the analysis engines
# services: threatgrid, reversinglab
# space delimited
window.evaluate_file =  (services) ->
  sha256_hash = $('#sha256_hash')[0].innerText
  unless services == 'threatgrid'
    services = []
  this_api = 'true'
  magic = 'true'

  # Submitted via individual button
  if services == 'threatgrid'
    wrapper = $('#threatgrid-report-wrapper')
    tg_report_present = wrapper.find('.tg-data-present')[0]
    tg_report_missing = wrapper.find('.tg-data-missing')[0]
    tg_report_running = wrapper.find('.tg-report-run')[0]
    $(tg_report_present).hide()
    $(tg_report_missing).hide()
    # Clear residual data
    $(tg_report_present).find('.data-report-content').each ->
      $(this).empty()
    $(tg_report_running).show()
    $('#tg-loader').show()

  # Multiple submission checkboxes / buttons
  else

    $('#resubmit-to-resources input:checked').each ->
      service = $(this).attr('data-service')
      wrapper = $('#' + service + '-report-wrapper')
      console.log wrapper
      switch service
        when 'threatgrid'
          tg_report_present = wrapper.find('.tg-data-present')[0]
          tg_report_missing = wrapper.find('.tg-data-missing')[0]
          tg_report_running = wrapper.find('.tg-report-run')[0]
          $(tg_report_present).hide()
          $(tg_report_missing).hide()
          # Clear residual data
          $(tg_report_present).find('.data-report-content').each ->
            $(this).empty()
          $(tg_report_running).show()
          $('#tg-loader').show()
          services += service + ' '
        when 'reversinglab'
          # When this is enabled some of the html structure needs to be changed
          # The submit to RL and the loading information will need to be added
          rl_report_present = wrapper.find('.rl-data-present')[0]
          rl_report_missing = wrapper.find('.rl-data-missing')[0]
          rl_report_running = wrapper.find('.rl-report-run')[0]
          $(rl_report_present).hide()
          $(rl_report_missing).hide()
          # Clear residual data
          $(rl_report_present).find('.data-report-content').each ->
            $(this).empty()
          $(rl_report_running).show()
          $('#rl-loader').show()
          services += service + ' '

  if this_api == 'true'
    std_msg_ajax(
      method: 'POST'
      url: "/escalations/api/v1/escalations/file_rep/disputes/submit_for_evaluation/"
      data: {sha256_hash: sha256_hash, service: services, refresh_magic: magic}
      success_reload: false
      success: (response) ->
        if services.includes('threatgrid')
          setTimeout get_threatgrid_data, 600000
#        Add later when RL api is enabled
#        else if services.includes('reversinglab')
#          setTimeout(get_reversinglabs_data(sha256_hash), 600000)
      error: (response) ->
        std_api_error( response, "Submission Error", reload: false)
    )





########### COMPILE RESEARCH REPORTS ############
# Grabs the initial data for all three reports / datasets
# Loads on page load
# Report functions defined immediately below
window.research_data = (sha256_hash) ->
  window.get_threatgrid_data(sha256_hash)
  window.get_reversinglabs_data(sha256_hash)
  window.get_zoo_status(sha256_hash)
  window.get_enrichment_service_filerep(sha256_hash)


########### SAMPLE ZOO STATUS ############
window.get_zoo_status = (sha256_hash) ->
  # check SHA256 against Sample Zoo
  $('#zoo-loader').show()
  std_msg_ajax(
    method: 'GET'
    url: "/escalations/api/v1/escalations/file_rep/sample_zoo/" + sha256_hash
    success_reload: false
    success: (response) ->

      $('#zoo-loader').hide()
      zoo_present = $('.zoo-data-present').find('span')
      zoo_missing = $('.zoo-data-notfound').find('span')

      unless response.json.error?
        if response.json.in_zoo == true
          zoo_present.addClass('glyphicon glyphicon-ok')
        else
          zoo_missing.addClass('glyphicon glyphicon-remove')
      else
        $(zoo_present).show()
        $(zoo_missing).hide()

    error: (response) ->
      std_api_error(response, "There was a problem retrieving data from the Sample Zoo", reload: false)
  )





########### THREATGRID REPORT ############
get_threat_data = window.get_threatgrid_data = () ->
  # Send sha to ThreatGrid, get data
  loader = $('#tg-loader')
  sha256_hash = $('#sha256_hash')[0].innerText
  tg_report_running = $('#threatgrid-report-wrapper').find('.tg-report-run')[0]
  loader.show()
  std_msg_ajax(
    method: 'POST'
    url: "/escalations/api/v1/escalations/filerep/research/"
    data: {sha256_hash: sha256_hash}
    success_reload: false
    success: (response) ->
      wrapper = $('#threatgrid-report-wrapper')
      report_present = wrapper.find('.tg-data-present')[0]
      report_missing = wrapper.find('.tg-data-missing')[0]

      if response.json.data.current_item_count > 0
        file_data = response.json.data.items[0].item
        { state, submitted_at, tags, analysis } = file_data

        # if TG has a fail state, don't show most of the stuff
        switch state
          when 'fail'
            $('#tg-run-status').html('<span class="tg-fail-status">Failure</span>')
            $('#tg-score').siblings().hide()
            $('#tg-tags').closest('div.row').nextAll().hide()
            $(tg_report_running).hide()
            $(report_present).show()
            $(report_missing).hide()

          when 'succ'
            loader.hide()
            $(tg_report_running).hide()
            $(report_present).show()
            $(report_missing).hide()

            # dbinebri: use moment.js to make date readable, convert string to Date object first for best practice
            tg_formatted_submitted_date = moment(new Date( submitted_at )).format('MMM D, YYYY h:mm A')

            # Load the top data
            $('#tg-submission-date').text(tg_formatted_submitted_date)
            $('#tg-tags').text( tags.join(', '))
            $('#tg-run-status').text (state)

            # Ensure the analysis property exists first, it will not if there is a TG fail state
            unless !file_data.hasOwnProperty('analysis')
              # Adding threat score
              $('#tg-score').text( analysis.threat_score)
              # Adding behaviors
              behaviors = ""
              $( analysis.behaviors ).each ->
                behaviors += '<tr>'
                behaviors += '<td>' + this.name + '</td><td>' + this.threat + '</td><td>' + this.title + '</td>'
                behaviors += '</tr>'
              $('#tg-behaviors').append('<tbody>' + behaviors + '</tbody>')

              # Adding full json report in case it's needed
              full_report = JSON.stringify(response.json, null, 2)
              $('#tg-full').text(full_report)

              # dbinebri: Convert the Threatgrid full_report to a downloadable file, add the Download button hyperlink
              tg_json_file = 'text/json; charset=utf-8,' + encodeURIComponent(full_report)
              tg_filename = 'threatgrid_' + moment(new Date()).format('MM_DD_YYYY') + '.json'
              tg_json_link = '<a href="data:' + tg_json_file + '" download="' + tg_filename + '"></a>'
              $('#download-tg-json').wrap tg_json_link

          when 'wait'
            $(report_missing).hide()
            $(report_present).hide()
            $(tg_report_running).show()
            loader.show()
            setTimeout get_threatgrid_data, 600000
      else
        $(report_present).hide()
        $(report_missing).show()
        loader.hide()
        $(tg_report_running).hide()

    error: (response) ->
      loader.hide()
      std_api_error(response, "There was a problem retrieving data from ThreatGrid", reload: false)
  )





########### REVERSING LABS REPORT ############
window.get_reversinglabs_data = (sha256_hash) ->
  #  Send sha to reversing labs, get data
  $('#rl-loader').show()
  std_msg_ajax(
    method: 'GET'
    url: "/escalations/api/v1/escalations/filerep/reversing_labs/" + sha256_hash
    success_reload: false
    success: (response) ->
      $('#rl-loader').hide()
      report_present = $('#reversing-labs-report-wrapper').find('.rl-data-present')[0]
      report_missing = $('#reversing-labs-report-wrapper').find('.rl-data-missing')[0]

      unless response.json.error?
        rl_data = response.json.rl.sample.xref
        scanner_count = ""
        result_count = ""

        $(report_present).show()
        $(report_missing).hide()

        all_scanner_results = rl_data.entries[0]
        scan_time = all_scanner_results.record_time
        scanner_count = all_scanner_results.scanners.length

        # dbinebri: use moment.js to make dates readable
        first_seen_date = moment(new Date(rl_data.first_seen)).format('MMM D, YYYY h:mm A')
        last_seen_date = moment(new Date(rl_data.last_seen)).format('MMM D, YYYY h:mm A')
        formatted_scan_time = moment(new Date(scan_time)).format('MMM D, YYYY h:mm A')

        $('#rl-first-seen-date').text(first_seen_date)
        $('#rl-most-recent-date').text(last_seen_date)


        # Cycle through the scanner results
        mal_results = []
        unk_results = []
        $(all_scanner_results.scanners).each ->
          if this.result == ""
            unk_results.push(this)
          else
            mal_results.push(this)

        result_count = mal_results.length
        $('#rl-scanner-results').text(result_count + '/' + scanner_count)

        # Add the malicious scans to top of table, create rows from each scanner result
        tbody = ""
        $(mal_results).each ->
          tbody += '<tr><td>' + this.name + '</td><td>' + formatted_scan_time + '</td><td class="scanner-mal">' + this.result + '</td></tr>'
        $(unk_results).each ->
          tbody += '<tr><td>' + this.name + '</td><td>' + formatted_scan_time + '</td><td class="scanner-unk">Not Detected</td></tr>'

        $('#rl-scanner-table').append(tbody)
      else
        $(report_present).hide()
        $(report_missing).show()

    error: (response) ->
      $('#rl-loader').hide()
      std_api_error(response, "There was a problem retrieving data from Reversing Labs", reload: false)
  )

########### ENRICHMENT SERVICES SECTION ############
# This function is called on the page load with the rest of the Research tab
# Three sections: Email, Web and Enrichment. Enrichment usually has the most results.
# Sections are then sorted into taxonomies if there are multiple tags in each section.

#group taxonomies by ID - for Enrichment section
group_by_tag = (array, key) ->
  array.reduce (acc, obj) ->
    property = obj[key]
    acc[property] = acc[property] || []
    acc[property].push obj
    acc
  , {}

create_filerep_enrich_section = (tags, context) ->

  #organize tags by taxonomy_id if there are multiple
  if tags.length > 1
    taxonomy_object = group_by_tag(tags, 'taxonomy_id')
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
        table_header = "<tr class='filerep-enrich-table-header-row'><th class='filerep-enrich-table-name-th'>Name</th><th class='filerep-enrich-table-description-th'>Description</th><th class='text-right'>External Ref</th></tr>"
        $(table_wrapper).append table_header

      name_wrapper = $("<td class='filerep-enrich-cell-name'></td>")
      $(name_wrapper).text(name) #escaping to prevent xss attacks
      description_wrapper = $("<td class='filerep-enrich-cell-description'></td>")
      $(description_wrapper).text(description) #escaping to prevent xss attacks
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

          $(individual_wrapper).append link_wrapper
          $(external_ref_wrapper).append individual_wrapper

      $(table_wrapper).append row_wrapper

    $(section_wrapper).append table_wrapper
    $('.enrich-filerep-data-present').append section_wrapper

create_filerep_prevalence_section = (prevalence_data) ->
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
    $('.prevalence-filerep-data-present').append(total_section_wrapper)

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

        dataset_td = $("<td></td>")
        $(dataset_td).text(key)
        $(dataset_row).append(dataset_td)

        dataset_disposition_td = $("<td></td>")
        $(dataset_disposition_td).text(d_key)
        $(dataset_row).append(dataset_disposition_td)

        dataset_count_td = $("<td></td>")
        $(dataset_count_td).text(dispositions[d_key].count)
        $(dataset_row).append(dataset_count_td)

        dataset_first_seen_td = $("<td></td>")
        $(dataset_first_seen_td).text(dispositions[d_key].first_seen)
        $(dataset_row).append(dataset_first_seen_td)

        dataset_last_seen_td = $("<td></td>")
        $(dataset_last_seen_td).text(dispositions[d_key].last_seen)
        $(dataset_row).append(dataset_last_seen_td)

        $(dataset_table_body).append(dataset_row)

    $(dataset_table_wrapper).append(dataset_table_body)
    $(dataset_section_wrapper).append(dataset_table_wrapper)
    $('.prevalence-filerep-data-present').append(dataset_section_wrapper)



########### ENRICHMENT API REPORT ############
window.get_enrichment_service_filerep = (sha256_hash) ->
  std_msg_ajax(
    method: 'GET'
    data: {'query_item': sha256_hash, 'query_type':'sha'}
    url: '/escalations/api/v1/escalations/cloud_intel/enrichment_service/query/'
    success_reload: false
    success: (response) ->

      $('#enrich-loader').hide()
      $('#prevalence-loader').hide()
      email_context_tags = []
      web_context_tags = []
      enrichment_context_tags = []

      if response?.data?.email_context_tags.length > 0
        email_context_tags = response.data.email_context_tags

      if response?.data?.web_context_tags.length > 0
        web_context_tags = response.data.web_context_tags

      if response?.data?.context_tags.length > 0
        enrichment_context_tags = response.data.context_tags

      #check if any data returned and show section
      if email_context_tags.length > 0 || web_context_tags.length > 0 || enrichment_context_tags.length > 0
        $('.enrich-filerep-data-present').show()

        ## Enrichment Section - Email Section
        if email_context_tags.length > 0
          create_filerep_enrich_section(email_context_tags, 'Email')

        ## Enrichment Section - Web Section
        if web_context_tags.length > 0
          create_filerep_enrich_section(web_context_tags, 'Web')

        ## Enrichment Section - Enrichment (Other) Section
        if enrichment_context_tags.length > 0
          create_filerep_enrich_section(enrichment_context_tags, 'Enrichment')

      #show empty message if no tags returned
      else
        $('.enrich-filerep-data-missing').show()

      if response?.data?.prevalence?
        create_filerep_prevalence_section(response.data.prevalence.responses)
      else
        $('.prevalence-filerep-data-missing').show()

    error: (response) ->
      std_msg_error('Error with Enrichment Service', ['There was an error.'])
  )

##### UPDATE FILE REP DATA #####
# Refresh items from the reports that we store in the db & save them
window.update_file_rep_data = () ->
  file_rep_id = $(".case-id-tag")[0].innerText
  # Hide current data
  sb_data_true = $($('.sb-data-present')[0]).hide()
  sb_data_false = $($('.sb-data-missing')[0]).hide()
  tg_data_true = $($('.tg-data-present')[0]).hide()
  tg_data_false = $($('.tg-data-missing')[0]).hide()
  rl_data_true = $($('.rl-data-present')[0]).hide()
  rl_data_false = $($('.rl-data-missing')[0]).hide()

  # Round and round it goes
  sync_button = $('#file-rep-sync-button')
  $(sync_button).addClass('syncing')

  # Updating the info for the db
  std_msg_ajax(
    method: 'POST'
    url: "/escalations/api/v1/escalations/filerep/research/update_file_rep_data"
    data: {id: file_rep_id}
    success_reload: false
    success: (response) ->
      $('#tg-loader').hide()
      $('#sb-loader').hide()
      $('#rl-loader').hide()
      $(sync_button).removeClass('syncing')
    error: (response) ->
      $('#tg-loader').hide()
      $('#sb-loader').hide()
      $('#rl-loader').hide()
      $(sync_button).removeClass('syncing')
      std_api_error(response, "There was a problem refreshing some research data", reload: false)
  )

########### REVERSING LABS LOCAL API ############
window.get_local_reversinglabs_api = () ->
  file_rep_id = $(".case-id-tag")[0].innerText

  threat_name = $("#local-rl-threat-name")
  threat_status = $("#local-rl-threat-status")
  threat_scan = $("#local-rl-threat-scan")
  threat_signer = $("#local-rl-signer")

  std_msg_ajax(
    method: 'GET'
    url: "/escalations/api/v1/escalations/filerep/research/local_reversinglabs_api"
    data: {id: file_rep_id}
    success_reload: false
    success: (response) ->
      name = response['threat_name']
      status = response['threat_status']
      scan = response['last_scan_date']
      signer = response['digital_signer']

      if not name?
        name = "N/A"
      if not status?
        status = "N/A"
      if not scan?
        scan = "N/A"
      if not signer?
        signer = "N/A"

      # format date:
      scan_date = moment(new Date(scan)).format('MMM D, YYYY h:mm A')

      # add data from response to page:
      threat_name.text(name)
      threat_status.text(status)
      threat_scan.text(scan_date)
      threat_signer.text(signer)

    error: (response) ->
      std_api_error(response, "There was a problem retrieving data from the local Reversing Labs api", reload: false)
  )  


$ ->
  # dbinebri: on page load - setting the collapsed + height state for both json reports
  $('#collapse_sb_json, #collapse_tg_json').toggleClass("in").css("height", "300px").attr("aria-expanded", "false")


  # dbinebri: refactoring this. this is checkbox toggle column visible + widths on Show Page, Research tab
  $('#data-show-tg-cb').click -> $('#threatgrid-report-wrapper').toggle()
  $('#data-show-reversing-cb').click -> $('#reversing-labs-report-wrapper').toggle()

  wrapper_list = $('#threatgrid-report-wrapper, #reversing-labs-report-wrapper')

  $('#data-show-tg-cb, #data-show-reversing-cb').click ->
    if $('.dataset-cb:checked').length == 1
      $(wrapper_list).removeClass('col-sm-6').addClass('col-sm-12')
    else if $('.dataset-cb:checked').length == 2
      $(wrapper_list).removeClass('col-sm-12').addClass('col-sm-6')
