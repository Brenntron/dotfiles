cluster_detail_head = """
    <table class='table cluster-path-table'>
      <thead>
        <tr>
          <th class='clusterpath-col-path'>Cluster Paths</th>
          <th class='clusterpath-col-path'>Customer Name</th>
          <th class='clusterpath-col-volume text-center'>APAC Region Volume</th>
          <th class='clusterpath-col-volume text-center'>EMRG Region Volume</th>
          <th class='clusterpath-col-volume text-center'>EURP Region Volume</th>
          <th class='clusterpath-col-volume text-center'>GLOB Volume</th>
          <th class='clusterpath-col-volume text-center'>JAPN Volume</th>
          <th class='clusterpath-col-volum text-centere'>NA Region Volume</th>
          <th class='clusterpath-col-wbrs text-center'>WBRS Score</th>
        </tr>
        </thead>
      <tbody>
  """

window.cluster_detail_row = (wbrs_rep, wbrs_score, url, customer_name, apac_volume, emrg_volume, eurp_volume, glob_volume, japn_volume, noam_volume) ->
  wbrs_col = "<div class='reputation-icon-container'><span class='reputation-icon icon-#{wbrs_rep} esc-tooltipped' title='#{wbrs_rep.toUpperCase()}'></span> #{wbrs_score}</div>"

  "<tr class='index-entry-row'>
    <td class='clusterpath-col-path'>#{url}</td>
    <td class='clusterpath-col-path'>#{customer_name}</td>
    <td class='clusterpath-col-volume text-center'>#{apac_volume}</td>
    <td class='clusterpath-col-volume text-center'>#{emrg_volume}</td>
    <td class='clusterpath-col-volume text-center'>#{eurp_volume}</td>
    <td class='clusterpath-col-volume text-center'>#{glob_volume}</td>
    <td class='clusterpath-col-volume text-center'>#{japn_volume}</td>
    <td class='clusterpath-col-volume text-center'>#{noam_volume}</td>
    <td class='clusterpath-col-wbrs text-center'>#{wbrs_col}</td>
  </tr>"

window.apply_filter_to_table = () ->
  filter = $("#cluster_filter_field").val()

  # if they have entered a regex, show the regex in upper-left area
  if filter != ''
    $('.regex-area').removeClass('hidden')
  else
    $('.regex-area').addClass('hidden')

  $('#regex-filter').html(filter)

  populate_clusters_index_table(filter)
    
window.populate_clusters_index_table = (filter) ->
  if $('#clusters-index_wrapper').length > 0
    loader = $('.cluster-mgt-loader-wrapper')
    loader.removeClass('hidden')

    filter_param = window.location.search
    save_regex = $('#saveRegex')[0].checked

    if filter_param.length == 0
      filter_param += "?f=all"
    if filter && filter_param
      filter_param += "&regex=" + filter
    if save_regex && filter_param
      filter_param += "&save_regex=" + save_regex
    table =  $("#clusters-index").DataTable()
    if save_regex
      $.ajax(
        url: "/escalations/api/v1/escalations/webcat/clusters/searches"
        headers: window.headers()
        data: { save_regex: save_regex, regex: filter}
        method: 'POST'
        success: (response) ->
          search = $.parseJSON(response).data
          $('#saved-search-tbody').append("<tr id='saved_search_#{search.id}'><td><a class='input-truncate saved-search esc-tooltipped tooltipstered' name='#{search.name}' onclick='build_webcat_clusters_named_search(this);'>#{filter}</a><a class='delete-search' name='#{search.name}' onclick='delete_clusters_named_search(this);' title='Delete Saved Search'><img src='/assets/icon_cancel_grey.svg'></a></td></tr>")

      )
    if window.location.search.includes('WSA')
      $.ajax(
        url: "/escalations/api/v1/escalations/webcat/clusters" + filter_param
        method: 'GET'
        headers: window.headers()
        success: (response) ->
          loader.addClass('hidden')
          if response.data.length == 0
            std_msg_error("No clusters available.","")
          if response.error
            std_msg_error('Table Error', [response.error])
          else
            datatable = $('#clusters-index').DataTable()
            datatable.clear();
            datatable.rows.add(response.data);
            datatable.draw();

        error: (response) ->
          loader.addClass('hidden')
          std_msg_error('Table Error', [response.responseText])
      , this)
    else
      table.ajax.url("/escalations/api/v1/escalations/webcat/clusters.json" + filter_param).load()    


window.build_webcat_clusters_named_search = (namedSearch) ->
  $("#cluster_filter_field").val($(namedSearch).attr('name'))
  apply_filter_to_table()


# Delete saved regex searches
window.delete_clusters_named_search = (close_button) ->
  data = { search_name: $(close_button).attr('name') }
  std_msg_ajax(
    method: 'DELETE'
    url: "/escalations/api/v1/escalations/webcat/clusters/searches"
    data: data
    error_prefix: 'Error deleting saved search.'
    failure_reload: false
    tr_tag: close_button.closest('tr')
    success: (response) ->
      this.tr_tag.remove();
  )


