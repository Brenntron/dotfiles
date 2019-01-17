window.display_tooltip = (id)->
  $('#cat_tooltip_' + id).tooltip('toggle')

window.td_truncate = (str, max, long) ->
  long = long or '...'
  if typeof str == 'string' and str.length > max then str.substring(0, max) + long else str

$ ->

  $('.cat_new_url').selectize {
    persist: false,
    create: false,
    maxItems: 5,
    valueField: 'category_id',
    labelField: 'category_name',
    searchField: ['category_name', 'category_code'],
    options: AC.WebCat.createSelectOptions()
  }

  if $('#complaints-index').length
    complaint_table = $('#complaints-index').DataTable(
      'rowCallback': (row, data, index) ->
        $node = @api().row(row).nodes().to$()
        $node.addClass 'not-shown'
        if  data.subdomain && data.subdomain.length > 0
          $node.addClass 'highlight-has-subdomain'
        if data.is_important
          $node.addClass 'highlight-second-review'
        if data.was_dismissed
          $node.addClass 'highlight-was-dismissed'
        if data.age_int < 10800
          $node.addClass 'highlight-minus3Hours'
        else if data.age_int < 18000
          $node.addClass 'highlight-minus5Hours'
        else if data.age_int > 18000
          $node.addClass 'highlight-plus5Hours'
        else
        return
      order: [ [
        3
        'desc'
      ] ]
      dom: '<"datatable-top-tools no-margin-datatable-top-tool"lf>t<ip>'
      language: {
        search: "_INPUT_"
        searchPlaceholder: "Search within table"
      }
      columnDefs: [
        {
          targets: [ 0 ]
          className: 'expandable-row-column'
          orderable: false
          searchable: false
        }
        {
          targets: [1]
          className: 'important-flag-col'
          orderable: false
          searchable: false
        }
        {
          targets: [ 2 ]
          className: 'entry-id-col'
        }
        {
          targets: [3]
          orderData: 15
        }
        {
          targets: [ 12 ]
          className: 'submitter-col'
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
            return '<button class="expand-row-button-inline expand-row-button-' + data.entry_id + '"></button>'
        }
        {
          data: null
          orderable: false
          searchable: false
          sortable: false
          defaultContent: '<span></span>'
          width: '24px'
        }
        {
          data: 'entry_id'
          width: '50px'
        }
        {
          data: 'age'
          width: '40px'
          'render':(data) ->
            parts = data.split(' ')
            days = parseInt(parts[0])
            hour = parseInt(parts[1])

            if days == 0
              if hour < 3
                data
              else if hour < 5
                '<span class="ticket-age-over3hr">' + data + '</span>'
              else
                '<span class="overdue">' + data + '</span>'
            else
              '<span class="overdue">' + data + '</span>'
        }
        {
          data: 'status'
          className: 'state-col'
        }
        {
          'render':(data,type,full,meta)->
            tags = full.tags
            tag_items = ''
            if tags.length > 0
              for tag in tags
                item = '<span class="tag-capsule">' + tag + '</span>'
                tag_items = tag_items + item
            else
              tag_items = '<span class="missing-data">No tags</span>'
            tag_items
        }
        {
          'render':(data,type,full,meta)->
            subdomain = full.subdomain

            if subdomain
              '<p id="subdomain_' + full.entry_id + '">' + subdomain + '</p>'
            else
              '<p id="subdomain_' + full.entry_id + '">' + '</p>'
          width: '50px'
        }
        {
          'render':(data,type,full,meta)->
            domain = full.domain
            ip_address = full.ip_address
            if domain
              '<p id="domain_' + full.entry_id + '">' + domain + '</p>'
            else
              '<a href="http://' + ip_address + '" target="blank">' + ip_address + '</a>'

        }
        {
          data: 'path'
          'render': (data, type, full, meta) ->
            full_data = data
            if type == 'display'
              full_data = td_truncate(data, 20)
            return '<span class="esc-tooltipped td-truncate" title="' + data + '">' + full_data + '</span>'
        }
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
          'render': (data) ->
            if data == 'CUSTOMER'
              '<button class="complaint-submitter-type icon-custom-star esc-tooltipped" title="Customer"></button>'
            else
              data
        }
        {
          data: 'company_name'
        }
        {
          data: 'assigned_to'
        }
        {
          data: 'age_int'
          visible: false
        }
      ]
      select: 'style': 'os'
      responsive: true)


    $('#complaints-index_filter input').addClass('table-search-input');

    $('#complaints-index tbody').on 'click', 'td.expandable-row-column', ->
      click_table_buttons complaint_table, this

    $('#general_search').on 'keyup', (e) ->
      if event.keyCode == 13
        # do the ajax call
        filter = this.value
        headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
        $.ajax(
          url: '/escalations/api/v1/escalations/webcat/complaint_entries?search='+filter
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

$('#exampleModal').on 'shown.bs.modal', ->
  $('button.toolbar-button.cat-btn').addClass('active')

#$('.toolbar-button').on 'click', ->

