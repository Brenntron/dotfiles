# determines the proper icon to display next to the score
# TODO - there is probably a better place to put this
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


# clear out 'touched' entries
window.clear_stored_entries = () ->
  sessionStorage.getItem("webcat_entries_changed") || ""
  sessionStorage.setItem("webcat_entries_changed", "")
  sessionStorage.getItem("webcat_entries_reviewed") || ""
  sessionStorage.setItem("webcat_entries_reviewed", "")


$ ->
  clear_stored_entries()


  # webcat: have top navigation bar scroll with page per user request
  if $('body').hasClass("escalations--webcat--complaints-controller") && $('body').hasClass("index-action")
    $('#nav-banner').addClass('fixed-nav')

    #pin webcat toolbar under navigation bar, add padding
    toolbar = $('#webcat-index-toolbar')
    $('#nav-banner').append(toolbar)
    $('.escalations--webcat--complaints-controller.index-action #page-content-wrapper').css('padding-top','60px')

    #align tooltips under toolbar
    $('body').addClass('pinned-toolbar-true')

  $('#web-cat-search #general_search').on 'keyup', (e) ->
    { keyCode } = e
    { webcat_search_type, webcat_search_name, webcat_search_conditions }= localStorage
    if keyCode == 13
      webcat_search_string = $('#web-cat-search .search-box').val().trim()
      if webcat_search_string == ''
        refresh_webcat_localStorage()
      else
        localStorage.webcat_search_type = 'contains'
        localStorage.webcat_search_name = ''
        localStorage.webcat_search_conditions = JSON.stringify({value:webcat_search_string})
      $('#complaints-index').DataTable().state.clear()
      refresh_url()

  $('#filter-cases-list a').on 'click', (e)->
    filter_url = $(this).attr('href')
    localStorage.setItem('webcat_reset_page', true)
    localStorage.setItem('webcat_search_type', 'standard')
    localStorage.setItem('webcat_search_name', filter_url)
    localStorage.removeItem('webcat_search_conditions')
    $('#complaints-index').DataTable().state.clear()


  window.set_webcat_advanced = () ->
    # creating form object from array made from advanced dropdown form

    form = {}
    # Get each visible search item - should either be a selectized select, or an input
    console.log $('#cat_named_search .search-item:not(:hidden)').length

    form['search_name'] = $('#cat_named_search input[name="search_name"]').val()

    $('#cat_named_search .search-item:not(:hidden)').each ->
      # selectized values will be arrays that need to be joined
      if $(this).find('select')[0]
        select = $(this).find('select')[0]
        search_item = $(select).attr('name')
        search_item_val = $(select).val()
        if search_item_val?
          # need both ids and names for categories and platforms
          if search_item == 'category-input' || search_item == 'platform'
            options = []
            selected_options = $(select).find('option:selected')
            $(selected_options).each ->
              options.push(this.innerText)
            if search_item == 'category-input'
              form['category'] = options.join(', ')
              form['category_ids'] = search_item_val.join(', ')
            if search_item == 'platform'
              form['platform_display'] = options.join(', ')
              form['platform_ids'] = search_item_val.join(', ')
          else
            search_item_val = search_item_val.join(', ')
      else
        input = $(this).find('input')
        search_item = $(input).attr('name')
        search_item_val = $(input).val()

      if search_item_val? && search_item_val != '' && search_item != 'category-input' && search_item != 'platform'
        form[search_item] = search_item_val

    localStorage.webcat_search_type = 'advanced'
    localStorage.webcat_search_name = form.search_name
    localStorage.webcat_search_conditions = JSON.stringify(form)
    $('#complaints-index').DataTable().state.clear()
    refresh_url()



  window.build_webcat_named_search = (search_name) ->
    localStorage.webcat_search_type = 'named'
    localStorage.webcat_search_name  = search_name
    localStorage.webcat_search_conditions = $('.saved-search:contains(' + search_name + ')').closest('tr').attr('id')
    $('#complaints-index').DataTable().state.clear()
    refresh_url()


  window.search_for_tag = (tag) ->
    { webcat_search_type, webcat_search_name, webcat_search_conditions } = localStorage
    try
      webcat_search_conditions = JSON.parse webcat_search_conditions
    catch e
      webcat_search_conditions = {}

    localStorage.webcat_search_type = 'advanced'
    webcat_search_conditions.tags = tag

    localStorage.webcat_search_conditions = JSON.stringify webcat_search_conditions
    $('#complaints-index').DataTable().state.clear()
    refresh_url()



  current_url = window.location.href

  # This is used when there is an error calling the data
  # or when clearing the search to the default data (favorite filter if set by user)
  window.webcat_refresh = ()->
    refresh_webcat_localStorage()
    refresh_url()


  refresh_url = (href) ->
    { webcat_search_type, webcat_search_name } = localStorage
    url_check = current_url.split('/escalations/webcat/complaints/')[0]
    new_url = '/escalations/webcat/complaints'
    if href != undefined
      window.location.replace( new_url + href )
    if !href && typeof parseInt(url_check) == 'number'
      window.location.replace('/escalations/webcat/complaints')
      localStorage.setItem('webcat_reset_page', true)

  window.refresh_webcat_localStorage = () ->
    localStorage.removeItem('webcat_search_type')
    localStorage.removeItem('webcat_search_name')
    localStorage.removeItem('webcat_search_conditions')
    $('#complaints-index').DataTable().state.clear()



  $('#filter-dropdown').on 'click', '.favorite-search-icon', () ->
    name = $(this).parent().find('a').attr('href') || $(this).parent().find('a').text().trim()
    data = { name: name }
    icon = $(this)

    std_msg_ajax(
      url: '/escalations/api/v1/escalations/user_preferences/update'
      method: 'POST'
      data: { data, name: 'webcat_complaints_filter' }
      dataType: 'json'
      success: (response) ->
        $('.favorite-search-icon-active').removeClass('favorite-search-icon-active').addClass('favorite-search-icon')
        icon.removeClass('favorite-search-icon').addClass('favorite-search-icon-active')
    )

  $('#filter-dropdown').on 'click', '.favorite-search-icon-active', () ->
    icon = $(this)
    std_msg_ajax(
      url: '/escalations/api/v1/escalations/user_preferences/destroy'
      method: 'DELETE'
      data: { name: 'webcat_complaints_filter' }
      dataType: 'json'
      success: (response) ->
        icon.removeClass('favorite-search-icon-active').addClass('favorite-search-icon')
    )


  window.use_user_preference_filter = () ->
    return if window.location.pathname != '/escalations/webcat/complaints'

    { icon, link, name } = chosen_default_filter()

    return if icon.length == 0 && link.length == 0

    # do not redirect if there is already some chosen search/filter (not from the settings)
    return if localStorage.webcat_search_type || window.location.search

    refresh_webcat_localStorage()
    if is_default_filter(icon) then refresh_url(name) else build_webcat_named_search(name);


  is_default_filter = (chosen_icon) ->
    chosen_icon.closest('#filter-dropdown > #filter-cases-list').length > 0

  chosen_default_filter = ->
    fav_icon = $('.favorite-search-icon-active')
    link = fav_icon.parent().find('a')
    name = if is_default_filter(fav_icon) then link.attr('href') else link.text().trim()
    { icon: fav_icon, link: link, name: name }

  window.current_page_is_favourite = (search_name) ->
    { icon, name } = chosen_default_filter()
    if is_default_filter(icon)
      filter_dropdown = $("#filter-cases-list > span.favorite-search-icon-active")
      if filter_dropdown
        #Check if filter link matches current url path
        if name == decodeURIComponent(window.location.search)
          return true
        #If no url path check if active link matches current filter name
        else
          link_text = $("#filter-dropdown > #filter-cases-list a.active-link").text().trim().toLowerCase()
          if link_text == search_name
            return true

    #check if on current saved search
    if name == localStorage.webcat_search_name
      return true

    #catch for when no favorites are set - currently loads All Tickets page, will need to be adjusted if that changes
    else if $('.favorite-search-icon-active').length == 0 && search_name == 'all tickets'
      return true

    #check if saved search favorite is set but there's no local storage saved
    else
      saved_search_dropdown = $("#saved-searches-wrapper > span.favorite-search-icon-active")
      if saved_search_dropdown.length > 0
        saved_name = $('#saved-searches-wrapper .active-link').text().trim()
        if search_name == saved_name
          return true





  if $('#complaints-index').length


    ## WEBCAT ADVANCED SEARCH FUNCTIONS

    ## Note - this function is not currently used,
    # it's for Adv searching tags
    createSelectOptions = ->
      tags = $('#search_tag_list')[0]

      if tags
        tag_list = tags.value
        tag_array = tag_list.split(',')
        options = []

        for tag in tag_array
          options.push {name: tag}

        return options

    assignee_input = $('#assignee-input').selectize {
      persist: true
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
      valueField: 'name',
      labelField: 'name',
      searchField: 'name',
      options: createSelectOptions()
      onFocus: () ->
        window.toggle_selectize_layer(this, 'true')
      onBlur: () ->
        if this.lastQuery != ""
          this.addItem([this.lastQuery])
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
    $('#company-input').selectize {
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
    $('#status-input').selectize {
      persist: false,
      create: false,
      maxItems: 6,
      valueField: 'name',
      labelField: 'name',
      searchField: 'name',
      options: [{name: "NEW"}, {name: "RESOLVED"}, {name: "ASSIGNED"},
               {name: "COMPLETED"}, {name: "PENDING"}, {name: "REOPENED"}]
      onFocus: () ->
        window.toggle_selectize_layer(this, 'true')
      onBlur: () ->
        window.toggle_selectize_layer(this, 'false')
    }
    $('#resolution-input').selectize {
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
    $('#name-input').selectize {
      persist: true,
      create: false,
      valueField: 'name',
      labelField: 'name',
      searchField: 'name',
      options: AC.WebCat.createCustomerNameOptions()
      onFocus: () ->
        window.toggle_selectize_layer(this, 'true')
      onBlur: () ->
        window.toggle_selectize_layer(this, 'false')
    }

    $('#complaint-input').selectize {
      persist: false,
      createOnBlur: true,
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
    $('#channel-input').selectize {
      persist: false,
      create: false,
      maxItems: 2,
      valueField: 'name',
      labelField: 'name',
      searchField: 'name',
      options: [{name: "Internal"}, {name: "TalosIntel"}, {name: "WBNP"},{name: "Jira"}, {name: "RMS"}, {name: "RMS Alert"} ]
      onFocus: () ->
        window.toggle_selectize_layer(this, 'true')
      onBlur: () ->
        window.toggle_selectize_layer(this, 'false')
    }

    $('#entryid-input').selectize {
      delimiter: ',',
      persist: false,
      createOnBlur: true,
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
    $('#complaintid-input').selectize {
      delimiter: ',',
      persist: false,
      createOnBlur: true,
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
    $('#jiraid-input').selectize {
      delimiter: ',',
      persist: false,
      createOnBlur: true,
      create: (input) ->
        {
          value: input
          text: input
        }
      onFocus: () ->
        window.toggle_selectize_layer(this, 'true')
        this.close()
      onBlur: () ->
        this.close()
        window.toggle_selectize_layer(this, 'false')
    }

    $('#platform-input').selectize {
      persist: true,
      create: false,
      valueField: 'id',
      labelField: 'public_name',
      searchField: 'public_name',
      options: AC.WebCat.createPlatformOptions()
      render:
        option: (item, escape) ->
          '<div class="custom-render-selectize"><span>' + item.public_name + '</span></div>'
      onFocus: () ->
        window.toggle_selectize_layer(this, 'true')
      onBlur: () ->
        window.toggle_selectize_layer(this, 'false')
    }

    $('#submitter-type-input').selectize {
      delimiter: ',',
      persist: false,
      valueField: 'name',
      labelField: 'name',
      searchField: 'name',
      options: [{name: "Customer"}, {name: "Guest"}]
      onFocus: () ->
        window.toggle_selectize_layer(this, 'true')
      onBlur: () ->
        window.toggle_selectize_layer(this, 'false')
    }

    window.clearSelectize = (input) ->
      $("##{input}")[0].selectize.clear()



window.get_current_cats = (rows) ->
  # Grab up-to-date list of categories ONE time for all entries
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: "/escalations/api/v1/escalations/webcat/complaints/category_list"
    method: 'GET'
    headers: headers
    success: (response) ->
      all_categories = response
      # Initialize category selectizes
      $(rows).each ->
        entry_id = $(this).attr('id')
        entry_cats = $(this).attr('data-categories')
        entry_status = $(this).attr('data-status')
        load_selectize_cats(entry_id, entry_cats, all_categories, entry_status)
        fetch_external_categories(entry_id)
  )

# Compares the categories of an entry in AC to the full list of
# AUP categories and initializes & populates that entry's selectize box
load_selectize_cats = (entry_id, entry_categories, all_categories, entry_status) ->

  cleaned_cats = []
  if entry_categories
    cleaned_cats = entry_categories.split(',')
    #splice together 'Conventions, Conferences and Trade Shows' due to extra comma
    if entry_categories.includes('Conferences and Trade Shows')
      $(cleaned_cats).each (i, category) ->
        if category == 'Conventions'
          cleaned_cats.splice(i, 1)
        else if category == ' Conferences and Trade Shows'
          i2 = i - 1
          cleaned_cats.splice(i2, 1, 'Conventions, Conferences and Trade Shows')

  cat_options = []
  for key, value of all_categories
    cat_code = key.split(' - ')[1]
    value_name = key.split(' - ')[0]
    cat_options.push({category_id: value, category_name: value_name, category_code: cat_code})

  # find the category ids that match the current cats on the entry
  category_ids = []
  for name in cleaned_cats
    for x, y of all_categories
      value_name = x.split(' - ')[0]
      if name.trim() == value_name
        category_ids.push(y)

  # adds category ids to row for fetching later
  $('#' + entry_id).attr('data-cat-ids', category_ids.join(','))

  if entry_status == 'COMPLETED'
    # need to initialize the selectize function but disable it here if entry is completed
    $completed_selectize = $('#input_cat_'+ entry_id).selectize {
      persist: true,
      create: false,
      maxItems: 5,
      closeAfterSelect: true,
      valueField: 'category_id',
      labelField: 'category_name',
      searchField: ['category_name', 'category_code'],
      options: cat_options,
      items: category_ids,
    }
    select_complete = $completed_selectize[0].selectize
    select_complete.disable()
  else
    $('#input_cat_'+ entry_id).selectize {
      persist: false,
      create: false,
      maxItems: 5,
      closeAfterSelect: true,
      valueField: 'category_id',
      labelField: 'category_name',
      searchField: ['category_name', 'category_code'],
      options: cat_options,
      items: category_ids,
      onItemAdd: ->
        # User shouldn't be able to change cats in pending, but just in case
        unless entry_status == 'PENDING'
          store_entry_changes(entry_id, 'submit')
          if verifyMasterSubmit() == true
            $('#master-submit').prop('disabled', false)
            window.prevent_close('true')
          else
            $('#master-submit').prop('disabled', true)
            window.prevent_close()
      onItemRemove: ->
        unless entry_status == 'PENDING'
          store_entry_changes(entry_id, 'submit')
          if verifyMasterSubmit() == true
            $('#master-submit').prop('disabled', false)
            window.prevent_close('true')
          else
            $('#master-submit').prop('disabled', true)
            window.prevent_close()
      score: (input) ->
        #  Adding some customization for autofill
        #  restricting on certain cats to avoid accidental categorization
        #  (replaces selectize's built-in `getScoreFunction()` with our own)
        (item) ->
          if item.category_code == 'cprn' || item.category_code == 'xpol' || item.category_code == 'xita' || item.category_code == 'xgbr' || item.category_code == 'xdeu' || item.category_code == 'piah'
            item.category_code == input ? 1 : 0
          else if item.category_name.toLowerCase().startsWith(input.toLowerCase())
            1
          else if item.category_name.toLowerCase().includes(input.toLowerCase()) || item.category_code.toLowerCase().includes(input.toLowerCase())
            0.9
          else
            0
    }


fetch_external_categories = (entry_id) ->
  std_msg_ajax(
    method: 'POST'
    url: '/escalations/api/v1/escalations/webcat/complaint_entries/retrieve_current_categories'
    data: {'id': entry_id}
    success: (response) ->
      row_id = JSON.parse(this.data).id
      { current_category_data : current_categories, master_categories, sds_category, sds_domain_category} = JSON.parse(response)

      # If there are any current categories (WBRS)
      # Put the top one in the list
      # All other cat details will be in a tooltip
      primary_cat = '<span class="missing-data">No current external categories</span>'

      if current_categories || sds_category || sds_domain_category
        tooltip_table = '<div class="current-external-cat-info">'
      else
        tooltip_table = ''

      if current_categories
        tooltip_table +=
          '<label class="tooltip-table-label">WBRS</label>' +
            '<table class="category-tooltip-table"><thead><tr>' +
            '<th>Conf</th><th>WBRS Categories</th><th>Certainty</th><th colspan="3">Feeds</th>' +
            '</tr></thead><tbody>'

        $.each current_categories, (key, value) ->
          active =  $(this).attr("is_active")
          if active == true
            { confidence, mnem: mnemonic, descr: name, category_id: cat_id, top_certainty, certainties } = this
            if certainties
              rowspan = certainties.length
            else
              rowspan=''

            tooltip_table +=
              '<tr><td rowspan="' + rowspan + '">' + value.confidence + '</td>' +
                '<td rowspan="' + rowspan + '">' + value.mnem + ' - ' + value.descr + '</td>' +
                '<td rowspan="' + rowspan + '">' + value.top_certainty + '</td>'
            if certainties
              $(certainties).each (i) ->
                { certainty:source_certainty, source_description, source_mnemonic: source_name } = this
                unless i == 0
                  tooltip_table += '<tr>'

                tooltip_table +=
                  '<td class="alt-col">' + this.certainty + '</td>' +
                    '<td class="alt-col">' + this.source_mnemonic + '</td>' +
                    '<td class="alt-col">' + this.source_description + '</td>'
            else
              tooltip_table += '<td colspan="3"></td>'

            tooltip_table += '</tr></tbody></table>'

            if key == '1.0'
              primary_cat = '<a class="esc-tooltipped tooltip-underline">' + value.mnem + ' - ' + value.descr + ' <span class="ex-category-source">WBRS</span></a>'

      else if sds_category
        primary_cat = '<a class="esc-tooltipped tooltip-underline">' + sds_category + ' <span class="ex-category-source">SDS URI</span></a>'

      else if sds_domain_category
        primary_cat = '<a class="esc-tooltipped tooltip-underline">' + sds_domain_category + ' <span class="ex-category-source">SDS Domain</span></a>'

      # build the rest of the tooltip if there is stuff from SDS
      if sds_category || sds_domain_category
        tooltip_table +=
          '<label class="tooltip-table-label">SDS</label>' +
            '<table class="category-tooltip-table"><thead><tr>' +
            '<th>SDS URI Category</th><th>SDS Domain Category</th>' +
            '</tr></thead>' +
            '<tbody><tr>'

        if sds_category
          tooltip_table += '<td>' + sds_category + '</td>'
        else
          tooltip_table += '<td></td>'
        if sds_domain_category
          tooltip_table += '<td>' + sds_domain_category + '</td>'
        else
          tooltip_table += '<td></td>'

        tooltip_table +=
          '</tr></tbody></table>'

      tooltip_table += '</div>'

      $('#current_cat_' + entry_id).html(primary_cat)
      if tooltip_table != '</div>'
        $('#current_cat_' + entry_id + ' a.esc-tooltipped').tooltipster
          content: $(tooltip_table),
          theme: [
            'tooltipster-borderless'
            'tooltipster-borderless-customized'
          ],
          minWidth: '820'

    error: (response) ->
      # maintain this for troubleshooting external api responses
      console.log response
      current_categories = ''
  )


# Sending individual entry info to the backend
process_entry = (entry_data) ->
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  std_msg_ajax(
    url: '/escalations/api/v1/escalations/webcat/complaint_entries/update'
    method: 'POST'
    headers: headers
    data: entry_data
    success: (response) ->
      data = $.parseJSON(response)
      if data.error?
        err_msg = data.error
        msg = $('#' + data.entry_id + ' .temp-msg')
        $(msg).text('Submission failed: ' + err_msg)
      else
        msg = $('#' + data.entry_id + ' .temp-msg')
        $(msg).text('Submitted. Refresh to see new results.')
        $(msg).addClass('submitted-row')
        remove_entry_from_changes(data.entry_id, 'submit')
    error: (response) ->
      msg = response.resonseJSON.error
      std_msg_error("Error submitting entry", msg, reload: false)
  , this)


# Sending individual reviewed (PENDING) entry info to the backend
process_review = (entry_data) ->
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  std_msg_ajax(
    url: '/escalations/api/v1/escalations/webcat/complaint_entries/update_pending'
    method: 'POST'
    headers: headers
    data: {
      data: [entry_data]
    }
    success: (response) ->
      data = $.parseJSON(response)
      msg = $('#' + data.entry_id + ' .temp-msg')
      $(msg).text('Submitted. Refresh to see new results.')
      $(msg).addClass('submitted-row')
      remove_entry_from_changes(data.entry_id, 'review')
    error: (response) ->
      msg = response.resonseJSON.error
      std_msg_error("Error submitting reviewed entries", msg, reload: false)
  , this)




$ ->
  ### New for card style rows ###
  # Changes which value is in the entry's uri input
  window.update_editURI = (entry_id, value, value_type) ->
    # update input
    input = '#edit_uri_input_' + entry_id
    $(input).val(value)
    $(input).attr('value', value)

    # adjust the quickie dropdown
    dropdown = '#quick_edit_dropdown_' + entry_id
    domain_link = $(dropdown).find('.quick-domain')
    dom_val = $(domain_link[0]).attr('data-val')
    sub_link = $(dropdown).find('.quick-subdomain')
    sub_val = $(sub_link[0]).attr('data-val')
    uri_link = $(dropdown).find('.quick-uri')
    uri_val = $(uri_link[0]).attr('data-val')

    if value_type == 'uri' || value_type == 'subdomain'
      $(domain_link).removeClass('disabled')
      $(domain_link).attr('onclick', 'update_editURI(\'' + entry_id + '\', \'' + dom_val + '\', \'domain\')')

      if value_type == 'subdomain'
        $(sub_link).addClass('disabled')
        $(sub_link).removeAttr('onclick')
        unless uri_val == ''
          $(uri_link).removeClass('disabled')
          $(uri_link).attr('onclick', 'update_editURI(\'' + entry_id + '\', \'' + uri_val + '\', \'uri\')')

      else if value_type == 'uri'
        $(uri_link).addClass('disabled')
        $(uri_link).removeAttr('onclick')
        unless sub_val == ''
          $(sub_link).removeClass('disabled')
          $(sub_link).attr('onclick', 'update_editURI(\'' + entry_id + '\', \'' + sub_val + '\', \'subdomain\')')

    else if value_type == 'domain'
      $(domain_link).addClass('disabled')
      $(domain_link).removeAttr('onclick')
      unless sub_val == ''
        $(sub_link).removeClass('disabled')
        $(sub_link).attr('onclick', 'update_editURI(\'' + entry_id + '\', \'' + sub_val + '\', \'subdomain\')')
      unless uri_val == ''
        $(uri_link).removeClass('disabled')
        $(uri_link).attr('onclick', 'update_editURI(\'' + entry_id + '\', \'' + uri_val + '\', \'uri\')')




  # New submit function that maintains current layout and spacing
  # by adding a screen overtop the submitted row, does not reload the page
  # Single submissions only, both PENDING and non PENDING
  window.submit_changes = (entry_id) ->
    row = $('#' + entry_id)
    curr_status = $(row).attr('data-status')

    # slight differences in data sent
    if curr_status == 'PENDING'
      status = ''
      commit = $('input[name=resolution_review' + entry_id+ ']:checked').val()
      # we are disabling the button if ignore is checked, but just in case
      if commit == 'ignore'
        return
    else
      commit = ''
      status = $('input[name=resolution' + entry_id + ']:checked').val()

    comment = $('#internal_comment_' + entry_id).val()
    resolution_msg = $('#entry-email-response-to-customers_' + entry_id).val()
    uri = $('#edit_uri_input_' + entry_id).val()
    if $('#input_cat_'+entry_id).val() != null
      cat_ids = $('#input_cat_'+entry_id).val().toString()
    else
      cat_ids = null
    category_name = $('#input_cat_' + entry_id).next('.selectize-control').find('.item')
    category_names = []
    category_name.each ->
      category_names.push($(this).text())
    category_names = category_names.toString()

    entry_data = {
      'id': entry_id,
      'prefix': uri,
      'categories': cat_ids,
      'category_names': category_names,
      'status': status,
      'commit': commit,
      'comment': comment,
      'resolution_comment': resolution_msg,
      'uri_as_categorized': uri
    }

    # check data here before submitting
    # If resolution is set to fixed, make sure it has categories applied
    if entry_data.categories == null && entry_data.status == "FIXED"
      std_msg_error("Must include at least one category.","", reload: false)
      return
    else if entry_data.status == "INVALID" && entry_data.categories != null
      std_msg_error("Cannot include categories with an INVALID resolution.", "", reload: false)
      return

    # need number of cols for replacement temp col
    visible_cols = $('#complaints-index thead th').length

    # gets submission row height, then assigns it so it won't change
    row_height = $(row).height()
    $(row).css('height', row_height + 'px')
    $(row).empty()
    $(row).addClass('submitting-entry')

    temp_msg = '<h3 class="temp-msg">Submitting entry...</h3>'
    $(row).append('<td colspan="' + visible_cols + '">' + temp_msg + '</td>')

    # remove from changes must be done before submission in case user clicks
    # bulk submission before ind submission is finished processing
    if curr_status == 'PENDING'
      remove_entry_from_changes(entry_id, 'review')
      process_review(entry_data)
    else
      remove_entry_from_changes(entry_id, 'submit')
      process_entry(entry_data)
      # submit for real


  window.prevent_close = (prevent) ->
    if prevent == 'true'
      window.onbeforeunload = (e) ->
        e.preventDefault()
        e = e || window.event
        e.returnValue = ''
    else
      window.onbeforeunload = null

  # webcat > complaints index, ensure this JS gets called
  if $('body').hasClass('escalations--webcat--complaints-controller') && $('body').hasClass('show-action')
    check_wbnp_status()

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


# Let users copy the customer description
window.copy_description = (item) ->
  description = $(item).text()
  dummy = document.createElement('input')
  document.body.appendChild dummy
  dummy.setAttribute 'value', description
  dummy.select()
  document.execCommand 'copy'
  document.body.removeChild dummy

  html = "<div class='copied-container'>" +
            "<span class='copied-check'></span>" +
            "<p id='copiedAlert'>Copied to clipboard</p>" +
          "</div>"

  $(item).after( html )
  $('.copied-container').delay(1000).fadeOut(1000);
  setTimeout (->
    $(".copied-container").remove()
  ), 2000


## SAVED (NAMED) SEARCH FUNCTIONS
window.temporary_search_link = (webcat_search_name, webcat_search_conditions) ->
  table = document.getElementById("saved-search")

  new_tr = document.createElement('tr')
  new_td = document.createElement('td')
  new_link =  document.createElement('a')
  new_delete_image = document.createElement('img')
  new_delete = document.createElement('a')
  new_fav_icon = document.createElement('span')

  new_tr.setAttribute('id','temp_row')
  $(new_link).addClass('input-truncate saved-search esc-tooltipped')
  $(new_link).attr('title', webcat_search_name)
  $(new_link).attr('data-search_conditions', webcat_search_conditions)
  $(new_link).text(webcat_search_name)
  $(new_delete).addClass("delete-search")
  $(new_delete_image).addClass('delete-search-image')
  $(new_fav_icon).addClass('nav-dropdown-icon favorite-search-icon')

  $(new_link).on 'click', () ->
    window.build_webcat_named_search(webcat_search_name)

  $(new_delete).on 'click', () ->
    window.delete_disputes_named_search(this,  webcat_search_name)
    refresh_webcat_localStorage()

  $(new_tr).append(new_td)
  $(new_td).append(new_link)
  $(new_td).append(new_delete)
  $(new_delete).append(new_delete_image)
  $(new_td).append(new_fav_icon)
  $(table).append(new_tr)

window.find_saved_search_by_name = (name) ->
  saved_search = null
  $("#saved-search-tbody a").each((i, elem) ->
    # trim() is needed for filter_name in case if there is extra space in saved filter
    if elem.text.trim() == name.trim()
      saved_search = $(elem)
      return
  )
  return saved_search

$ ->

  # TODO - lots of tooltip initializing, see if this can be consolidated
#  Webcat toolbar and wbnp status report tooltips need slight adjustment
  $('.esc-tooltipped-webcat-toolbar').tooltipster
    theme: [
      'tooltipster-borderless'
      'tooltipster-borderless-customized'
      'tooltipster-borderless-comment'
    ]
    debug: false
    maxWidth: 500
    position: 'bottom'
    distance: [-8, 0]

  $('.esc-tooltipped-webcat-toolbar:disabled').tooltipster
    disable: true
    debug: false

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