# categorize clusters submission - review_action (optional) is "bulk_accept", "bulk_deny", or empty (default)
window.categorize_clusters = (review_action) ->
  loader = $('.cluster-mgt-loader-wrapper')
  loader.removeClass('hidden')
  user_id = $("#user_id").val()
  comment = $("#cluster_comment_field").val()
  saveRegex = $('#saveRegex')[0].checked

  #cluster_id comment category_ids
  clusters = $ '[id$=\'_categories\']'
  categories = []
  if $('#clusters-index').find('input:checked').length == 0
    std_msg_error('no rows selected', ['Please select at least one row.'])
    loader.addClass('hidden')
    return

  data = {}
  data["comment"] = comment
  data["user_id"] = user_id
  selected_rows = $("#clusters-index").DataTable().rows('.selected').data()
  clusters = []

  for selected_row in selected_rows
    selected_row["comment"] = comment
    escaped_domain = selected_row.domain.replaceAll('.', '_')
    $("##{escaped_domain}_#{selected_row["platform"]}_categories").each ->
      # collect selected categories
      categories = $(this).find('option')

      if categories? and categories.length > 0
        category_values = []
        $(categories).each ->
          value = $(this).attr('value')
          category_values.push value
        selected_row['categories'] = category_values
        for duplicate in selected_row.duplicates
          duplicate['categories'] = category_values

    clusters.push(selected_row)

  data["clusters"] = JSON.stringify(clusters)

  endpoint = "process_cluster"  # endpoint for 1st person (default)

  selections_invalid = false  # ensure valid selections on bulk

  # endpoints for 2nd person bulk accept/deny
  if review_action == "bulk_accept"
    endpoint = "process_multiple_reviewed"
  else if review_action == "bulk_deny"
    endpoint = "decline_multiple_reviewed"

  url = "/escalations/api/v1/escalations/webcat/clusters/#{endpoint}"

  # approve all, deny all: ensure all selected rows are in 2nd review (blue row) before proceeding
  if review_action == "bulk_accept" || review_action == "bulk_deny"
    $('input.cluster-row-select:checked').each ->
      curr_selectize = $(this).closest('tr').find('.selectize-input')
      if !$(curr_selectize).hasClass('locked')   # locked rows are in review and have categories
        std_msg_error('Please make sure all clusters selected are in review', [''])
        loader.addClass('hidden')
        selections_invalid = true  # user selected some rows not in 2nd review (locked)

  unless selections_invalid
    std_msg_ajax
      url: url
      method: 'POST'
      headers: window.headers()
      data: data
      success: (response) ->
        loader.addClass('hidden')
        json = $.parseJSON(response)

        # clusters submitted but need 3rd person review, this step is a success & error/notice at the same time
        if json.error && json.error.includes("Manager needs to approve")
          std_msg_success('Clusters submitted, manager approval still needed', [json.error])
        # success on ajax call but other error info exists in response
        else if json.error && !json.error.includes("Manager needs to approve")
          std_msg_error("Clusters processing error", [json.error])
        else
          # if no 'json.error' then this is a normal success, reload page for page cleanup
          switch review_action
            when "bulk_accept"
              std_msg_success("Approved all cluster categories", '')
            when "bulk_deny"
              std_msg_success("Denied all cluster categories", '')

          # legacy logic here, indvidual submit success updates the datatable w/o page reload
          $("#cluster_comment_field").val('')
          filter = $("#cluster_filter_field").val()
          if filter
            populate_clusters_index_table(filter)
          else
            populate_clusters_index_table()

      error: (response) ->
        loader.addClass('hidden')
        if review_action == "bulk_accept"
          std_msg_error('Error on approve all categories', '')
        else if review_action == "bulk_deny"
          std_msg_error('Error on deny all categories', '')
        else
          std_msg_error('Error on clusters processing', '')


$ ->
  $('.show-platforms-filter').click (event) ->
    if event.target.value == 'WSA' && event.target.checked
      $("[name='NGFW_platform'], [name='Umbrella_platform'], [name='Meraki_platform']").prop('checked', false)
    if event.target.value != 'WSA' && event.target.checked
      $("[name='WSA_platform']").prop('checked', false)
    platforms = $("input.show-platforms-filter:checked")

    selected_platform = []
    platforms.each -> selected_platform.push($(this).val());
  
    url = new URL(document.location.href)
    url.searchParams.set('platform', selected_platform)
    document.location = url;
  
  window.build_clusters_filters = ()=>
    filter_param = window.location.search
    if $('#clusters-index_wrapper').length > 0
      loader = $('.cluster-mgt-loader-wrapper')
      loader.removeClass('hidden')

      filter_param = window.location.search
      save_regex = $('#saveRegex')[0].checked

      if filter_param.length == 0
        filter_param += "?f=all"
      if save_regex && filter_param
        filter_param += "&save_regex=" + save_regex
    
    filter_param
  $(document).ready ->
    # uncheck the select all checkbox on page change.
    $('#clusters-index').DataTable().on('page.dt', () ->
      if $('#clusters_check_box').prop('checked')
        $('#clusters_check_box').prop('checked', false)
        $('#clusters-index').DataTable().rows().deselect()

        rows = $('table#clusters-index input[type="checkbox"]')
        for row in rows
          $(row)[0].checked = false
    )

# expand all functionality
window.expand_all_clusters = (tableId) ->
  selectedRows = $('table#' + tableId + ' tr[role="row"]')
  clusterIds = window.clusters_table.rows({page:'current'} ).data().pluck('cluster_id').toArray()
  window.get_data_for_clusters(selectedRows, clusterIds)

# collapse all functionality
window.collapse_all_clusters = (tableId) ->
  selectedRows = $('table#' + tableId + ' tr[role="row"]')
  for row in selectedRows
    if $(row).hasClass('shown')
      $(row).find('.expand-row-button-inline').click()

#  expand selected funtionality
window.expand_selected_clusters = (tableId) ->
  selectedRows = $('table#' + tableId + ' tr[role="row"].selected')
  clusterIds = selectedRows.map (i, row) ->
    parseInt($(row).find('.cluster_identifier').text())
  window.get_data_for_clusters(selectedRows, clusterIds.toArray())

