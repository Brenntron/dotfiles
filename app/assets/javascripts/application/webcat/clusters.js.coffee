window.populate_clusters_index_table = (filter) ->
  filter_param = ""
  if filter
    filter_param = "?regex=" + filter

  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: "/escalations/api/v1/escalations/webcat/clusters" + filter_param
    method: 'GET'
    headers: headers
    success: (response) ->

      json = $.parseJSON(response)
      if json.data.length == 0
        std_msg_error("No clusters available.","")
      if json.error
        notice_html = "<p>Something went wrong: #{json.error}</p>"
        alert(json.error)
      else
        datatable = $('#clusters-index').DataTable()
        datatable.clear();
        datatable.rows.add(json.data);
        datatable.draw();

        $('.cluster_categories').selectize {
          persist: false,
          create: false,
          maxItems: 5,
          valueField: 'value',
          labelField: 'value',
          searchField: ['text'],
          options: AC.WebCat.createSelectOptions()
        }

    error: (response) ->
      notice_html = "<p>Something went wrong: #{response.responseText}</p>"
  , this)

window.fetch_cluster_data = (id) ->
  std_msg_ajax(
    method: 'GET'
    url: "/escalations/api/v1/escalations/webcat/clusters/" + id
    data: {}
    success: (response) ->
      json = $.parseJSON(response)
      json.data
      console.log (json.data)
    error: (response) ->
  )

window.categorize_cluster = (cluster_id, comment, category_ids) ->
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: "/escalations/api/v1/escalations/webcat/clusters/process_cluster"
    method: 'POST'
    headers: headers
    data: {cluster_id: cluster_id, category_ids: category_ids, comment: comment}
    success: (response) ->

      json = $.parseJSON(response)
      if json.error

      else

    error: (response) ->
      notice_html = "<p>Something went wrong: #{response.responseText}</p>"
  , this)

$ ->
#  Populate the cluster management table (temp data currently)
  window.clusters_table = $('#clusters-index').DataTable(
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
        data: 'cluster_id'
        orderable: false
        searchable: false
        sortable: false
        render: (data, type, full, meta) ->
          '<input type="checkbox" name="id[]" onclick="toggleRow(this)">'
      }
      {
        data: 'cluster_id'
        width: '100px'
      }
      {
        data: 'domain',
        render: (data) ->
          regexp = /^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/i;
          if (data.match(regexp))
            data
          else
            if (data.startsWith('http') is false)
              data = 'http://' + data
              '<button type="button" class="help-btn right-margin esc-tooltipped" title="Whois Domain Lookup Information" onclick="domain_whois(\'' + data + '\')"></button>' +
              '<button type="button" class="google-btn right-margin esc-tooltipped" title="Google it!" onclick="window.open(\'https://www.google.com/search?q=' + data + '\')"></button>' +
              data + '<button type="button" onclick="window.open(\'' + data + '\', \'_blank\') " class="data-btn right-margin esc-tooltipped", title="Open ' + data + ' in a new tab"></button>' +
              ' <span class="label right-margin label-default">3</span>' # TODO: Put real data here
      }
      {
        data: 'global_volume'
      }
      {
        data: null
        defaultContent: 'N/A'
      }
      {
        data: 'cluster_id'
        render: (data) ->
          '<select id="' + data + '_categories"' + 'class="form-control selectize cluster_categories" multiple="multiple" placeholder="Enter up to 5 categories" value="" name="">'
      }
    ]
  )
  window.populate_clusters_index_table()

  #  Nested cluster entries within the parent cluster row
  #  Format established below
  format = (cluster_entry_row) ->
    cluster_entry = cluster_entry_row.data()
    missing_data = '<span class="missing-data">No Data</span>'

    cluster_entry_html = ''
    cluster_entry_html =
      '<table><tr><td>' +
      'Testing setup' +
      '</td></tr></table>'

    cluster_entry_html


$ ->
  $(document).ready ->

