window.display_tooltip = (id)->
  $('#cat_tooltip_' + id).tooltip('toggle')

window.td_truncate = (str, max, long) ->
  long = long or '...'
  if typeof str == 'string' and str.length > max then str.substring(0, max) + long else str

$ ->

  $('#web-cat-search #general_search').on 'keyup', (e) ->
    { keyCode } = e
    { webcat_search_type, webcat_search_name, webcat_search_conditions }= localStorage
    if keyCode == 13
      webcat_search_string = $('#web-cat-search .search-box').val()
      if webcat_search_string == ''
       refresh_localStorage()
      else
        localStorage.webcat_search_type = 'contains'
        localStorage.webcat_search_name = ''
        localStorage.webcat_search_conditions = JSON.stringify({value:search_string})
      refresh_url()

  window.set_webcat_advanced = () ->
    # creating form object from array made from advanced dropdown form
    form = {
      tags: tag_input[0].selectize.items.join()
    }

    for item in $('#cat_named_search').serializeArray()
      { name, value } = item
      name = name.toLowerCase().replace(/-/g, '_')
      if name != 'tags'
        form[name] = value

    localStorage.webcat_search_type = 'advanced'
    localStorage.webcat_search_name = form.search_name
    localStorage.webcat_search_conditions = JSON.stringify(
      status: form.status
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

    refresh_url()

  window.webcat_refresh = ()->
    refresh_localStorage()
    refresh_url()

  window.build_named_search = (search_name) ->
    localStorage.webcat_search_type = 'named'
    localStorage.webcat_search_name = search_name
    localStorage.removeItem('webcat_search_conditions')

    refresh_url()

  build_data = () ->
    { webcat_search_type, webcat_search_name, webcat_search_conditions } = localStorage
    { search } = location

    if search != ''
      webcat_search_type = 'standard'

    switch(webcat_search_type)
      when 'advanced'
        data = {
          webcat_search_type: webcat_search_type
          webcat_search_name : webcat_search_name
          webcat_search_conditions: JSON.parse(webcat_search_conditions)
        }
      when 'contains'
        data = {
          webcat_search_type: webcat_search_type
          webcat_search_conditions: JSON.parse(webcat_search_conditions)
        }
      when 'standard'
        data = {
          webcat_search_type: webcat_search_type
          webcat_search_name: search.replace('?f=', '')
        }
      when 'named'
        data = {
          webcat_search_type: webcat_search_type
          webcat_search_name: search.replace('?f=', '')
        }
    build_header(data)
    return data

  refresh_url = (href) ->
    { webcat_search_type, webcat_search_name } = localStorage
    url_check = current_url.split('/escalations/file_rep/disputes/')[0]
    new_url = '/escalations/file_rep/disputes'
    if href != undefined
      window.location.replace(new_url + href)
    if !href && typeof parseInt(url_check) == 'number'
      window.location.replace('/escalations/webcat/complaints')

  refresh_localStorage = () ->
    localStorage.removeItem('webcat_search_type')
    localStorage.removeItem('webcat_search_name')
    localStorage.removeItem('webcat_search_conditions')

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

  window.webcat_refresh = ()->
    refresh_localStorage()
    refresh_url()

  build_header = (data) ->
    container = $('#webcat_searchref_container')
    if data != undefined && container.length > 0
      reset_icon = '<span id="refresh-filter-button" class="reset-filter esc-tooltipped" title="Clear Search Results" onclick="webcat_refresh()"></span>'
      {webcat_search_type, webcat_search_name} = data

      if webcat_search_type == 'standard'
        new_header =
          '<div>' +
            '<span class="text-capitalize">' + webcat_search_name.replace(/_/g, " ") + ' tickets </span>' +
            reset_icon +
            '</div>'

      else if webcat_search_type == 'advanced'
        search_condition_tooltip = []
        webcat_search_conditions = JSON.parse(localStorage.webcat_search_conditions)
        new_header =
          '<div>Results for Advanced Search ' +
            reset_icon +
            '</div>'

        for condition_name, condition of webcat_search_conditions
          if condition != ''
            condition_name = condition_name.replace(/_/g, " ").toUpperCase()
            condition_name_HTML = '<span class="search-condition-name text-uppercase">' + condition_name + ': </span>'

            if typeof condition == 'object'
              condition_HTML = '<span>' + condition.from  + ' - ' + condition.to+ '</span>'
            else
              condition_HTML = '<span>' + condition + '</span>'

            search_condition_tooltip.push(condition_name + ': ' + $(condition_HTML).text())
            container.append('<span class="search-condition">' + condition_name_HTML + condition_HTML + '</span>')

        if search_condition_tooltip.length > 0
          container.css('display', 'inline-block')
          container.addClass('esc-tooltipped')
          list = document.createElement('ul')
          $(list).addClass('tooltip_content')
          for  li in search_condition_tooltip
            item = document.createElement('li')
            item.appendChild(document.createTextNode(li))
            list.appendChild(item)
          container.prepend(list)
          $(list).hide()
          container.attr('data-tooltip-content', '.tooltip_content')

      else if webcat_search_type == 'named'

        new_header =
          '<div>Results for "' + webcat_search_name + '" Saved Search' +
            reset_icon +
            '</div>'

      else if webcat_search_type == 'contains'
        webcat_search_conditions = JSON.parse(localStorage.webcat_search_conditions)
        new_header =
          '<div>Results for "' + webcat_search_conditions.value + '" '+
            reset_icon +
            '</div>'
      else
        new_header = 'All File Reputation Tickets'
      $('#webcat-index-title')[0].innerHTML = new_header

  build_complaints_table = () ->
        complaint_table = $('#complaints-index').DataTable(
          processing: true
          serverSide: true
          ajax:
            url: url
            data: build_data()
          drawCallback: ( settings ) ->
            if localStorage.webcat_search_name
              {webcat_search_type, webcat_search_name, webcat_search_conditions } = localStorage
              last_tr = $('.webcat-named-search-list .saved-search').last().text()
              ### check variables below
                  text_check makes sure that the last table row doesn't match the named search being saved now
                  search_name_check makes sure that the search is being saved as a named search
                  Not super complicated, but that if statement was looking gross and confusing
              ###
              text_check = last_tr.trim() != webcat_search_name.trim()
              search_name_check = webcat_search_name != ''
              if webcat_search_type == 'advanced' && search_name_check && text_check
                ###
                  creating temporary tr for the filter dropdown
                  attributes added then onclick events
                ###
                new_tr = document.createElement('tr')
                new_td = document.createElement('td')
                new_link =  document.createElement('a')
                new_delete_image = document.createElement('img')
                new_delete = document.createElement('a')

                $(new_tr).attr('id','temp_row')
                $(new_link).addClass('input-truncate saved-search esc-tooltipped')
                  .attr('title', webcat_search_name)
                  .text(webcat_search_name)
                $(new_delete).addClass("delete-search")
                $(new_delete_image).addClass('delete-search-image')

                $(new_link).on 'click', () ->
                  window.build_named_search(webcat_search_name)
                $(new_delete).on 'click', () ->
                  window.delete_disputes_named_search(this,  webcat_search_name)
                  refresh_localStorage()
                $(new_tr).append(new_td)
                $(new_td).append(new_link)
                $(new_td).append(new_delete)
                $(new_delete).append(new_delete_image)
                $('.webcat-named-search-list').append(new_tr)

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
            { is_important, was_dismissed } = data
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

    tag_input = $('#tags-input').selectize {
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