# get data and expandand clusters details
window.get_data_for_clusters  = (selectedRows, clusterIds) ->
  $.ajax
    method: 'POST'
    url: "/escalations/api/v1/escalations/webcat/clusters/multiple"
    headers: window.headers()
    data: { ids: clusterIds }
    success: (response) ->
      clustersData =  $.parseJSON(response).data
      for row in selectedRows
        cluster_id = $(row).find('td.cluster_identifier').text()
        if !$(row).hasClass('shown') && clustersData[parseInt(cluster_id)]
          window.expandSingleRow(row, clustersData[parseInt(cluster_id)])
      $('.cluster-mgt-loader-wrapper').addClass('hidden')

    error: (response) ->
      $('.cluster-mgt-loader-wrapper').addClass('hidden')
      std_api_error(response, "There was an error loading cluster data.", reload: false)

#  collapse selected funtionality
window.collapse_selected_clusters = (tableId) ->
  selectedRows = $('table#' + tableId + ' tr[role="row"].selected')
  for row in selectedRows
    if $(row).hasClass('shown')
      $(row).find('.expand-row-button-inline').click()

# open selected funtionality
window.open_selected_clusters = () ->
  selected_rows = $('#clusters-index').DataTable().rows('.selected')
  if selected_rows[0].length == 0
    std_msg_error('no rows selected', ['Please select at least one row.'])
  else
    open_selected_tabs(selected_rows, true)


# open all functionality
window.open_all_clusters = () ->
  selected_rows = $('#clusters-index').DataTable().rows()
  open_selected_tabs(selected_rows, true)

# This is here because of weird namespace problems over at `complaints.js.coffee`
open_selected_tabs = (selected_rows, toggle) ->
  for row, i in selected_rows[0]
    subdomain = ""
    domain = ""
    path = ""
    if selected_rows.data()[i].subdomain
      subdomain = selected_rows.data()[i].subdomain + "."
    if selected_rows.data()[i].domain
      domain = selected_rows.data()[i].domain
    if selected_rows.data()[i].path
      path = selected_rows.data()[i].path
    if selected_rows.data()[i].domain
      window.open("http://"+ subdomain + domain + path)
    else
      window.open("http://"+selected_rows.data()[i].ip_address)

window.copycat_dialog = () ->
  $('#copycat_dialog').dialog({
    dialogClass: "copycat_tool_dialog",
    position: { my: "left+475 top+160", at: "left top", of: window },
    close: (event, ui) =>
      $('button.icon-copycat').removeClass('active')
    open: (event, ui) =>
      $('#copycat_dialog #copycat-categories').selectize {
        persist: true,
        create: false,
        maxItems: 5,
        closeAfterSelect: true,
        valueField: 'category_id',
        labelField: 'category_name',
        searchField: ['category_name', 'category_code'],
        options: AC.WebCat.createSelectOptions('#copycat_dialog #copycat-categories')
        score: (input) ->
          #  Adding some customization for autofill
          #  restricting on certain cats to avoid accidental categorization
          #  (replaces selectize's built-in `getScoreFunction()` with our own)
          (item) ->
            if item.category_code == 'cprn' || item.category_code == 'xpol' || item.category_code == 'xita' || item.category_code == 'xgbr' || item.category_code == 'xdeu' || item.category_code == 'piah'
              item.category_code == input ? 1 : 0
            else if item.category_name.toLowerCase().startsWith(input.toLowerCase())
              1
            else if item.category_name.toLowerCase().includes(input.toLowerCase()) || item.category_code.toLowerCase().includes(input.toLowerCase())
              0.9
            else
              0
      }
  });

window.open_wsa_status = () ->
  $('#wsa_status_dialog').removeClass('hidden')
  $('#wsa_status_dialog').dialog({
    dialogClass: "wsa_tool_dialog",
    position: { my: "left+275 top+160", at: "left top", of: window },
    close: (event, ui) =>
      $('button.icon-wsa').removeClass('active')
      $('#wsa-status-table').empty()
  });


# delete copycat input content
window.copycat_clear = () ->
  inputSelectCtrl = $('#copycat_dialog #copycat-categories')[0].selectize
  inputSelectCtrl.clear()

window.onlyUnique = (value, index, self) ->
  self.indexOf(value) == index

# paste checkbox category input into copycat input
window.copycat_paste = () ->
  inputSelectCtrl = $('#copycat_dialog #copycat-categories')[0].selectize
  selectedValues = inputSelectCtrl.items
  if (selectedValues.length == 0)
    std_msg_error('CopyCat Error', ['No categories selected.'])
  else
    selectedRows = $('#clusters-index tr[role="row"].selected')

  if (selectedRows.length == 0)
    std_msg_error('CopyCat Error', ['Select at least one row to paste categories to.'])
  else
    selectedRows = $('#clusters-index tr[role="row"].selected')
    for row in selectedRows
      rowSelectize = $(row).find('.category-column .selectize')[0].selectize
      rowSelectize.setValue(selectedValues, true)

window.selectRow = (el) ->
  $(el).closest('tr').toggleClass('selected')

window.selectize_category_inputs = () ->
  category_inputs = $("select.cluster_categories")
  input_ids = []
  $(category_inputs).each ->
      input_ids.push("##{this.id}")
      $(this).selectize {
        persist: true,
        create: false,
        maxItems: 5,
        closeAfterSelect: true,
        valueField: 'category_id',
        labelField: 'category_name',
        searchField: ['category_name', 'category_code'],
        score: (input) ->
          #  Adding some customization for autofill
          #  restricting on certain cats to avoid accidental categorization
          #  (replaces selectize's built-in `getScoreFunction()` with our own)
          (item) ->
            if item.category_code == 'cprn' || item.category_code == 'xpol' || item.category_code == 'xita' || item.category_code == 'xgbr' || item.category_code == 'xdeu' || item.category_code == 'piah'
              item.category_code == input ? 1 : 0
            else if item.category_name.toLowerCase().startsWith(input.toLowerCase())
              1
            else if item.category_name.toLowerCase().includes(input.toLowerCase()) || item.category_code.toLowerCase().includes(input.toLowerCase())
              0.9
            else
              0
      }
  AC.WebCat.createSelectOptionsForIds(input_ids)