# expand all functionality
window.expand_all = (tableId) ->
  selectedRows = $('table#' + tableId + ' tr[role="row"]')
  i = 0
  while i < selectedRows.length
    if !$(selectedRows[i]).hasClass('shown')
      $(selectedRows[i]).find('.expand-row-button-inline').click()
    i = i + 1

# collapse all functionality
window.collapse_all = (tableId) ->
  selectedRows = $('table#' + tableId + ' tr[role="row"]')
  i = 0
  while i < selectedRows.length
    if $(selectedRows[i]).hasClass('shown')
      $(selectedRows[i]).find('.expand-row-button-inline').click()
    i = i + 1

#  expand selected funtionality
window.expand_selected = (tableId) ->
  selectedRows = $('table#' + tableId + ' tr[role="row"].selected')
  i = 0
  while i < selectedRows.length
    if !$(selectedRows[i]).hasClass('shown')
      $(selectedRows[i]).find('.expand-row-button-inline').click()
    i = i + 1

#  collapse selected funtionality
window.collapse_selected = (tableId) ->
  selectedRows = $('table#' + tableId + ' tr[role="row"].selected')
  i = 0
  while i < selectedRows.length
    if $(selectedRows[i]).hasClass('shown')
      $(selectedRows[i]).find('.expand-row-button-inline').click()
    i = i + 1

# open selected funtionality
window.open_selected = (tableId) ->
  table = $('table#' + tableId).DataTable()
  $.map table.rows('.selected').data(), (row) ->
    domain = row.domain
    if !domain.startsWith('http://')
      domain = 'http://' + domain
    window.open(domain, '_blank')

# open all functionality
window.open_all = (tableId) ->
  table = $('table#' + tableId).DataTable()
  $.map table.rows().data(), (row) ->
    domain = row.domain
    if !domain.startsWith('http://')
      domain = 'http://' + domain
    window.open(domain, '_blank')


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
        valueField: 'value',
        labelField: 'value',
        searchField: ['text'],
        options: AC.WebCat.createSelectOptions()
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
    i = 0
    values = []

  if (selectedRows.length == 0)
    std_msg_error('CopyCat Error', ['Select at least one row to paste categories to.'])
  else
    selectedRows = $('#clusters-index tr[role="row"].selected')
    i = 0
    values = []
    while i < selectedRows.length
      rowSelectize = $(selectedRows[i]).find('.category-column .selectize')[0].selectize
      rowSelectize.setValue(selectedValues, true)
      i++



window.toggleRow = (el) ->
  $(el).closest('tr').toggleClass('selected')

# Select rows in Clusters Table
$ ->
  $('#clusters_check_box').click ->
    if $('#clusters_check_box').prop('checked')
      $('#clusters-index').DataTable().rows().select()
      rows = $('table#clusters-index input[type="checkbox"]');
      i = 1
      while i < rows.length
        $(rows[i])[0].checked = true
        console.log(rows[i].value)
        i++
    else
      $('#clusters-index').DataTable().rows().deselect()
      rows = $('table#clusters-index input[type="checkbox"]')
      i = 1
      while i < rows.length
        $(rows[i])[0].checked = false
        i++


  $('#clusters-index tbody').on 'click', 'td.expandable-row-column', ->
    tr = $(this).closest('tr')
    row = window.clusters_table.row(tr)
    if row.child.isShown()
# This row is already open - close it
      row.child.hide()
      tr.removeClass 'shown'
    else
