window.apply_filter_to_table = () ->
  filter = $("#cluster_filter_field").val()

  # if they have entered a regex, show the regex in upper-left area
  if filter != '' then $('.regex-area').removeClass('hidden')
  else $('.regex-area').addClass('hidden')

  $('#regex-filter').html(filter)
  populate_clusters_index_table(filter);

window.populate_clusters_index_table = (filter) ->
  if $('#clusters-index_wrapper').length > 0
    loader = $('.cluster-mgt-loader-wrapper')
    loader.removeClass('hidden')
    filter_param = ""
    if filter
      filter_param = "?regex=" + filter

    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    $.ajax(
      url: "/escalations/api/v1/escalations/webcat/clusters" + filter_param
      method: 'GET'
      headers: headers
      success: (response) ->
        loader.addClass('hidden')
        json = $.parseJSON(response)
        if json.data.length == 0
          std_msg_error("No clusters available.","")
        if json.error
          std_msg_error('Table Error', [json.error])
        else
          datatable = $('#clusters-index').DataTable()
          datatable.clear();
          datatable.rows.add(json.data);
          datatable.draw();
          selectize_category_inputs();

          $("#total_results").html(json.meta.rows_found)

      error: (response) ->
        loader.addClass('hidden')
        std_msg_error('Table Error', [response.responseText])
    , this)

window.categorize_clusters = () ->
  loader = $('.cluster-mgt-loader-wrapper')
  loader.removeClass('hidden')
  user_id = $("#user_id").val()
  comment = $("#cluster_comment_field").val()
  #cluster_id comment category_ids
  clusters_to_categorize = []
  clusters = $ '[id$=\'_categories\']'
  categories = []

  data = {}
  data["comment"] = comment
  data["user_id"] = user_id
  $(clusters).each ->
    id =  $(this).attr('id').split('_')[0]
    categories = $(this).find('option')

    if categories? and categories.length > 0
      category_values = []
      $(categories).each ->
        value = $(this).attr('value')
        category_values.push value

      data["cluster_id_" + id.toString()] = category_values

  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: "/escalations/api/v1/escalations/webcat/clusters/process_cluster"
    method: 'POST'
    headers: headers
    data: data
    success: (response) ->
      loader.addClass('hidden')
      json = $.parseJSON(response)
      if json.error
        std_msg_error('Process Error', [json.error])
      else
        $("#cluster_comment_field").val('')
        filter = $("#cluster_filter_field").val()
        if filter
          populate_clusters_index_table(filter)
        else
          populate_clusters_index_table()

    error: (response) ->
      loader.addClass('hidden')
      std_api_error(response, "There was an error loading search results.", reload: false)
  , this)

$ ->
#  Populate the cluster management table (temp data currently)
  window.clusters_table = $('#clusters-index').DataTable(
    dom: '<"datatable-top-tools no-margin-datatable-top-tool"lf>t<ip>'
    language: {
      search: "_INPUT_"
      searchPlaceholder: "Search within table"
    }
    order: [ [
      2
      'asc'
    ] ]
    lengthMenu: [50, 100, 500, 1000]
    columnDefs: [
      {
        targets: [
          0
          1
          6
        ]
        orderable: false
        searchable: false
      }
      {
        targets: [ 0 ]
        className: 'expandable-row-column'
      }
      {
        targets: [3]
        className: 'domain-column'
      }
      {
        targets: [6]
        className: 'category-column'
      }
    ]
    columns: [
      {
        data: null
        width: '14px'
        orderable: false
        searchable: false
        sortable: false
        'render':(data,type,full,meta)->
          return '<button class="expand-row-button-inline expand-row-button-' + data.cluster_id + '"></button>'
      }
      {
        data: null
        orderable: false
        searchable: false
        sortable: false
        render: (data, type, full, meta) ->
          return '<input type="checkbox" name="cluster_id_' + data.cluster_id + '" onclick="toggleRow(this)">'
      }
      {
        data: 'cluster_id'
        width: '100px'
      }
      {
        data: null,
        render: (data) ->
          html = ""
          {domain, cluster_size} = data  # get domain string and cluster_size out of the data
          is_ip = /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/

          # only show WHOIS lookup button for normal domains, not ip addresses
          if !is_ip.test(domain)
            html += "<button type='button' class='whois-btn right-margin esc-tooltipped' title='WHOIS Domain Lookup Information' onclick='domain_whois(\"#{domain}\")'></button>"
          else
            html += "<button type='button' class='whois-btn right-margin domain-spacer'></button>"

          html += "<button type='button' class='google-btn right-margin esc-tooltipped' title='Google it!' onclick='window.open(\"https://www.google.com/search?q=#{domain}\", \"_blank\")'></button>
                    #{domain} <button type='button' onclick='window.open(\"https://#{domain}\", \"_blank\")' class='open-in-tab-btn right-margin esc-tooltipped' title='Open #{domain} in a new tab'></button>
                    <span class='vertical-separator'></span><span class='entry-count'>#{cluster_size}</span>"

          return html
      }
      {
        data: 'global_volume'
      }
      {
        data: 'wbrs_score'
        width: '75px'
        render: ( data ) ->
          if data == undefined then data = ''
          wbrs_rep = wbrs_display(data)
          wbrs_score = parseFloat(data).toFixed(1)
          if wbrs_rep == undefined then wbrs_rep = 'unknown'
          if wbrs_rep == 'unknown'then wbrs_score = '--'
          tooltip_rep = wbrs_rep.toUpperCase()
          icon = "<span class='reputation-icon icon-#{wbrs_rep} esc-tooltipped' title='#{tooltip_rep}'></span>"
          return "<div class='reputation-icon-container'>#{icon}<span>#{wbrs_score}</span></div>"
      }
      {
        data: 'cluster_id'
        render: (data) ->
          '<select id="' + data + '_categories"' + 'class="form-control selectize cluster_categories" multiple="multiple" placeholder="Enter up to 5 categories" value="" name="">'
      }
    ]
  )
  $('#clusters-index_filter input').addClass('table-search-input');
  window.populate_clusters_index_table()

