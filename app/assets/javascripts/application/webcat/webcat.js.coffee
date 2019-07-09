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
    url = $('#complaints-index').data('source')
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    $.ajax(
      url: '/escalations/webcat/complaint_entries.json'
      method: 'GET'
      headers: headers
      success: (response) ->
        return  response
      error: (response) ->
        console.log response
    , this)

  window.build_complaints_table = (  ) ->
#      new_data = response
        url = $('#complaints-index').data('source')
        complaint_table = $('#complaints-index').DataTable(
          processing: true
          serverSide: true
          ajax:
            url: url
          pagingType: 'full_numbers'

#        order: [ [
#          3
#          'desc'
#        ] ]
#        dom: '<"datatable-top-tools no-margin-datatable-top-tool"lf>t<ip>'
#        language: {
#          search: "_INPUT_"
#          searchPlaceholder: "Search within table"
#        }
          rowCallback: (row, data) ->
            cell = @api().row(row).nodes().to$()
            is_important = data[19]
            was_dismissed = data[18]
            if is_important
              cell.addClass 'highlight-second-review'
            if was_dismissed
              cell.addClass 'highlight-was-dismissed'

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
              targets: [ 3 ]
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
              render: (data,type,full,meta)->
                entry_id = full[11]
                return '<button class="expand-row-button-inline expand-row-button-' + entry_id + '"></button>'
            }
            {
              data: null
              orderable: false
              searchable: false
              sortable: false
              defaultContent: '<span></span>'
              width: '24px'
              render: (data,type,full,meta)->
                is_important = full[19]
                was_dismissed = full[18]

                if is_important
                  if was_dismissed
                    return '<div class="container-important-tags">' +
                      '<div class="esc-tooltipped is-important" tooltip title="Important"></div>' +
                      '<div class="esc-tooltipped was-reviewed" tooltip title="Reviewed"></div>' +
                      '</div>'
                  else
                    return '<span class="esc-tooltipped is-important" tooltip title="Important"></span>'
            },
            {data: 'entry_id'},
            {data: 'created_at'},
            {data: 'age_int'},
            {data: 'age'},
            {data: 'status'},
            {data: 'subdomain'},
            {data: 'domain'},
            {data: 'ip_address'},
            {data: 'path'},
            {data: 'category'},
            {data: 'suggested_category'},
            {data: 'suggested_category_count'},
            {data: 'wbrs_score'},
            {data: 'customer_name'},
            {data: 'company_name'},
            {data: 'assigned_to'},
            {data: 'uri'},
            {data: 'resolution'},
            {data: 'path'},
            {data: 'internal_comment'},
            {data: 'resolution_comment'},
            {data: 'is_important'},
            {data: 'was_dismissed'},
            {data: 'viewable'},
            {data: 'complaint_id'},
            {data: 'tags'},
#            {data: 'submitter_type'},
#            {data: 'description'},
            ]
#            {
##             column entry_id
#              render: (data,type,full,meta)->
#                 full[4]
#              width: '50px'
#            }
#            {
##             age column
#              width: '40px'
#              render: (data,type,full,meta)->
#                full[0]
#              width: '50px'
#            }
#            {
##             status column
#              className: 'state-col'
#              render: (data,type,full,meta)->
#                full[10]
#            }
#            {
##              tag column
#              render: (data,type,full,meta)->
#                tags = full[24]
#                tag_items = ''
#                if tags
#                  if tags.length
#                    for tag in tags
#                      item = '<span class="tag-capsule">' + tag + '</span>'
#                      tag_items = tag_items + item
#                  else
#                    tag_items = '<span class="missing-data">No tags</span>'
#                  tag_items
#            }
#            {
##             subdomin column
#              render:(data,type,full,meta)->
#                subdomain = full[13]
#                entry_id = full[4]
#                if subdomain
#                  '<span id="subdomain_' + entry_id + '">' + subdomain + '</span>'
#                else
#                  '<span id="subdomain_' + entry_id + '">' + '</span>'
#              width: '50px'
#            }
#            {
##             domain/ip column
#              render:(data,type,full,meta)->
#                domain = full[1]
#                ip_address = full[16]
#                entry_id = full[4]
#                if domain
#                  '<p class="input-truncate esc-tooltipped" id="domain_' + entry_id + '" title="' + domain + '">' + domain + '</p>'
#                else
#                  '<a href="http://' + ip_address + '" target="blank">' + ip_address + '</a>'
#
#            }
#            {
##             path column
#              render: (data, type, full, meta) ->
#                path = full[15]
#                entry_id = full[4]
#                if path == null
#                  path = ''
#                return '<span class="esc-tooltipped" id="path_' + entry_id + '" title="' +  path + '">' +  path + '</span>'
#              width: '50px'
#            }
#            {
##             categories column
#              render: (data, type, full, meta) ->
#                categories = full[9]
#                entry_id = full[4]
#                plus = ''
#                if categories != null
#                  if categories.replace(/,/g, '') != ''
#                    for category in categories
#                      if category == "Not in our list"
#                        category = ""
#                  else
#                    categories = ""
#                else
#                  categories = ""
#                categories = categories.replace(/,/g, ', ')
#
#                return '<span id="category_' + entry_id + '">' + categories + '</span>'
#            }
#            {
##             suggested_category column
#              render: (data, type, full, meta)->
#                category = full[21]
#                if category
#                  category = category.replace('+', '').replace(',', ', ')
#                category
#            }
#            {
##             wbrs_score column
#              width: '20px'
#              render: (data, type, full, meta) ->
#                wbrs_score = full[17]
#                entry_id = full[4]
#
#                '<span id="wbrs_score_' + entry_id + '">' + wbrs_score + '</span>'
#            }
#            {
##             submitter_type column
#              render: (data, type, full, meta) ->
#                submitter_type = full[22]
#                if submitter_type == 'CUSTOMER'
#                  '<button class="complaint-submitter-type icon-custom-star esc-tooltipped" title="Customer"></button>'
#                else
#                  data
#            }
#            {
##             company name column
#              render: (data, type, full, meta) ->
#                full[23]
#
#            }
#            {
##             assigned_to column
#              render: (data, type, full, meta) ->
#                full[5]
#            }
#            {
##             age column
#              render: (data, type, full, meta) ->
#                full[2]
#              visible: false
#            }

        select: 'style': 'os'
        responsive: true)

  if $('#complaints-index').length
    build_complaints_table()
#    build_complaints_table()
##    .then( (response)-> build_complaints_table(response) )

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