window.populate_cat_select = ->
  setTimeout (->
    data = $("#clusters-index").DataTable().data()
    for cluster in data
      if cluster.is_pending == true
        escaped_domain = cluster.domain.replaceAll('.', '_')
        cat_select = $("##{escaped_domain}_#{cluster.platform}_categories")[0]
        if cat_select
          $("##{escaped_domain}_#{cluster.platform}_categories")[0].selectize.setValue(cluster.categories)
  ), 2000

window.copy_domain = (domain, element) ->
  copyToClipboard(domain)
  html = "<div class='copied-container'>
            <div class ='copied-check'></div>
            <p id='copiedAlert'>Copied to clipboard</p>
          </div>"
  $(element).after( html )
  $('.copied-container').delay(1000).fadeOut(1000);
  setTimeout (->
    $(".copied-container").remove()
  ), 2000

window.toggle_all_checkboxes = () ->
  if $('#clusters_check_box').prop('checked')
    rows = $('.cluster-row-select');
    row_count = $('.cluster-row-select:visible').length

    for i in [1..row_count]
      $(rows[i - 1])[0].checked = true
      rowNumber = $(rows[i-1]).attr('id').replace('cluster_row_', '')
      $('#clusters-index').DataTable().rows(rowNumber).select()
  else
    $('#clusters-index').DataTable().rows().deselect()
    rows = $('table#clusters-index input[type="checkbox"]')
    for row in rows
      $(row)[0].checked = false