$ ->
  $(document).ready ->

# expand all functionality
window.expand_all_clusters = (tableId) ->
  selectedRows = $('table#' + tableId + ' tr[role="row"]')
  for row in selectedRows
    if !$(row).hasClass('shown')
      $(row).find('.expand-row-button-inline').click()

# collapse all functionality
window.collapse_all_clusters = (tableId) ->
  selectedRows = $('table#' + tableId + ' tr[role="row"]')
  for row in selectedRows
    if $(row).hasClass('shown')
      $(row).find('.expand-row-button-inline').click()

#  expand selected funtionality
window.expand_selected_clusters = (tableId) ->
  selectedRows = $('table#' + tableId + ' tr[role="row"].selected')
  for row in selectedRows
    if !$(row).hasClass('shown')
      $(row).find('.expand-row-button-inline').click()

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
        persist: false,
        create: false,
        maxItems: 5,
        closeAfterSelect: true,
        valueField: 'category_id',
        labelField: 'category_name',
        searchField: ['category_name', 'category_code'],
        options: AC.WebCat.createSelectOptions('#copycat_dialog #copycat-categories')
      }
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



window.toggleRow = (el) ->
  $(el).closest('tr').toggleClass('selected')


window.selectize_category_inputs = () ->
  category_inputs = $("select.cluster_categories")
  $(category_inputs).each ->
    if $(this).next("div").hasClass("selectize-control")
#          This is already selectized
    else
      $(this).selectize {
        persist: false,
        create: false,
        maxItems: 5,
        closeAfterSelect: true,
        valueField: 'category_id',
        labelField: 'category_name',
        searchField: ['category_name', 'category_code'],
        options: AC.WebCat.createSelectOptions("##{this.id}"),
      }

window.toggle_all_checkboxes = () ->
  if $('#clusters_check_box').prop('checked')
    $('#clusters-index').DataTable().rows().select()
    rows = $('table#clusters-index input[type="checkbox"]');
    i = 1
    while i < rows.length
      $(rows[i])[0].checked = true
      i++
  else
    $('#clusters-index').DataTable().rows().deselect()
    rows = $('table#clusters-index input[type="checkbox"]')
    for row in rows
      $(row)[0].checked = false

# Select rows in Clusters Table
$ ->
  $('#clusters_check_box').click ->
    toggle_all_checkboxes()

  # Moves cluster selectize to table draw so that selectize boxes properly initialize when changing number of items being displayed
  $("#clusters-index").on 'draw.dt', ->
    selectize_category_inputs()
    toggle_all_checkboxes()

  $("#clusters-index").on 'order.dt', ->
    selectize_category_inputs()

  #  Expand cluster rows
  $('#clusters-index tbody').on 'click', 'td.expandable-row-column, .entry-count', ->
    tr = $(this).closest('tr')
    row = window.clusters_table.row(tr)
    if row.child.isShown()
# This row is already open - close it
      row.child.hide()
      tr.removeClass 'shown'
    else
