$('#myModal').on 'shown.bs.modal', ->
  $('#myInput').trigger 'focus'

window.display_tooltip = (id)->
  $('#cat_tooltip_' + id).tooltip('toggle')

$ ->
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
          'render': (data, type, full, meta) ->
            if data == 'CUSTOMER'
              '<button class="ticket-owner-button"></button>'
            else
              data
        }
        {
          data: 'company_name'
        }

        {
          data: 'assigned_to'
          className: 'alt-col'
        }
      ]
      select: 'style': 'os'
      responsive: true)
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