window.headers = () ->
  {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
# Select rows in Clusters Table
$ ->
  $('#clusters_check_box').click -> toggle_all_checkboxes()

  # Moves cluster selectize to table draw so that selectize boxes properly initialize when changing number of items being displayed
  $("#clusters-index").on 'draw.dt order.dt', ->
    selectize_category_inputs()
    populate_cat_select()
# 
  #  Expand cluster rows
  $('#clusters-index tbody').on 'click', '.expand-row-button-inline, .entry-count', ->
    expandSingleRow(this)

window.expandSingleRow = (currentRow, preloadedData=[])->
  tr = $(currentRow).closest('tr')
  row = window.clusters_table.row(tr)
  if row.child.isShown()
    # This row is already open - close it
    row.child.hide()
    tr.removeClass 'shown'
  else
    # Open this row
    $('.cluster-mgt-loader-wrapper').removeClass('hidden')
    cluster = row.data()

    missing_data = '<span class="missing-data">Missing data</span>'
    entry_rows = []
    if preloadedData.length != 0
      entry = preloadedData
      total_shown_entries = 0
      total_entries = $($(tr[0]).find('.entry-count')[0]).text()

      if total_entries < 300
        max_viewable_entries = total_entries
      else
        max_viewable_entries = 300

      if total_entries > 25
        link_to_more_results = '<a class="expand-cluster-entries">Click to preview the top  26 - ' + max_viewable_entries + ' cluster entries.</a>'
      else
        link_to_more_results = ''

      $(entry).each (i) ->
        if i <= 24
          {url, customer_name, apac_volume, emrg_volume, eurp_volume, glob_volume, japn_volume, noam_volume, wbrs_score}= this
          wbrs_rep = window.wbrs_display(wbrs_score)
          if wbrs_rep == undefined then wbrs_rep = 'unknown'
          if wbrs_rep == 'unknown'then wbrs_score = '--'

          entry_rows.push window.cluster_detail_row(wbrs_rep, wbrs_score, url, customer_name, apac_volume, emrg_volume, eurp_volume, glob_volume, japn_volume, noam_volume)
          total_shown_entries = i + 1
          return

      bottom_row = '<tr class="cluster-entry-bottom-row">' +
        '<td colspan="10">Previewing cluster entries 1 - <span class="total-shown-entries">' + total_shown_entries + '</span>. ' + link_to_more_results + '<span class="total-cluster-entry-count">Total Entries: ' + total_entries + '.</span></td>' +
        '</tr>'

      complete_table = cluster_detail_head + entry_rows.join('') + '</tbody><tfoot>' + bottom_row + '</tfoot></table>'

      row.child(complete_table).show()
      tr.addClass 'shown'
      td = $(tr).next('tr').find('td:first')
      $(td).addClass 'nested-complaint-data-wrapper'

      #         Expanding to maximum preview rows
      $('.expand-cluster-entries').click ->
        expand_table_row = this
        expandClusterEntryPreview(cluster, expand_table_row, max_viewable_entries)

      # subrow icons on clusters DT need the TT init on row expand, these icons don't exist on dt draw.dt, init them here
      $('#clusters-index .reputation-icon').tooltipster
        theme: [
          'tooltipster-borderless'
          'tooltipster-borderless-customized'
        ]

    else
      std_msg_ajax(
        method: 'GET'
        url: "/escalations/api/v1/escalations/webcat/clusters/" + cluster.cluster_id
        data: {}
        success: (response) ->
          $('.cluster-mgt-loader-wrapper').addClass('hidden')
          json = $.parseJSON(response)
          entry = json.data
          total_shown_entries = 0
          total_entries = $($(tr[0]).find('.entry-count')[0]).text()

          if total_entries < 300
            max_viewable_entries = total_entries
          else
            max_viewable_entries = 300

          if total_entries > 25
            link_to_more_results = '<a class="expand-cluster-entries">Click to preview the top  26 - ' + max_viewable_entries + ' cluster entries.</a>'
          else
            link_to_more_results = ''

          $(entry).each (i) ->
            if i <= 24
              {url, customer_name, apac_volume, emrg_volume, eurp_volume, glob_volume, japn_volume, noam_volume, wbrs_score}= this
              wbrs_rep = window.wbrs_display(wbrs_score)
              if wbrs_rep == undefined then wbrs_rep = 'unknown'
              if wbrs_rep == 'unknown'then wbrs_score = '--'

              entry_rows.push window.cluster_detail_row(wbrs_rep, wbrs_score, url, customer_name, apac_volume, emrg_volume, eurp_volume, glob_volume, japn_volume, noam_volume)
              total_shown_entries = i + 1
              return

          bottom_row = '<tr class="cluster-entry-bottom-row">' +
            '<td colspan="10">Previewing cluster entries 1 - <span class="total-shown-entries">' + total_shown_entries + '</span>. ' + link_to_more_results + '<span class="total-cluster-entry-count">Total Entries: ' + total_entries + '.</span></td>' +
            '</tr>'

          complete_table = cluster_detail_head + entry_rows.join('') + '</tbody><tfoot>' + bottom_row + '</tfoot></table>'

          row.child(complete_table).show()
          tr.addClass 'shown'
          td = $(tr).next('tr').find('td:first')
          $(td).addClass 'nested-complaint-data-wrapper'

          #         Expanding to maximum preview rows
          $('.expand-cluster-entries').click ->
            expand_table_row = this
            expandClusterEntryPreview(cluster, expand_table_row, max_viewable_entries)

          # subrow icons on clusters DT need the TT init on row expand, these icons don't exist on dt draw.dt, init them here
          $('#clusters-index .reputation-icon').tooltipster
            theme: [
              'tooltipster-borderless'
              'tooltipster-borderless-customized'
            ]

          error: (response) ->
            $('.cluster-mgt-loader-wrapper').addClass('hidden')
            std_api_error(response, "There was an error loading cluster data.", reload: false)
        )
  return

window.expandClusterEntryPreview = (cluster, expand_table_row, max_viewable_entries) ->
  $('.cluster-mgt-loader-wrapper').removeClass('hidden')
  entry_rows = []
  table_footer_cell = $(expand_table_row).parent()[0]
  table_footer = $($(table_footer_cell).parent()[0]).parent()[0]
  table_body = $(table_footer).prev('tbody')[0]
  footer_link_text = $(expand_table_row).text()
  total_shown_entries = $(table_footer_cell).children('.total-shown-entries')
  current_row_count = $(table_body).find('tr').length

  if current_row_count <= 25
    std_msg_ajax(
      method: 'GET'
      url: "/escalations/api/v1/escalations/webcat/clusters/" + cluster.cluster_id
      data: {}
      success: (response) ->
        $('.cluster-mgt-loader-wrapper').addClass('hidden')
        json = $.parseJSON(response)
        entry = json.data
        $(entry).each (i) ->
          if i > 25
            {url, customer_name, apac_volume, emrg_volume, eurp_volume, glob_volume, japn_volume, noam_volume, wbrs_score}= this
            wbrs_rep = window.wbrs_display(wbrs_score)
            if wbrs_rep == undefined
              wbrs_rep = 'unknown'

            if wbrs_rep == 'unknown'
              wbrs_score = '--'
            else
              wbrs_score = parseFloat(wbrs_score).toFixed(1)

              entry_rows.push window.cluster_detail_row(wbrs_rep, wbrs_score, url, customer_name, apac_volume, emrg_volume, eurp_volume, glob_volume, japn_volume, noam_volume)
            return

        $(table_body).append(entry_rows)

        replacement_text = footer_link_text.replace("preview", "collapse")
        $(expand_table_row).text(replacement_text)
        $(expand_table_row).addClass("collapse-cluster-entries")
        $(total_shown_entries[0]).text(max_viewable_entries)

      error: (response) ->
        $('.cluster-mgt-loader-wrapper').addClass('hidden')
        std_api_error(response, "There was an error loading cluster data.", reload: false)
    )
  else
    $('.cluster-mgt-loader-wrapper').addClass('hidden')
    rows = $(table_body).children('tr')
    replacement_text = footer_link_text.replace("collapse", "preview")
    $(expand_table_row).text(replacement_text)
    $(expand_table_row).removeClass("collapse-cluster-entries")
    $(total_shown_entries[0]).text('25')

    $(rows).each (i) ->
      if i > 24
        $(this).remove()

nf_data =''
companies_data = ''
serials_data = ''

$(document).on 'keydown','#wsa_statuses', (event) ->
  if (event.keyCode == 13)
    get_wsa_status()

window.get_wsa_status = () ->
  searches = $('#wsa_statuses').val();
  if searches == ""
    std_msg_error("No Companies or Serial numbers entered.","")
    return

  # empty data everytime

  nf_data = ''
  companies_data = ''
  serials_data = ''

  data_array = searches.split(',').map(Function.prototype.call, String.prototype.trim)
  $('.wsa-loader-wrapper').removeClass('hidden')
  $('#wsa-status-table').empty()

  serials  = {'serials':data_array}
  companies = {'companies': data_array}


  telemetry_call(serials, 'serials')
  telemetry_call(companies, 'companies')

  telemetry_interval = setInterval ()->
    if companies_data != '' && serials_data != ''
      clearInterval(telemetry_interval)
      build_wsa_table()
  , 3000



window.build_wsa_table = ()->
  $('#wsa-status-table').removeClass('hidden')

  wsa_data = []
  not_found = []

  #  have to stringify to compare objects and avoid duplicates
  for data, i in companies_data
    if  wsa_data.indexOf( JSON.stringify( companies_data[i]) ) == -1
      wsa_data.push(JSON.stringify( data) )

  for data, i in serials_data
    if  wsa_data.indexOf( JSON.stringify( serials_data[i]) ) == -1
      wsa_data.push(JSON.stringify( data) )

  for data, i in nf_data
    is_company = false
    is_serial = false
    for company, i in companies_data
      if company.company == data
        is_company = true

    for serial, i in serials_data
      if serial.serial == data
        is_serial = true

    if not_found.indexOf( nf_data[i]) == -1 && !is_company  && !is_serial
      not_found.push(data)

  data_header = ["", "Serial","Company", "Modification Time", "Source", "WSA Version"]
  wsa_div = document.getElementById('wsa-status-table')
  status_table = document.createElement('table');
  header_row = document.createElement('tr');
  status_table.classList = 'wsa-table'
  thead = document.createElement('thead');
  tbody = document.createElement('tbody');

  for header in data_header
    th = document.createElement('th');
    header_text = document.createTextNode(header);
    th.appendChild(header_text );
    header_row.appendChild(th);

  thead.appendChild(header_row);
  status_table.appendChild( thead);

  if wsa_data.length > 0
    for searched in wsa_data
      # limit amount of data displayed in table
      searched_el = JSON.parse( searched )
      { company, mtime, serial, source, wsa_version } = searched_el

      statuses = {serial, company, mtime, source, wsa_version}
      status_tr_body = document.createElement('tr');
      td = document.createElement('td');
      status = document.createTextNode(v);
      shared = document.createElement('td')
      shared.classList = 'shared_data'
      status_tr_body.appendChild(shared);

      for k, v of statuses
        td = document.createElement('td');
        status = document.createTextNode(v);
        td.appendChild(status);
        status_tr_body.appendChild(td);

      tbody.appendChild(status_tr_body);

  if not_found.length > 0
    for nf in not_found
      nf_type = 'company'
      if nf.startsWith("F") && nf.length == 11
        nf_type = 'serial'

      tr_body = document.createElement('tr');
      not_shared = document.createElement('td')
      not_shared.classList = 'not_shared_data'
      tr_body.appendChild(not_shared);
      td = document.createElement('td');
      serial_td = document.createElement('td');
      switch nf_type
        when 'company'
          td.appendChild( document.createTextNode(nf) );
          lg_td = document.createElement('td');
          serial_td.classList = 'nf_tds'
          lg_td.classList = 'nf_tds'

          lg_td.setAttribute('colspan', '3')

          tr_body.appendChild(serial_td )
          tr_body.appendChild(td)
          tr_body.appendChild(lg_td)

          tbody.appendChild(tr_body)
        when 'serial'

          td.appendChild( document.createTextNode(nf) );
          lg_td = document.createElement('td');
          lg_td.classList = 'nf_tds'
          lg_td.setAttribute('colspan', '4')
          tr_body.appendChild(td)
          tr_body.appendChild(lg_td)
          tbody.appendChild(tr_body)



  status_table.appendChild(tbody)
  wsa_div.appendChild(status_table)
  $('.wsa-loader-wrapper').addClass('hidden')

window.telemetry_call = (data, type) ->
    $.ajax(
      headers: window.headers()
      url: "/escalations/api/v1/escalations/wsa_statuses"
      method: 'POST'
      data: data
      success: (response) ->
        {not_found, wsa_statuses} = response
        switch type
          when 'companies'
            companies_data = wsa_statuses
          when 'serials'
            serials_data = wsa_statuses
        if typeof nf_data == 'string'
          nf_data = not_found
        else
          nf_data = nf_data.concat(not_found)
        return response
      error: (response) ->
        return response
    )

$('#cluster_filter_field').keyup (event) ->
    if event.keyCode == 13
      apply_filter_to_table()
    return

$ ->
# tooltip init these icons inside this DT, this MUST be on 'draw.dt', not page-load, DT doesn't exist on page-load
  $('#clusters-index').on 'draw.dt', ->
    $('#clusters-index .tooltipstered').tooltipster('destroy')  # remove existing dt tt attachments, then restore title attr
    $('#clusters-index .esc-tooltipped').tooltipster
      restoration: 'previous'
      theme: [
        'tooltipster-borderless'
        'tooltipster-borderless-customized'
      ]

  $('#duplicate-clusters-dialog').dialog({
    autoOpen : false
    width: 750
  });

window.take_selected_clusters = ()->
  selected_rows = $("#clusters-index").DataTable().rows('.selected').data().toArray()
  if selected_rows.length > 0
    headers = window.headers()
    $.ajax(
      url: '/escalations/api/v1/escalations/webcat/clusters/take'
      method: 'POST'
      headers: headers
      data: 'clusters': JSON.stringify(selected_rows)
      success: (response) ->
        json = $.parseJSON(response)
        if json.error
          notice_html = "<p>Something went wrong: #{json.error}</p>"
          std_msg_error('Error Taking Clusters', [json.error])
        else
          for cluster, i in json.clusters
            change_assignee_for_duplicates(cluster.domain, json.username)
            escaped_domain = cluster.domain.replaceAll('.', '_')
            $("#owner_#{escaped_domain}_#{cluster.platform}").text(json.username)

      error: (response) ->
        notice_html = "<p>Something went wrong: #{response.responseText}</p>"
    , this)
  else
    std_msg_error('No rows selected', ['Please select at least one row.'])

window.change_assignee_for_duplicates = (domain, username) ->
  selected_rows = $("#clusters-index").DataTable().rows('.selected').data().toArray()
  row = (row for row in selected_rows when row.domain is domain)[0]
  for duplicate in row.duplicates
    duplicate.assigned_to = username

window.return_selected_clusters = ()->
  selected_rows = $("#clusters-index").DataTable().rows('.selected').data().toArray()
  if selected_rows.length > 0
    $.ajax(
      url: '/escalations/api/v1/escalations/webcat/clusters/return'
      method: 'POST'
      headers: window.headers()
      data: 'clusters': JSON.stringify(selected_rows)
      success: (response) ->
        json = $.parseJSON(response)
        if json.error
          notice_html = "<p>Something went wrong: #{json.error}</p>"
          std_msg_error('Error Returning Clusters', [json.error])
        else
          for entry, i in selected_rows
            change_assignee_for_duplicates(entry.domain, '')
            escaped_domain = entry.domain.replaceAll('.', '_')
            $("#owner_#{escaped_domain}_#{entry.platform}").text('')

      error: (response) ->
        notice_html = "<p>Something went wrong: #{response.responseText}</p>"
    , this)
  else
    std_msg_error('no rows selected', ['Please select at least one row.'])


window.approve_cluster = (cluster_row_id) ->
  cluster = window.get_cluster_by_row_id(cluster_row_id)
  $.ajax(
    url: '/escalations/api/v1/escalations/webcat/clusters/proccess'
    method: 'POST'
    headers: window.headers()
    data: 'cluster': cluster
    success: (response) ->
      json = $.parseJSON(response)
      if json.error
        notice_html = "<p>Something went wrong: #{json.error}</p>"
        if json.error.includes("Manager needs to approve")
          std_msg_success('Cluster submitted, manager approval still needed', [json.error], reload: true)
        else
          std_msg_error('Error approving clusters', [json.error], reload: false)
      else
        std_msg_success("Cluster was submitted", '', reload: true)
    error: (response) ->
      notice_html = "<p>Something went wrong: #{response.responseText}</p>"
  , this)

window.decline_cluster = (cluster_row_id) ->
  cluster = window.get_cluster_by_row_id(cluster_row_id)
  $.ajax(
    url: '/escalations/api/v1/escalations/webcat/clusters/decline'
    method: 'POST'
    headers: window.headers()
    data: 'cluster': cluster
    success: (response) ->
      json = $.parseJSON(response)
      if json.error
        notice_html = "<p>Something went wrong: #{json.error}</p>"
        std_msg_error('Error declining clusters', [json.error])
      else
        std_msg_success("Cluster categories were declined", '', reload: true)
    error: (response) ->
      notice_html = "<p>Something went wrong: #{response.responseText}</p>"
  , this)

window.get_cluster_by_row_id = (row_id) ->
  $("#clusters-index").DataTable().row(row_id).data()

window.build_clusters_header = () ->
  return if $('#clusters-index_wrapper').length == 0
  urlParams = new URLSearchParams(location.search).get('f');
  if urlParams
    search_name = urlParams.toLowerCase()

    if !search_name.endsWith('clusters')
      search_name += ' clusters'

    new_header =
      '<div>' +
        '<span class="text-capitalize">' + search_name.replace(/_|%20/g, " ") + ' </span>' +
        '<span id="refresh-filter-button" class="reset-filter esc-tooltipped" title="Clear Search Results" onclick="webcat_clusters_refresh()"></span>' +
        '</div>'
  else
    new_header = 'Current Clusters'
  $('#clusters-index-title')[0].innerHTML = new_header

window.webcat_clusters_refresh = () ->
  window.location.replace('/escalations/webcat/clusters');

window.htmlEntitiesDecode = (str) ->
  str.replace(/&gt;/g, '>')
     .replace(/&quot;/g, '"')
     .replace(/&apos;/g, "'")
     .replace(/&amp;/g, '&')
     .replace(/&lt;/g, '<')

window.show_duplicates = (row) ->
  AC.WebCat.getAUPCategories().then((categories) ->
    $('#clusters-index-duplicates').find('tbody').html('')
    reverted_categories = {}
    for key, value of categories
      reverted_categories[value] = key.split(' - ')[0]

    data = window.clusters_table.row(row).data()

    duplicates = JSON.parse(window.htmlEntitiesDecode(data.duplicates))
    for duplicate in duplicates
      row = "<tr>"
      # check if already converted ids to names
      if duplicate.categories.every((element) -> return !isNaN(element))
        duplicate.categories = category_ids_to_names(reverted_categories, duplicate.categories)

      attribites = [
        duplicate.cluster_id,
        duplicate.domain,
        duplicate.global_volume,
        duplicate.wbrs_score,
        duplicate.platform,
        duplicate.assigned_to,
        duplicate.categories.join(', ')
      ]

      for attribute in attribites
        if attribute || attribute == 0
          row = row + "<td>#{attribute}</td>"
        else
          row = row + "<td></td>"
      $('#clusters-index-duplicates').find('tbody').append(row + "</tr>");
    $('#duplicate-clusters-dialog').dialog('open')
  )

# convert categories_ids to categories names
window.category_ids_to_names = (categories_hash, category_ids) ->
  categories = []
  for category_id in category_ids
    categories.push(categories_hash[category_id])
  return categories

window.webcat_cluster_type_filter = () ->
  types = $("input.show-cluster-types-filter:checked")
  if $(types).length > 1 || $(types).length == 0
    selected_type = 'all'
  else
    selected_type = $("input.show-cluster-types-filter:checked").val()
  url = new URL(document.location.href)
  url.searchParams.set('cluster_type', selected_type)
  document.location = url;
$ ->
  $(document).ready ->
    url = new URL(document.location.href)
    platform = url.searchParams.get('platform')
    cluster_type = url.searchParams.get('cluster_type')
    dropdownShouldToggle = true
     
    platforms = if platform then  platform.split(',') else ['Umbrella', 'Meraki', 'NGFW']
    $("input.show-platforms-filter").prop('checked', false)
   
    for platform in platforms
      $("[name='#{platform}_platform']").prop('checked', true)

    if(cluster_type)
      if cluster_type == 'all'
        $("input.show-cluster-types-filter").prop('checked', true)
      else
        $("input.show-cluster-types-filter").prop('checked', false)
        $("input.show-cluster-types-filter[name='show-cluster-#{cluster_type}'").prop('checked', true)


  @tableAttributes =
    dom: '<"datatable-top-tools no-margin-datatable-top-tool"lf>t<ip>'
    language: {
      search: "_INPUT_"
      searchPlaceholder: "Search within table"
    }
    stateSave: true
    pagingType: 'full_numbers'
    order: [ [
      6
      'desc'
    ] ]
    lengthMenu: [50, 100, 200]
    columnDefs: [
      {
        targets: [
          0
          1
          2
          5
          7
          10
          11
        ]
        orderable: false
        searchable: false
        sortable: false
      }
      {
        targets: [2]
        className: 'important-flag-col'
        searchable: false
        orderable: false
        orderable: true
      }
    ]
    columns: [
      {
        data: null
        width: '14px'
        className: 'expandable-row-column'
        'render':(data,type,full,meta)->
          if full.platform == 'WSA'
            return "<button class='expand-row-button-inline expand-row-button-#{data.cluster_id}'></button>"
          else
            return "<span />"
      }
      {
        data: null
        render: (data, type, full, meta) ->
          element_id = "cluster_row_#{meta.row}"
          return "<input type='checkbox' class='cluster-row-select' name='#{element_id}' id='#{element_id}' onclick='window.selectRow(#{element_id})'>"
      }
      {
        data: null
        width: '10px'
        defaultContent: '<span></span>'
        render: ( data )->

          { is_important } = data
          if is_important == 'true'
            '<span class="entry-important-flag esc-tooltipped is-important highlight-second-review" tooltip title="Important"></span>'
      }
      {
        data: 'cluster_id'
        width: '100px'
        className: 'cluster_identifier'
      }
      {
        data: 'domain'
        className: 'domain-column'
        render: (data) ->
           "<span ondblclick='copy_domain(\"#{data}\", this)'> #{data} </span>"
      }
      {
        data: null
        className: 'cluster-actions',
        with: '100px',
        render:  (data, _type, _full, meta) ->
          {domain, cluster_size, platform, duplicates} = data  # get domain string and cluster_size out of the data
          is_ip = /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/

          html = ""

          # only show WHOIS lookup button for normal domains, not ip addresses
          if !is_ip.test(domain)
            html += "<button type='button' class='whois-btn  esc-tooltipped' title='WHOIS Domain Lookup Information' onclick='WebCat.RepLookup.whoIsLookup(\"#{domain}\")'></button>"
          else
            html += "<button type='button' class='whois-btn right-margin'></button>"

          html += "<button type='button' class='google-btn right-margin esc-tooltipped' title='Google it!' onclick='window.open(\"https://www.google.com/search?q=#{domain}\", \"_blank\")'></button>
                  <button type='button' onclick='window.open(\"https://#{domain}\", \"_blank\")' class='open-in-tab-btn right-margin esc-tooltipped' title='Open #{domain} in a new tab'></button>"
          
          if window.htmlEntitiesDecode(duplicates) != '[]'
            html += "<button type='button' class='cluster-dup-btn right-margin esc-tooltipped' title='Show duplicates' onclick='show_duplicates(#{meta.row})'></button>"

          if platform == 'WSA'
            html += "<span class='vertical-separator'></span><span class='entry-count'>#{cluster_size}</span>"
          return html
      }
      {
        data: 'global_volume'
      }
      {
        data: 'wbrs_score'
      }
      {
        data: 'platform'
      }
      {
        data: 'assigned_to'
        orderable: true
        className: "alt-col assignee-col"
        render: (data, type, full, meta) ->
          escaped_domain = full.domain.replaceAll('.', '_') # jquery doesn't like dots in id
          return "<span id='owner_#{escaped_domain}_#{full.platform}'> #{data} </span>"
      }
      {
        data: 'cluster_id'
        className: 'category-column'
        render: (data, type, full, meta) ->
          escaped_domain = full.domain.replaceAll('.', '_') # jquery doesn't like dots in id
          "<select id='#{escaped_domain}_#{full.platform}_categories' class='form-control selectize cluster_categories' multiple='multiple' placeholder='Enter up to 5 categories' value='6' name='' #{if full.is_pending == true then 'disabled'}>"
      }
      {
        data: 'cluster_id'
        className: "alt-col"
        width: '70px'
        defaultContent: '<span></span>'
        render: (data, type, full, meta) ->
          if full.is_pending == true
            return "<div class='cluster-btn-container'>
                      <button class='toolbar-button icon-submit toolbar-button-spacer cluster-submit-button tooltipped' onclick='window.approve_cluster(#{meta.row})' type='button' title='Confirm Changes' />
                      <button class='toolbar-button cluster-cancel-button tooltipped' onclick='window.decline_cluster(#{meta.row})' type='button' title='Decline Updates' />
                    </div>"
      }
    ]
    initComplete: ->
      setTimeout (->
#         ensure the tooltips on cluster categories buttons appear on init and redraw, deal with lag
        $('#clusters-index .tooltipped').tooltipster
          theme: ['tooltipster-borderless', 'tooltipster-borderless-customized']
      ), 500
    drawCallback: ->
      setTimeout (->
        $('#clusters-index .tooltipped').tooltipster
          theme: ['tooltipster-borderless', 'tooltipster-borderless-customized']
      ), 500
      loader = $('.cluster-mgt-loader-wrapper')
      if loader.length > 0
        loader.addClass('hidden')

  if window.location.search.includes('WSA')
    @additional_attributes = {processing: true, pagin: true}
  else
    @additional_attributes = {
      serverSide: true
      processing: true
      ajax:
        url: ("/escalations/api/v1/escalations/webcat/clusters.json" + window.build_clusters_filters())
        headers: window.headers()
    }
  window.clusters_table = $('#clusters-index').DataTable($.extend({}, @tableAttributes, @additional_attributes))

  $('#clusters-index_filter input').addClass('table-search-input');

  window.populate_clusters_index_table()
  window.build_clusters_header()


