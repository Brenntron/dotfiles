window.display_tooltip = (id)->
  $('#cat_tooltip_' + id).tooltip('toggle')

window.td_truncate = (str, max, long) ->
  long = long or '...'
  if typeof str == 'string' and str.length > max then str.substring(0, max) + long else str

$ ->

  $('#web-cat-search #general_search').on 'keyup', (e) ->
    { keyCode }= e
    if keyCode == 13
      search_string = $('#web-cat-search .search-box').val()
      if search_string == ''
       refresh_localStorage()
       refresh_url()
      else
        localStorage.search_type = 'contains'
        localStorage.search_name = ''
        localStorage.search_conditions = JSON.stringify({value:search_string})
      refresh_url()

  window.set_webcat_advanced = () ->
    # creating form object from array made from advanced dropdown form
    form = {}
    for item in $('#cat_named_search').serializeArray()
      { name, value } = item
      name = name.toLowerCase().replace(/-/g, '_')
      form[name] = value

    localStorage.search_type = 'advanced'
    localStorage.search_name = form.name
    localStorage.search_conditions = JSON.stringify(
      status: form.status
      description: form.description
      ip_address: form.complaint_id
      resolution: form.resolution
      channel: form.channel
      category: form.category
      customer_name: form.customer_name
      customer_email: form.customer_email
      company: form.company
      tags: form.tags
      submitted_older: form.date_submitted_older
      submitted_newer: form.date_submitted_newer
      modified_older: form.date_modified_newer
      modified_newer: form.date_modified_older
    )