# Open this row
      cluster = row.data()

      table_head = '<table class="table cluster-path-table">' + '<thead>' + '<tr>' +
        '<th><input class="cluster_path_select_all" type="checkbox" onclick="select_or_deselect_cluster(' + cluster.cluster_id + ')" id=' + cluster.cluster_id + ' /></th>' +
        '<th class="clusterpath-col-path">Cluster Paths</th>' +
        '<th class="clusterpath-col-volume text-center">APAC Region Volume</th>' +
        '<th class="clusterpath-col-volume text-center">EMRG Region Volume</th>' +
        '<th class="clusterpath-col-volume text-center">EURP Region Volume</th>' +
        '<th class="clusterpath-col-volume text-center">GLOB Volume</th>' +
        '<th class="clusterpath-col-volume text-center">JAPN Volume</th>' +
        '<th class="clusterpath-col-volum text-centere">NA Region Volume</th>' +
        '<th class="clusterpath-col-wbrs text-center">WBRS Score</th>' +
        '</tr>' +
        '</thead>' + '<tbody>'
      missing_data = '<span class="missing-data">Missing Data</span>'
      entry_rows = []


      std_msg_ajax(
        method: 'GET'
        url: "/escalations/api/v1/escalations/webcat/clusters/" + cluster.cluster_id
        data: {}
        success: (response) ->
          json = $.parseJSON(response)
          entry = json.data

          $(entry).each ->
            entry_row = '<tr class="index-entry-row">' +
              '<td class="clusterpath-col-spacer"><input type="checkbox" class="cluster-path-checkbox_' + cluster.cluster_id + '"</td>' + # Spacer for the check box row
              '<td class="clusterpath-col-path">' + this.url + '</td>' +
              '<td class="clusterpath-col-volume text-center">' + this.apac_region_volume + '</td>' +
              '<td class="clusterpath-col-volume text-center">' + this.emrg_region_volume + '</td>' +
              '<td class="clusterpath-col-volume text-center">' + this.eurp_region_volume + '</td>' +
              '<td class="clusterpath-col-volume text-center">' + this.glob_volume + '</td>' +
              '<td class="clusterpath-col-volume text-center">' + this.japn_region_volume + '</td>' +
              '<td class="clusterpath-col-volume text-center">' + this.na_region_volume + '</td>' +
              '<td class="clusterpath-col-wbrs text-center">' + this.wbrs_score + '</td>' +
              '</tr>'
            entry_rows.push entry_row
            return
          complete_table = table_head + entry_rows.join('') + '</tbody></table>'

          row.child(complete_table).show()
          tr.addClass 'shown'
          td = $(tr).next('tr').find('td:first')
          $(td).addClass 'dispute-entry-table-wrapper'
        error: (response) ->
      )


    return
#  Expand cluster rows

  window.format = (cluster) ->
    table_head = '<table class="table cluster-path-table">' + '<thead>' + '<tr>' + '<th><input class="cluster_path_select_all" type="checkbox" onclick="select_or_deselect_cluster(' + cluster.cluster_id + ')" id=' + cluster.cluster_id + ' /></th>' + '<th class="clusterpath-col-path">Cluster Paths</th>' + '<th class="clusterpath-col-volume">Volume</th>' + '<th class="clusterpath-col-wbrs">WBRS Score</th>' + '<th class="clusterpath-col-rules">Rules</th>' + '</tr>' + '</thead>' + '<tbody>'
    missing_data = '<span class="missing-data">Missing Data</span>'
    entry_rows = []
    entry = [
      {
        "id": 1,
        "path": "255.255.255.0",
        "volume": 8.488308,
        "rules": "Test"
      },
      {
        "id": 2,
        "path": "192.168.0.1",
      }
    ]
    $(entry).each ->

      entry_row = '<tr class="index-entry-row">' +
        '<td class="clusterpath-col-spacer"><input type="checkbox" class="cluster-path-checkbox_' + cluster.cluster_id + '"</td>' + # Spacer for the check box row
        '<td class="clusterpath-col-path">' + this.path + '</td>' +
        '<td class="clusterpath-col-volume text-center">' + this.volume + '</td>' +
        '<td class="clusterpath-col-wbrs">' + this.wbrs + '</td>' +
        '<td class="clusterpath-col-rules">' + this.rules + '</td>' +
        '</tr>'
      entry_rows.push entry_row
      return
    # `d` is the original data object for the row
    table_head + entry_rows.join('') + '</tbody></table>'

  window.select_or_deselect_cluster = (cluster_id)->
    $('.cluster-path-checkbox_' + cluster_id).prop('checked', $('#' + cluster_id).prop('checked'))


