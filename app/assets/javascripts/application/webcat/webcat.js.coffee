window.display_tooltip = (id)->
  $('#cat_tooltip_' + id).tooltip('toggle')

window.td_truncate = (str, max, long) ->
  long = long or '...'
  if typeof str == 'string' and str.length > max then str.substring(0, max) + long else str

window.def_includes = (check, str) ->
  return check.indexOf(str) != -1

window.timeMatch = (age)->
  time = 'exceeds time'
  if !def_includes(age, 'months')
    if def_includes(age, 'm') && def_includes(age, 's')
      time = 'minutes'
    else if def_includes(age, 'h') && def_includes(age, 'm')
      time =  'hours'
  return time

window.wbrs_display = (score) ->
  score = parseFloat(score)
  if score == NaN
    return 'unknown'
  else if  score <= -6
    return 'untrusted'
  else if score <= -3
    return 'questionable'
  else if score <= 0
    return 'neutral'
  else if score < 6
    return 'favorable'
  else if score >= 6
    return 'trusted'
$ ->

  # webcat: have top navigation bar scroll with page per user request
  if $('body').hasClass("escalations--webcat--complaints-controller")
    $('#nav-banner').addClass('fixed-nav')

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
        localStorage.webcat_search_conditions = JSON.stringify({value:webcat_search_string})
      refresh_url()

  $('#filter-cases-list a').on 'click', (e)->
    localStorage.setItem('webcat_reset_page', true)
  window.set_webcat_advanced = () ->
    # creating form object from array made from advanced dropdown form
    form = {}
    user_id = assignee_input[0].selectize.items
    tags = tag_input[0].selectize.items
    company = $('#company-input')[0].selectize.items
    status = $('#status-input')[0].selectize.items
    resolution = $('#resolution-input')[0].selectize.items
    customer_name = $('#name-input')[0].selectize.items
    { items, options } = category_input[0].selectize
    complaints = $('#complaint-input')[0].selectize.items
    channels = $('#channel-input')[0].selectize.items
    entry_ids = $('#entryid-input')[0].selectize.items
    complaint_ids = $('#complaintid-input')[0].selectize.items

    if tags.length
      form['tags'] = tags.join(', ')
    if items.length
      form['category'] = items.map( (cat) -> options[cat].category_name).join(', ')
    if company.length
      form['company'] = company.join(', ')
    if status.length
      form['status'] = status.join(', ')
    if resolution.length
      form['resolution'] = resolution.join(', ')
    if customer_name.length
      form['customer_name'] = customer_name.join(', ')
    if complaints.length
      form['ip_or_uri'] = complaints.join(', ')
    if channels.length
      form['channel'] = channels.join(', ')
    if entry_ids.length
      form['entry_id'] = entry_ids.join(', ')
    if complaint_ids.length
      form['complaint_id'] = complaint_ids.join(', ')
    if user_id.length
      form['user_id'] = user_id.join(', ')

    for item in $('#cat_named_search :input:not(:hidden)').serializeArray()
      { name, value } = item
      name = name.toLowerCase().replace(/-/g, '_')
      if name != 'tags' && name != 'category'&&  name != 'companies'
        form[name] = value

    localStorage.webcat_search_type = 'advanced'
    localStorage.webcat_search_name = form.search_name
    localStorage.webcat_search_conditions = JSON.stringify(
      status: form.status
      complaint_id: form.complaint_id
      id: form.entry_id
      ip_or_uri: form.ip_or_uri
      resolution: form.resolution
      channel: form.channel
      category: form.category
      customer_name: form.customer_name
      customer_email: form.customer_email
      company_name: form.company
      domain: form.domain
      tags: form.tags
      user_id: form.user_id
      submitted_older: form.date_submitted_older
      submitted_newer: form.date_submitted_newer
      modified_older: form.date_modified_newer
      modified_newer: form.date_modified_older
    )

    refresh_url()

  window.webcat_refresh = ()->
    refresh_localStorage()
    refresh_url()

  window.build_webcat_named_search = (search_name) ->
    link_el = $('.saved-search:contains(' + search_name + ')').closest('tr').attr('id')
    localStorage.webcat_search_type = 'named'
    localStorage.webcat_search_name = search_name
    localStorage.webcat_search_conditions = '#' + link_el

    refresh_url()

  build_data = () ->
    ###
    # This function builds the argument to get data from the backend for DataTables
    # Depending on the search type and arguments
    # build_header is called at the bottom of this function to format the search header
    ###
    { webcat_search_type, webcat_search_name, webcat_search_conditions } = localStorage
    { search } = location
    if search != ''
      webcat_search_type = 'standard'
      urlParams = new URLSearchParams(location.search);
    switch(webcat_search_type)
      when 'advanced'
        data = {
          search_type: webcat_search_type
          search_name : webcat_search_name
          search_conditions: JSON.parse(webcat_search_conditions)
        }
      when 'contains'
        data = {
          search_type: webcat_search_type
          search_conditions: JSON.parse(webcat_search_conditions)
        }
      when 'standard'
        urlParams = new URLSearchParams(location.search);
        data = {
          search_type: webcat_search_type
          search_name: urlParams.get('f')
        }
      when 'named'
        data = {
          search_type: webcat_search_type
          search_name: webcat_search_name
        }
    build_header(data)
    return data

  refresh_url = (href) ->
    { webcat_search_type, webcat_search_name } = localStorage
    url_check = current_url.split('/escalations/file_rep/disputes/')[0]
    new_url = '/escalations/file_rep/disputes'
    if href != undefined
      window.location.replace( new_url + href )
    if !href && typeof parseInt(url_check) == 'number'
      window.location.replace('/escalations/webcat/complaints')
      localStorage.setItem('webcat_reset_page', true)

  refresh_localStorage = () ->
    localStorage.removeItem('webcat_search_type')
    localStorage.removeItem('webcat_search_name')
    localStorage.removeItem('webcat_search_conditions')


  for select in $('select.cat_new_url')

    $(select).selectize {
      persist: false,
      create: false,
      maxItems: 5,
      closeAfterSelect: true,
      valueField: 'category_id',
      labelField: 'category_name',
      searchField: ['category_name', 'category_code'],
      options: AC.WebCat.createSelectOptions("##{select.id}")
    }

  url = $('#complaints-index').data('source')
  current_url = window.location.href
  complaint_table = ''

  window.webcat_refresh = ()->
    refresh_localStorage()
    refresh_url()

  build_subheader = (subheader) ->

    if typeof subheader == 'string'
      subheader = JSON.parse(subheader)

    container = $('#webcat_searchref_container')
    search_condition_tooltip = []
    for condition_name, condition of subheader
      if condition != ''
        if condition_name == 'id'
          condition_name = 'Entry Id'
        if condition_name == 'user_id'
          condition_name = 'Assignee'
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
      list = $(container).find('#search-tooltip_content')[0]
      for  li in search_condition_tooltip
        item = document.createElement('li')
        item.appendChild(document.createTextNode(li))
        list.appendChild(item)
      container.attr('data-tooltip-content', '#search-tooltip_content')
      container.tooltipster(
        theme: [
          'tooltipster-borderless'
          'tooltipster-borderless-customized'
        ]
        contentCloning: true
      )

  build_header = (data) ->
    ###
    # Depending on the data, this function builds the search header
    # With the search header the reset filter button is attached
    # If the search_type is 'named' or 'advanced', a subheader with search definitions will be made with the build_subheader function
    ###
    container = $('#webcat_searchref_container')
    if data != undefined && container.length > 0
      reset_icon = '<span id="refresh-filter-button" class="reset-filter esc-tooltipped" title="Clear Search Results" onclick="webcat_refresh()"></span>'
      {search_type, search_name} = data

      if search_type == 'standard'

        search_name = search_name.toLowerCase().replace('complaints', 'tickets')

        if !search_name.endsWith('tickets')
          search_name += ' tickets'

        new_header =
          '<div>' +
            '<span class="text-capitalize">' + search_name.replace(/_|%20/g, " ") + ' </span>' +
            reset_icon +
            '</div>'

      else if search_type == 'advanced'

        webcat_search_conditions = JSON.parse(localStorage.webcat_search_conditions)
        new_header =
          '<div>Results for Advanced Search ' +
            reset_icon +
            '</div>'
        build_subheader(webcat_search_conditions)

      else if search_type == 'named'
        new_header =
          '<div>Results for "' + search_name + '" Saved Search' +
            reset_icon +
            '</div>'
        el = localStorage.webcat_search_conditions
        if !el.includes('temp_row')
          subheader = $(el + ' .saved-search')[0].dataset.search_conditions
        else
          subheader = $('#saved-search-tbody').last('tr').find('.saved-search').attr('data-search_conditions')
        build_subheader(subheader)

      else if search_type == 'contains'
        webcat_search_conditions = JSON.parse(localStorage.webcat_search_conditions)
        new_header =
          '<div>Results for "' + webcat_search_conditions.value + '" '+
            reset_icon +
          '</div>'
      else
        new_header = 'All Tickets'
      $('#webcat-index-title')[0].innerHTML = new_header
    else
      $('#webcat-index-title')[0].innerHTML = 'All Tickets'

  build_complaints_table = () ->
        complaint_table = $('#complaints-index').DataTable(
          initComplete: ->
            input = $('.dataTables_filter input').unbind()
            self = @api()

            $searchButton = $('<button class="dt-button dt-search-button esc-tooltipped" title="Search">').click(->
              self.search(input.val()).draw()
              return
            )
            $clearButton = $('<button class="dt-button dt-search-clear-button esc-tooltipped" title="Clear">').click(->
              input.val ''
              $searchButton.click()
              return
            )
            $('.dataTables_filter').append $clearButton, $searchButton

            # properly init these search/clear icons
            $('.dt-button').tooltipster
              theme: [
                'tooltipster-borderless'
                'tooltipster-borderless-customized'
                'tooltipster-borderless-comment'
              ]

            return
          lengthMenu: [[25, 50, 100, 150, 200], [25, 50, 100, 150, 200]]
          processing: true
          serverSide: true
          stateSave: true
          select: true
          ajax:
            url: url
            data: build_data()
            error: () ->
              ###
                If there is an error with the build_data call, the localstorage and url will be blown away
                This will reset the search and filters
              ###
              refresh_localStorage()
              refresh_url()
          drawCallback: ( settings ) ->
            if localStorage.webcat_reset_page
              localStorage.removeItem('webcat_reset_page')

              setTimeout () ->
                $('#complaints-index').DataTable().page(0).draw( true )
              , 100

            if localStorage.webcat_search_name
              { webcat_search_type, webcat_search_name, webcat_search_conditions } = localStorage
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
                  window.build_webcat_named_search(webcat_search_name)

                $(new_delete).on 'click', () ->
                  window.delete_disputes_named_search(this,  webcat_search_name)
                  refresh_localStorage()

                $(new_tr).append(new_td)
                $(new_td).append(new_link)
                $(new_td).append(new_delete)
                $(new_delete).append(new_delete_image)
                $('.webcat-named-search-list tbody').append(new_tr)

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
              searchable: false
              orderable: false
            }
            {
              targets: [1]
              className: 'important-flag-col'
              searchable: false
              orderable: false
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
                  if is_important == "true" && was_dismissed == "true"
                      return '<div class="container-important-tags ">' +
                        '<div class="esc-tooltipped is-important highlight-second-review" tooltip title="Important"></div>' +
                        '<div class="esc-tooltipped was-reviewed highlight-was-dismissed" tooltip title="Reviewed"></div>' +
                        '</div>'
                  else if is_important == "true" && was_dismissed == "false"
                    return '<span class="esc-tooltipped is-important highlight-second-review" tooltip title="Important"></span>'
                  else if is_important == "false" && was_dismissed == "true"
                    return '<span class="esc-tooltipped was-reviewed highlight-was-dismissed" tooltip title="Reviewed"></span>'
              }
              {
                data: 'entry_id'
                width: '50px'
              }
              {
#               age column
                width: '40px'
                render: ( data, type, full, meta) ->
                  { age } = full
                  time = timeMatch(age)
                  switch ( time )
                    when 'minutes'
                      age_class = ''
                    when 'hours'
                      hour = parseInt( age.split("h")[0] )
                      if hour >= 3 && hour < 12
                        age_class = 'ticket-age-over3hr'
                      else if hour > 12
                        age_class = 'ticket-age-over12hr'
                    when 'exceeds time'
                      age_class = 'ticket-age-over12hr'
                  return "<span class='#{age_class}'>#{age}</span>"
              }
              {
                data: 'status'
                className: 'state-col'
              }
              {
                data: 'tags'
                render: ( data )->

                  tag_items = '<span class="missing-data">No tags</span>'

                  if data && typeof data == 'string'
                    tags = data.substring( 1, data.length-1 ).replace(/&quot;/g,'');
                    tag_list = tags.split(',').map ( tag ) -> return tag.trim();

                    if tag_list.length >= 1
                      tag_items = ''
                      tag_list = tag_list.filter ( tag, index )-> return tag_list.indexOf( tag ) == index && tag != ''
                      for tag in tag_list
                        item = '<span class="tag-capsule">' + tag + '</span>'
                        tag_items += item

                  tag_items
              }
              {
#                subdomain column
                data: 'subdomain'
                render:(data,type,full,meta)->
                  {subdomain, entry_id} = full

                  if subdomain
                    '<span id="subdomain_' + entry_id + '" class="webcat-subdomain-holder">' + subdomain + '</span>'
                  else
                    '<span id="subdomain_' + entry_id + '" class="webcat-subdomain-holder">' + '</span>'
                width: '50px'
              }
              {
                data: 'domain'
                render:( data, type, full, meta )->
                  { domain, ip_address, entry_id, subdomain, path } = full
                  data_full = ''
                  if subdomain != ''
                    subdomain += '.'
                    data_full = subdomain
                  if domain != ''
                    data_full += domain
                  if path != ''
                    data_full += path
                  if ip_address != ''
                    data_full = ip_address
                  if data_full != ''
                    data_full = "data-full=" + data_full
                  title = "title=" + domain
                  if domain
                    "<p class='input-truncate esc-tooltipped webcat-domain-holder' #{data_full} id='domain_#{entry_id}' #{title}>#{domain}</p>"
                  else
                    "<a id='domain_#{entry_id}' #{data_full} href='http://#{ip_address}' target='blank'>#{ip_address}</a>"
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
                data: 'suggested_disposition'
                render: ( data, type, full, meta ) ->
                  return data.replace(',', ', ')
              }
              {
                data: 'wbrs_score'
                width: '55px'
                render: ( data, type, full, meta ) ->
                  { wbrs_score, entry_id } = full
                  rep = wbrs_display(wbrs_score)
                  wbrs_score = parseFloat(wbrs_score).toFixed(1)
                  if rep == undefined then rep = 'unknown'
                  if rep == 'unknown' then wbrs_score = '--'
                  tooltip_rep = rep.toUpperCase()
                  icon = "<span class='reputation-icon icon-#{rep} esc-tooltipped' title='#{tooltip_rep}'></span>"
                  return "<div class='reputation-icon-container'>#{icon}<span id='wbrs_score_#{entry_id}'>#{wbrs_score}</span>"
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
                className: 'assignee-col'
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

    # Make the search prettier
    $('#complaints-index_filter input').addClass('restricted-table-search-input');

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


    $('#complaints-index tbody').on 'click', 'td.expandable-row-column', ->
      click_table_buttons complaint_table, this

    createSelectOptions = ->
      tags = $('#search_tag_list')[0]
      if tags
        tag_list = tags.value
        array = tag_list.split(',')
        options = []
        for x in array
          options.push {name: x}
        return options

    assignee_input = $('#assignee-input').selectize {
      persist: false
      create: false
      valueField: 'name',
      labelField: 'display_name',
      searchField: ['name', 'display_name'],
      options: AC.WebCat.createAssigneeOptions()
      render:
        option: (item, escape) ->
          name = item.display_name
          user_id = item.name
          '<div class="custom-render-selectize"><span>' + escape(name) + ' (' + escape(user_id) + ')' + '</span></div>'
      onFocus: () ->
        window.toggle_selectize_layer(this, 'true')
      onBlur: () ->
        window.toggle_selectize_layer(this, 'false')
    }
    tag_input = $('#tags-input').selectize {
      persist: false
      create: false
      valueField: 'name',
      labelField: 'name',
      options: createSelectOptions()
      onFocus: () ->
        window.toggle_selectize_layer(this, 'true')
      onBlur: () ->
        window.toggle_selectize_layer(this, 'false')
    }
    category_input = $('#category-input').selectize {
      persist: false,
      create: false,
      maxItems: 5,
      valueField: 'category_id',
      labelField: 'category_name',
      searchField: ['category_name', 'category_code'],
      options: AC.WebCat.createSelectOptions('#category-input')
      onFocus: () ->
        window.toggle_selectize_layer(this, 'true')
      onBlur: () ->
        window.toggle_selectize_layer(this, 'false')
    }
    company_input = $('#company-input').selectize {
      persist: false,
      create: false,
      valueField: 'company_name',
      labelField: 'company_name',
      searchField: 'company_name',
      onFocus: () ->
        window.toggle_selectize_layer(this, 'true')
      onBlur: () ->
        window.toggle_selectize_layer(this, 'false')
    }
    status_input = $('#status-input').selectize {
      persist: false,
      create: false,
      maxItems: 6,
      valueField: 'name',
      labelField: 'name',
      searchField: 'name',
      options: [{name: "NEW"}, {name: "RESOLVED"}, {name: "ASSIGNED"}, {name: "ACTIVE"},
               {name: "COMPLETED"}, {name: "PENDING"}, {name: "REOPENED"}]
      onFocus: () ->
        window.toggle_selectize_layer(this, 'true')
      onBlur: () ->
        window.toggle_selectize_layer(this, 'false')
    }
    resolution_input = $('#resolution-input').selectize {
      persist: false,
      create: false,
      maxItems: 3,
      valueField: 'name',
      labelField: 'name',
      searchField: 'name',
      options: [{name: "FIXED"}, {name: "INVALID"}, {name: "UNCHANGED"}, {name: "DUPLICATE"}]
      onFocus: () ->
        window.toggle_selectize_layer(this, 'true')
      onBlur: () ->
        window.toggle_selectize_layer(this, 'false')
    }
    customer_input = $('#name-input').selectize {
      persist: false,
      create: false,
      valueField: 'name',
      labelField: 'name',
      searchField: 'name',
      onFocus: () ->
        window.toggle_selectize_layer(this, 'true')
      onBlur: () ->
        window.toggle_selectize_layer(this, 'false')
    }
    complaint_input = $('#complaint-input').selectize {
      persist: false,
      create: (input) ->
        {
          value: input
          text: input
        }
      onFocus: () ->
        window.toggle_selectize_layer(this, 'true')
      onBlur: () ->
        window.toggle_selectize_layer(this, 'false')
    }
    channel_input = $('#channel-input').selectize {
      persist: false,
      create: false,
      maxItems: 2,
      valueField: 'name',
      labelField: 'name',
      searchField: 'name',
      options: [{name: "Internal"}, {name: "TalosIntel"}, {name: "WBNP"}]
      onFocus: () ->
        window.toggle_selectize_layer(this, 'true')
      onBlur: () ->
        window.toggle_selectize_layer(this, 'false')
    }
    entry_ids = $('#entryid-input').selectize {
      delimiter: ',',
      persist: false,
      create: (input) ->
        {
          value: input
          text: input
        }
      onFocus: () ->
        window.toggle_selectize_layer(this, 'true')
      onBlur: () ->
        window.toggle_selectize_layer(this, 'false')
    }
    complaint_ids = $('#complaintid-input').selectize {
      delimiter: ',',
      persist: false,
      create: (input) ->
        {
          value: input
          text: input
        }
      onFocus: () ->
        window.toggle_selectize_layer(this, 'true')
      onBlur: () ->
        window.toggle_selectize_layer(this, 'false')
    }


    window.clearSelectize = (input) ->
      $("##{input}")[0].selectize.clear()

$('#exampleModal').on 'shown.bs.modal', ->
  $('button.toolbar-button.cat-btn').addClass('active')


$ ->

  $('.toggle-vis-webcat').each ->
    table = $('#complaints-index').DataTable()
    column = table.column($(this).attr('data-column'))
    checkbox = $(this).find('input')

    if $(checkbox).prop('checked')
      column.visible(true)
    else
      column.visible(false)

    $(this).click (e) ->
      $(checkbox).prop('checked', !checkbox.prop('checked'))
      column.visible(!column.visible())

    $(checkbox).click (e) ->
      $(checkbox).prop('checked', !checkbox.prop('checked'))


  # webcat > get the show/hide state for these checkboxes
  if window.location.pathname == '/escalations/webcat/complaints'
    std_msg_ajax(
      method: 'POST'
      url: "/escalations/api/v1/escalations/user_preferences/"
      data: {name: 'WebCatColumns'}
      success: (response) ->
        response = JSON.parse(response)

        $.each response, (column, state) ->
          if state == true
            $("##{column}-checkbox").prop('checked', true)
            $('#complaints-index').DataTable().column("##{column}").visible true
          else
            $("##{column}-checkbox").prop('checked', false)
            $('#complaints-index').DataTable().column("##{column}").visible false

    )

  # webcat > on click any show/hide column, update user prefs table
  $('.toggle-vis-webcat').on "click", ->
    data = {}
    ## retain commented line below
    # data['important'] = $("#important-checkbox").is(':checked')
    data['age'] = $("#age-checkbox").is(':checked')
    data['status'] = $("#status-checkbox").is(':checked')
    data['tags'] = $("#tags-checkbox").is(':checked')
    data['subdomain'] = $("#subdomain-checkbox").is(':checked')
    data['domain'] = $("#domain-checkbox").is(':checked')
    data['path'] = $("#path-checkbox").is(':checked')
    data['primary'] = $("#primary-checkbox").is(':checked')
    data['suggested'] = $("#suggested-checkbox").is(':checked')
    data['wbrs'] = $("#wbrs-checkbox").is(':checked')
    data['submittertype'] = $("#submittertype-checkbox").is(':checked')
    data['submitterorg'] = $("#submitterorg-checkbox").is(':checked')
    data['assignee'] = $("#assignee-checkbox").is(':checked')

    std_msg_ajax(
      url: "/escalations/api/v1/escalations/user_preferences/update"
      method: 'POST'
      data: {data, name: 'WebCatColumns'}
      dataType: 'json'
      success: (response) ->
        console.log 'Webcat column show/hide preferences are updated in user_prefs table.'
    )

  # webcat > complaints show page, disable two Submit toolbar buttons on page load
  if $('body').hasClass('escalations--webcat--complaints-controller')
    $('#master-submit, #index_update_resolution').prop('disabled','disabled')

  # webcat > complaints show page, ensure this JS gets called
  if $('body').hasClass('escalations--webcat--complaints-controller') && $('body').hasClass('show-action')
    check_wbnp_status()

  # webcat > reports page, show full metrics banner at top, not the streamlined one
  if $('body').hasClass("escalations--webcat--reports-controller")
    $('#tooltip-wbnp').empty()
    $('.complaints-metrics-banner').addClass('hidden')
    $('.webcat-reports-only').removeClass('hidden')

  # wbnp report status link shows a tooltip table
  $('.complaints-mgt-area #wbnp-report-status-link').tooltipster
    theme: [
      'tooltipster-borderless'
      'tooltipster-borderless-customized'
    ]
    contentCloning: true
    side: 'bottom'
    trigger: 'hover'


# Prevent the many selectizes from running into each other
window.toggle_selectize_layer = (input, focus) ->
  input = input.$control_input[0]
  select_parent = $(input).parents('.form-control')[0]
  if focus == 'true'
    $(select_parent).css('z-index', '4')
  else
    $(select_parent).css('z-index', '2')

window.copyToClipboard = (text) ->
  dummy = document.createElement('input')
  document.body.appendChild dummy
  dummy.setAttribute 'value', text
  dummy.select()
  document.execCommand 'copy'
  document.body.removeChild dummy

$ ->
  # tooltip init these icons inside this DT, this MUST be on 'draw.dt', not page-load, DT doesn't exist on page-load
  $('#complaints-index').on 'draw.dt', ->
    $('#complaints-index .tooltipstered').tooltipster('destroy')  # remove existing dt tt attachments, then restore title attr
    $('#complaints-index .esc-tooltipped').tooltipster
      restoration: 'previous'
      theme: [
        'tooltipster-borderless'
        'tooltipster-borderless-customized'
      ]

  # one-off init for 'clear search results' icon
  $('#webcat-index-title #refresh-filter-button').tooltipster
    theme: [
      'tooltipster-borderless'
      'tooltipster-borderless-customized'
    ]
