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
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  #        url: '/escalations/api/v1/escalations/webcat/complaint_entries'
  window.get_ajax_data = () ->
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    $.ajax(
      url: '/escalations/api/v1/escalations/webcat/complaint_entries'
      method: 'GET'
      headers: headers
      success: (response) ->
        data = JSON.parse(response).data
        console.log data
        if data.subdomain != '' && data.subdomain != undefined
          console.log data.subdomain
        return  data
      error: (response) ->
        console.log response
    , this)

  window.build_complaints_table = ( response) ->
      new_data = JSON.parse(response).data
      complaint_table = $('#complaints-index').DataTable(
        ajax: ( data, callback, settings )->
          data = []
          for row in new_data
            console.log row.subdomain
            new_row = Object.keys(row).map((key) -> return row[key])
            data.push(new_row)
#            dataSrc: (json)->
#              data_array = JSON.parse( json ).data
#              console.log data_array
#              new_data = []
#              for obj in data_array
#                result = Object.keys(obj).map((key) -> return obj[key])
#                obj = result
#                new_data.push(result)
#
#              return data_array

          count = new_data.length
          setTimeout( ()->
            callback( {
              draw: data.draw,
              data: data,
              recordsTotal: count,
              recordsFiltered: count
            } );
          , 150 )

        processing: true,

#        scrollY: 500,
#        scroller: {
#          loadingIndicator: true
#        },

        order: [ [
          3
          'desc'
        ] ]
        dom: '<"datatable-top-tools no-margin-datatable-top-tool"lf>t<ip>'
        language: {
          search: "_INPUT_"
          searchPlaceholder: "Search within table"
        }
        rowCallback: (row, data) ->
            cell = @api().row(row).nodes().to$()
            {is_important, was_dismissed} = data
            if is_important
              cell.addClass 'highlight-second-review'
            if was_dismissed
              cell.addClass 'highlight-was-dismissed'

#          columnDefs: [
#            {
#              targets: [ 0 ]
#              className: 'expandable-row-column'
#              orderable: false
#              searchable: false
#            }
#            {
#              targets: [1]
#              className: 'important-flag-col'
#              orderable: false
#              searchable: false
#            }
#            {
#              targets: [ 2 ]
#              className: 'entry-id-col'
#            }
#            {
#              targets: [ 3 ]
#              orderData: 15
#            }
#            {
#              targets: [ 12 ]
#              className: 'submitter-col'
#            }
#          ]
        columns: [
            {
              data: null
              width: '14px'
              orderable: false
              searchable: false
              sortable: false
              'render':(data)->
                entry_id = data[11]
                return '<button class="expand-row-button-inline expand-row-button-' + entry_id + '"></button>'
            }
            {
              data: null
              orderable: false
              searchable: false
              sortable: false
              defaultContent: '<span></span>'
              width: '24px'
              'render': (data)->
                is_important = data[14]
                was_dismissed = data[26]
                if is_important
                  if was_dismissed
                    return '<div class="container-important-tags">' +
                      '<div class="esc-tooltipped is-important" tooltip title="Important"></div>' +
                      '<div class="esc-tooltipped was-reviewed" tooltip title="Reviewed"></div>' +
                      '</div>'
                  else
                    return '<span class="esc-tooltipped is-important" tooltip title="Important"></span>'
            }
            {
              data: 'entry_id'
              render: (data,type,full,meta)->
                 full[11]
              width: '50px'
            }
            {
              data: 'age'
              width: '40px'
              render: (data,type,full,meta)->
                full[0]
              width: '50px'
            }
            {
              data: 'status'
              className: 'state-col'
              render: (data,type,full,meta)->
                full[10]
            }
            {
              render: (data,type,full,meta)->
                tags = full[24]
                tag_items = ''
                if tags
                  if tags.length
                    for tag in tags
                      item = '<span class="tag-capsule">' + tag + '</span>'
                      tag_items = tag_items + item
                  else
                    tag_items = '<span class="missing-data">No tags</span>'
                  tag_items
            }
            {
              render:(data,type,full,meta)->
                subdomain = full.subdomain
                if subdomain
                  '<span id="subdomain_' + full.entry_id + '">' + subdomain + '</span>'
                else
                  '<span id="subdomain_' + full.entry_id + '">' + '</span>'
              width: '50px'
            }
            {
              render:(data,type,full,meta)->
                domain = full.domain
                ip_address = full.ip_address
                if domain
                  '<p class="input-truncate esc-tooltipped" id="domain_' + full.entry_id + '" title="' + domain + '">' + domain + '</p>'
                else
                  '<a href="http://' + ip_address + '" target="blank">' + ip_address + '</a>'

            }
            {
              data: 'path'
              render: (data, type, full, meta) ->
                full_data = data
                if type == 'display'
                  full_data = td_truncate(data, 20)
                return '<span class="esc-tooltipped td-truncate" id="path_' + full.entry_id + '" title="' + data + '">' + full_data + '</span>'
            }
            {
              render: (data, type, full, meta) ->
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
              render: (data, type, full, meta) ->
                '<span id="wbrs_score_' + full.entry_id + '">' + data + '</span>'
            }
            {
              data: 'submitter_type'
              render: (data) ->
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

  if $('#complaints-index').length
    get_ajax_data().then( (response)-> build_complaints_table(response) )

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
          url: 'escalations/webcat/complaint_entries'
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

