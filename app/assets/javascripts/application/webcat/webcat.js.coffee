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
        targets: [ 1 ]
        className: 'important-flag-col'
        orderable: false
        searchable: false
      {
        targets: [ 2 ]
        className: 'entry-id-col'
      }
    ]
    columns: [
      {
        data: null
        defaultContent: '<button class="expand-row-button-inline"></button>'
        width: '14px'
        orderable: false
        searchable: false
        sortable: false
      }
      {
        data: null
        defaultContent: '<span></span>'
        width: '24px'
      }
#      {
#        'render': (data, type, full, meta) ->
#          complaintID = full.complaint_id.toString()
#          '<a href="complaints/' + complaintID + '">' + complaintID + '</a>'
#        width: '45px'
#
#      }


      {
        data: 'entry_id'
        width: '50px'
      }
      {
        data: 'age'
        width: '40px'
      }
      {
        data: 'status'
        className: 'state-col'
      }
      {
        data: 'subdomain'
        width: '50px'
      }
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
      {
        'render': (data, type, full, meta) ->
          categories = ''
          category = ''
          plus = ''
          if full.category
            categories = full.category.split(',')
            category = categories[0]
            if category == "Not in our list"
              category = ""
          category
      }
      {
        data: 'suggested_category'
      }
      {
        data: 'wbrs_score'
        width: '20px'
      }
      {
        data: 'submitter_type'
      }
      {
        data: 'company_name'
      }
      { data: 'customer_name' }



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


  $('.cat_new_url').selectize {
    persist: false,
    create: false,
    maxItems: 5,
    valueField: 'value',
    labelField: 'value',
    searchField: ['text'],
    options: AC.WebCat.createSelectOptions()

  }


  $('#general_search').on 'keyup', (e) ->
    if event.keyCode == 13
      # do the ajax call
      filter = this.value
      headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
      $.ajax(
        url: '/api/v1/escalations/webcat/complaint_entries?search='+filter
        method: 'GET'
        headers: headers
        success: (response) ->

          json = $.parseJSON(response)
          if json.error
            notice_html = "<p>Something went wrong: #{json.error}</p>"
            alert(json.error)
          else
            datatable = $('#complaints-index').DataTable()
            datatable.clear();
            datatable.rows.add(json.data);
            datatable.draw();

        error: (response) ->
          std_api_error(response, "There was an error loading search results.", reload: false)
      , this)


  # advanced search tags
  createSelectOptions = ->
    tags = $('#search_tag_list')[0]
    if tags
      tag_list = tags.value
      array = tag_list.split(',')
      options = []
      for x in array
        options.push {name: x}
      return options

  $('#tags-input').selectize {
    persist: false
    create: false
    maxItmes: null
    valueField: 'name'
    labelField: 'name'
    searchField: 'name'
    options: createSelectOptions()

  }