#    refresh_url()
  window.build_named_search = (search_name) ->
    localStorage.search_type = 'named'
    localStorage.search_name = search_name
    localStorage.removeItem('search_conditions')

    refresh_url()

  build_data = () ->
    { search_type, search_name, search_conditions } = localStorage
    { search } = location

    if search != ''
      search_type = 'standard'

    switch(search_type)
      when 'advanced'
        data = {
          search_type: search_type
          search_name : search_name
          search_conditions: JSON.parse(search_conditions)
        }
      when 'contains'
        data = {
          search_type: search_type
          search_conditions: JSON.parse(search_conditions)
        }
      when 'standard'
        data = {
          search_type: search_type
          search_name: search.replace('?f=', '')
        }
      when 'named'
        data = {
          search_type: search_type
          search_name: search.replace('?f=', '')
        }
    data

  refresh_url = (href) ->
    { search_type, search_name } = localStorage
    url_check = current_url.split('/escalations/file_rep/disputes/')[0]
    new_url = '/escalations/file_rep/disputes'
    if href != undefined
      window.location.replace(new_url + href)
    if !href && typeof parseInt(url_check) == 'number'
      window.location.replace('/escalations/webcat/complaints')

  refresh_localStorage = () ->
    localStorage.removeItem('search_type')
    localStorage.removeItem('search_name')
    localStorage.removeItem('search_conditions')

  $('.cat_new_url').selectize {
    persist: false,
    create: false,
    maxItems: 5,
    valueField: 'category_id',
    labelField: 'category_name',
    searchField: ['category_name', 'category_code'],
    options: AC.WebCat.createSelectOptions()
  }

  url = $('#complaints-index').data('source')
  current_url = window.location.href
  complaint_table = ''

  build_complaints_table = () ->
        complaint_table = $('#complaints-index').DataTable(
          processing: true
          serverSide: true
          ajax:
            url: url
            data: build_data()
          pagingType: 'full_numbers'

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
            { is_important, was_dismissed, age_int } = data
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
                render: ( data ) ->
                  { entry_id } = data
                  return '<button class="expand-row-button-inline expand-row-button-' + entry_id + '"></button>'
              }
              {
                data: null
                orderable: false
                searchable: false
                sortable: false
                defaultContent: '<span></span>'
                width: '10px'
                render: ( data )->
                  { is_important, was_dismissed } = data
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
                width: '50px'
              }
              {
#               age column
                width: '40px'
                render: ( data, type, full, meta) ->
                  { age, case_opened_at } = full
                  if age != "<1 hr"
                    dispute_duration = moment( case_opened_at ).fromNow()
                  if dispute_duration.includes('minute')
                    dispute_latency = age
                  if dispute_duration.includes('hour')
                    hours = parseInt(dispute_duration.replace(/[^0-9]/g, ''))
                  if hours <= 3
                    dispute_latency = age
                  else
                    dispute_latency = '<span class="ticket-age-over3hr">' + age + '</span>'
                  if hours > 12
                    dispute_latency = '<span class="ticket-age-over12hr">' + age + '</span>'
                  else
                    dispute_latency = '<span class="ticket-age-over12hr">' + age + '</span>'
                  if dispute_duration.includes('day')
                    day = parseInt(age.replace(/[^0-9]/g, ''))
                  if day >= 1
                    dispute_latency = '<span class="ticket-age-over12hr">' + age + '</span>'
                  if dispute_duration.includes('months')
                    month = parseInt(age.replace(/[^0-9]/g, ''))
                    dispute_latency = '<span class="ticket-age-over12hr">' + age + '</span>'
                  if dispute_duration.includes('year')
                    year = parseInt(age.replace(/[^0-9]/g, ''))
                    dispute_latency = '<span class="ticket-age-over12hr">' + age + '</span>'
                  dispute_latency
              }
              {
                data: 'status'
                className: 'state-col'
              }
              {
                data: 'tags'
                render: ( data )->
                  if data
                    tags = data.substring( 1, data.length-1 ).replace(/&quot;/g,'');
                    tag_items = ''
                    tag_list = tags.split(',').map ( tag ) -> return tag.trim();
                    tag_list = tag_list.filter ( tag, index )-> return tag_list.indexOf( tag ) == index && tag != ''

                    if tag_list.length
                      for tag in tag_list
                        item = '<span class="tag-capsule">' + tag + '</span>'
                        tag_items += item
                    else
                      tag_items = '<span class="missing-data">No tags</span>'
                    tag_items
              }
              {
#                subdomain column
                data: 'subdomain'
                render:(data,type,full,meta)->
                  {subdomain, entry_id} = full

                  if subdomain
                    '<span id="subdomain_' + entry_id + '">' + subdomain + '</span>'
                  else
                    '<span id="subdomain_' + entry_id + '">' + '</span>'
                width: '50px'
              }
              {
                data: 'domain'
                render:( data, type, full, meta )->
                  { domain, ip_address, entry_id } = full
                  if domain
                    '<p class="input-truncate esc-tooltipped" id="domain_' + entry_id + '" title="' + domain + '">' + domain + '</p>'
                  else
                    '<a href="http://' + ip_address + '" target="blank">' + ip_address + '</a>'
              }
              {
                data: 'path'
                render: ( data, type, full, meta ) ->
                  { path , entry_id } = full
                  if type == 'display'
                    path = td_truncate(data, 20)
                  return '<span class="esc-tooltipped td-truncate" id="path_' + entry_id + '" title="' + path + '">' + path + '</span>'
              }
              {
                data: 'category'
                render: ( data, type, full, meta ) ->
                  categories = ''
                  category = ''
                  plus = ''
                  { category , entry_id } = full
                  if category
                    categories = category.split(',')
                    category = categories[0]
                    if category == "Not in our list"
                      category = ""
                  '<span id="category_' + entry_id + '">' + category + '</span>'
              }
              {
                data: 'suggested_category'
              }
              {
                data: 'wbrs_score'
                width: '20px'
                render: ( data, type, full, meta ) ->
                  { wbrs_score, entry_id } = full
                  '<span id="wbrs_score_' + entry_id + '">' + wbrs_score + '</span>'
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
    build_complaints_table()

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