# Open this row
      $('.cluster-mgt-loader-wrapper').removeClass('hidden')
      cluster = row.data()

      table_head = '<table class="table cluster-path-table">' + '<thead>' + '<tr>' +
        '<th class="clusterpath-col-path">Cluster Paths</th>' +
        '<th class="clusterpath-col-path">Customer Name</th>' +
        '<th class="clusterpath-col-volume text-center">APAC Region Volume</th>' +
        '<th class="clusterpath-col-volume text-center">EMRG Region Volume</th>' +
        '<th class="clusterpath-col-volume text-center">EURP Region Volume</th>' +
        '<th class="clusterpath-col-volume text-center">GLOB Volume</th>' +
        '<th class="clusterpath-col-volume text-center">JAPN Volume</th>' +
        '<th class="clusterpath-col-volum text-centere">NA Region Volume</th>' +
        '<th class="clusterpath-col-wbrs text-center">WBRS Score</th>' +
        '</tr>' +
        '</thead>' + '<tbody>'
      missing_data = '<span class="missing-data">Missing data</span>'
      entry_rows = []


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
              wbrs_col = "<div class='reputation-icon-container'><span class='reputation-icon icon-#{wbrs_rep} esc-tooltipped' title='#{wbrs_rep.toUpperCase()}'></span> #{wbrs_score}</div>"
              entry_row = "<tr class='index-entry-row'>
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
              entry_rows.push entry_row
              total_shown_entries = i + 1
              return

          bottom_row = '<tr class="cluster-entry-bottom-row">' +
            '<td colspan="10">Previewing cluster entries 1 - <span class="total-shown-entries">' + total_shown_entries + '</span>. ' + link_to_more_results + '<span class="total-cluster-entry-count">Total Entries: ' + total_entries + '.</span></td>' +
            '</tr>'

          complete_table = table_head + entry_rows.join('') + '</tbody><tfoot>' + bottom_row + '</tfoot></table>'

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
            wbrs_col = "<div class='.reputation-icon-container'><span class='reputation-icon icon-#{wbrs_rep} esc-tooltipped' title='#{wbrs_rep.toUpperCase()}'></span> #{wbrs_score}</div>"
            entry_row = "<tr class='index-entry-row'>
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
            entry_rows.push entry_row
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


window.get_wsa_status = () ->
  serials = $('#wsa_statuses').val();
  data_array =  serials.split(/[\s,;\t\n]+/);
  $.ajax(
    method: 'POST'
    headers : {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    url: "/escalations/api/v1/escalations/wsa_statuses"
    data:
      serials: data_array
    success: (response) ->
      dialog = $('#wsa-status-dialog')
      if $('.wsa-table:visible').length > 0
        dialog.dialog('close')
      {not_found, wsa_statuses} = response
      status_table = ''
      nf_div = ''
      data_points = ["Serial","Company", "Modification Time", "Source", "WSA Version"]
      header_row = document.createElement('tr');

      if not_found.length > 0

        nf_div = document.createElement('div');
        nf_div.classList = 'not-found-wsa'
        nf_list = document.createTextNode( not_found.join(', ') );
        nf_div.appendChild( nf_list );

      if wsa_statuses.length > 0

        status_table = document.createElement('table');
        status_table.classList = 'wsa-table'

        for header in data_points
           tr_header = document.createElement('tr');
           th = document.createElement('th');
           header_text = document.createTextNode(header);
           th.appendChild(header_text );
           tr_header.appendChild(th);
           header_row.appendChild(th);
        status_table.appendChild(header_row);

        for searched_serial in wsa_statuses
          { company, mtime, serial, source, wsa_version } = searched_serial
          statuses = [serial, company, mtime, source, wsa_version]
          tr_body = document.createElement('tr');
          for status in statuses
            td = document.createElement('td');
            status = document.createTextNode(status);
            td.appendChild(status);
            tr_body.appendChild(td);
            status_table.appendChild(tr_body);

      dialog.dialog({
        width: 'auto',
        minWidth: '600px',
        open: () ->
          $(this).css('padding', '15px')
        close : () ->
          $(this).empty()
      })

      wsa_el = document.getElementById('wsa-status-dialog')
      wsa_el.appendChild(status_table)
      wsa_el.appendChild(nf_div)
#      $(wsa_el).find('td:first')addClass()
#      background-color: #d7dadb2b;
      dialog.dialog('open')

#      std_msg_success('WSA Status',["#{status_table}"], reload: false)

    error: (response) ->
      console.log response
  )

  window.select_or_deselect_cluster = (cluster_id)->
    $('.cluster-path-checkbox_' + cluster_id).prop('checked', $('#' + cluster_id).prop('checked'))

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
