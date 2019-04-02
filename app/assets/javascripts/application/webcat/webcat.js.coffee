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
          'render':(data,type,full,meta) ->
            if (~data.indexOf('minute'))
              complaint_latency = data
            if (~data.indexOf('hour'))
              hours = parseInt(data.replace(/[^0-9]/g, ''))
              if hours <= 3
                complaint_latency = data
              else
                complaint_latency = '<span class="ticket-age-over3hr">' + data + '</span>'
              if hours > 12
                complaint_latency = '<span class="overdue">' + data + '</span>'
            else
              complaint_latency = data
            if (~data.indexOf('day'))
              day = parseInt(data.replace(/[^0-9]/g, ''))
              if day >= 1
                complaint_latency = '<span class="overdue">' + data + '</span>'
            if (~data.indexOf('months'))
              month = parseInt(data.replace(/[^0-9]/g, ''))
              complaint_latency = '<span class="overdue">' + data + '</span>'
            if (~data.indexOf('year'))
              year = parseInt(data.replace(/[^0-9]/g, ''))
              complaint_latency = '<span class="overdue">' + data + '</span>'
            complaint_latency
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
              '<span id="subdomain_' + full.entry_id + '">' + subdomain + '</span>'
            else
              '<span id="subdomain_' + full.entry_id + '">' + '</span>'
          width: '50px'
        }
        {
          'render':(data,type,full,meta)->
            domain = full.domain
            ip_address = full.ip_address
            if domain
              '<p class="input-truncate esc-tooltipped" id="domain_' + full.entry_id + '" title="' + domain + '">' + domain + '</p>'
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
            '<span id="category_' + full.entry_id + '">' + category + '</span>'
        }
        {
          data: 'suggested_category'
        }
        {
          data: 'wbrs_score'
          width: '20px'
          'render': (data, type, full, meta) ->
            '<span id="wbrs_score_' + full.entry_id + '">' + data + '</span>'
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

    $('#complaints-index tbody').on 'click', ' .nested-complaint-data', ->
      $(this).focus()
      $(this).toggleClass('highlight-text')
      element = $(this)
      innertext = $(this).text()
      copyToClipboard(innertext)
      $(element).after( "<p id='copiedAlert'>Copied to clipboard!</p>" )
      setTimeout (->
        $("#copiedAlert").remove()
      ), 1000

    copyToClipboard = (text) ->
      dummy = document.createElement('input')
      document.body.appendChild dummy
      dummy.setAttribute 'value', text
      dummy.select()
      document.execCommand 'copy'
      document.body.removeChild dummy

    $('#complaints-index tbody').on 'click', 'td.expandable-row-column', ->
      click_table_buttons complaint_table, this

    $('#general_search').on 'keyup', (e) ->
      if event.keyCode == 13
        # do the ajax call
        $('#loader-modal').modal({
          keyboard: false
        })
        filter = this.value
        headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
        $.ajax(
          url: '/escalations/api/v1/escalations/webcat/complaint_entries?search='+filter
          method: 'GET'
          headers: headers
          success: (response) ->

            json = $.parseJSON(response)
            if json.error
              $('#loader-modal').modal 'hide'
              notice_html = "<p>Something went wrong: #{json.error}</p>"
              alert(json.error)
            else
              datatable = $('#complaints-index').DataTable()
              datatable.clear();
              datatable.rows.add(json.data);
              datatable.draw();
              $('#loader-modal').modal 'hide'

          error: (response) ->
            $('#loader-modal').modal 'hide'
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

