$('#myModal').on 'shown.bs.modal', ->
  $('#myInput').trigger 'focus'

window.display_tooltip = (id)->
  $('#cat_tooltip_' + id).tooltip('toggle')

$ ->
  complaint_table = $('#complaints-index').DataTable(
    'rowCallback': (row, data, index) ->
      $node = @api().row(row).nodes().to$()
      $node.addClass 'not-shown'
      if  data.subdomain && data.subdomain.length > 0
        $node.addClass 'highlight-has-subdomain'
      if data.is_important
        $node.addClass 'highlight-second-review'
      if data.age_int < 10800
        $node.addClass 'highlight-minus3Hours'
      else if data.age_int < 18000
        $node.addClass 'highlight-minus5Hours'
      else if data.age_int > 18000
        $node.addClass 'highlight-plus5Hours'
      else
      return
    columnDefs: [
      {
        targets: [ 0 ]
        className: 'expandable-row-column'
        orderable: false
        searchable: false
      }
      {
        targets: [ 2 ]
        className: 'id-col'
        'width': '1%'
      }
      {
        targets: [ 3 ]
        className: 'entry-id-col'
        'width': '1%'
      }
    ]
    columns: [
      {
        data: null
        defaultContent: '<button class="expand-row-button-inline"></button>'
      }
      {
        'render': (data, type, full, meta) ->
          complaintID = full.complaint_id.toString()
          '<a href="complaints/' + complaintID + '">' + complaintID + '</a>'

      }
      { data: 'entry_id' }
      { data: 'age' }
      {
        data: 'status'
        className: 'state-col'
      }
      { data: 'subdomain'}
      {
        'render':(data,type,full,meta)->
          domain = full.domain
          ip_address = full.ip_address
          if domain
            '<p>' + domain + '</p>'
          else
            '<a href="http://' + ip_address + '" target="blank">' + ip_address + '</a>'

      }
      { data: 'path' }
      { data: 'customer_name' }
      { data: 'wbrs_score' }
      {
        sortable: false
        'render': (data, type, full, meta) ->
          categories = ''
          category = ''
          plus = ''
          if full.category
            categories = full.category.split(',')
            category = categories[0]
          if categories.length > 1
            plus = '+'
          '<p id="cat_tooltip_' + full.entry_id + '" data-toggle="tooltip" title="' + full.category + '" onmouseover=display_tooltip(' + full.entry_id + ')>' + category + plus + '</p>'
      }
      {
        data: 'assigned_to'
        className: 'alt-col'
      }
    ]
    select: 'style': 'os'
    responsive: true)
  populate_webcat_index_table()
  $('#complaints-index tbody').on 'click', 'td.expandable-row-column', ->
    click_table_buttons complaint_table, this


  $('#cat_new_url').selectize {
    persist: false,
    create: false,
    maxItems: 5
    valueField: 'name'
    labelField: 'name'
    searchField: 'name'
    options: AC.WebCat.createSelectOptions()

  }
