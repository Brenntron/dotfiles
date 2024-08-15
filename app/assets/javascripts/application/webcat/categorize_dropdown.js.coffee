## WEBCAT CATEGORIZE URLS DROPDOWN FUNCTIONS ##
$ ->

  $('#categorize-urls').on 'click', ->

    # Populate the category selectizes on the dropdown
    new_url_cats = $('select.cat_new_url')
    for select in new_url_cats
      $(select).selectize {
        persist: true,
        create: false,
        maxItems: 5,
        closeAfterSelect: true,
        valueField: 'category_id',
        labelField: 'category_name',
        searchField: ['category_name', 'category_code'],
        options: AC.WebCat.createSelectOptions("##{select.id}")
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

    # Populate the platform selects
    AC.DataLoaders.load_plaforms().then( (platforms) =>
      $('#multiurl_platform_select').empty()
      $('.platform-new-url').empty()

      platform_options = ''
      for platform in platforms.data
        platform_options += '<option value="' + platform.public_name + '">' + platform.public_name + '</option>'

      $('#multiurl_platform_select').append platform_options
      $('.platform-new-url').each ->
        $(this).append platform_options
    )

    # Populate the tag selects
    $('.tags-new-url').each ->
      $(this).selectize {
        persist: false,
        create: (input) ->
          {name: input}
        maxItmes: null
        valueField: 'name'
        labelField: 'name'
        searchField: 'name'
        options: tag_select_options()
        onFocus: () ->
          window.toggle_selectize_layer(this, 'true')
        onBlur: () ->
          window.toggle_selectize_layer(this, 'false')
      }


  # there is a hidden input already on the page that has all existing tags
  tag_select_options = ->
    tags = $('#complaint_tag_list')[0]
    if tags
      tag_list = tags.value
      array = tag_list.split(',')
      options = []
      for x in array
        options.push {name: x}
      return options

  # Switch which form type is shown
  $('#cat-urls-diff').click ->
    if $('#cat-urls-diff').prop('checked')
      $('#categorize-same-form').hide()
      $('#categorize-diff-form').show()

  $('#cat-urls-same').click ->
    if $('#cat-urls-same').prop('checked')
      $('#categorize-diff-form').hide()
      $('#categorize-same-form').show()



# Lookup current categories of input urls
window.lookup_prefix = () ->
  $('#categorize-diff-form .webcat-loader').removeClass('hidden')

  urls = []
  url_inputs = $('#categorize-diff-form .url-input')
  url_inputs.each ->
    urls.push($(this).val())

  std_msg_ajax(
    url:'/escalations/api/v1/escalations/webcat/complaints/lookup_prefix'
    method: 'POST'
    data: { 'urls': urls }

    success: (response) ->
      i = 1
      for [i .. 5]
        j = 0
        try
          for [j .. Object.keys(response.json[i]).length]
            selector = '#cat_new_url_' + i.toString()
            $select= $(selector).selectize()
            selectize = $select[0].selectize
            selectize.addItem(response.json[i][j])
            j++
        catch
          i++
          continue
        i++
      $('#categorize-diff-form .webcat-loader').addClass('hidden')
  )



window.drop_current_categories = () ->
  loader = $('#categorize-diff-form .webcat-loader')
  $(loader).removeClass('hidden')
  $(".cat-url-msg").hide()

  urls = {}

  for i in [1 .. 5]
    $("#url_#{i}").removeClass('cat-url-input-error')
    if $("#url_" + i ).val() != ""
      url_data = {
        url: $("#url_" + i ).val(),
        platform: $("#platform_new_url_" + i).val(),
        tags: $("#tags_new_url_" + i).val()
    }
      urls[i] = url_data

  std_msg_ajax(
    url:'/escalations/api/v1/escalations/webcat/complaints/drop_current_categories'
    method: 'POST'
    data: { 'urls': urls }
    success: (response) ->

      message = ""
      for key, value of response.json
        # clear any residual classes on the msg wrapper
        msg_wrapper = $("#cat-url-msg-#{key}")
        $(msg_wrapper).removeClass('cat-url-error')
        $(msg_wrapper).removeClass('cat-url-success')

        if value && (value.popular || value.code == 200)
          if value.popular == true
            message = "Pending complaint entry has been created."
          else
            message = "Categories successfully dropped."
          $(msg_wrapper).text(message)
          $(msg_wrapper).addClass('cat-url-success')
          $(msg_wrapper).show()
          select= $("#cat_new_url_#{key}").selectize()
          selectize = select[0].selectize
          selectize.clear()
        else
          $("#url_#{key}").addClass('cat-url-input-error')
          $(msg_wrapper).text("Unable to drop categories.")
          $(msg_wrapper).addClass('cat-url-error')
          $(msg_wrapper).show()

      $(loader).addClass('hidden')
    error: (response) ->
      $(loader).addClass('hidden')
      std_msg_error("<p>There has been an error dropping categories: #{json.error}","")
  )


window.retrieve_history = (position) ->
  loader = $('#categorize-diff-form .webcat-loader')
  loader.removeClass('hidden')

  url = $("#url_" + position).val()
  msg = $('#cat-url-msg-' + position)
  url_input = $(msg[0]).next().next('.url-input')

  $(msg).empty().hide()
  $(url_input).removeClass('cat-url-input-error')

  if url.length > 0
    std_msg_ajax(
      url: '/escalations/api/v1/escalations/webcat/complaint_entries/categorize_urls_history'
      method: 'POST'
      data: {'position': position, url: url}
      success: (response) ->
        loader.addClass('hidden')
        json = JSON.parse(response)
        if json.error
          std_msg_error("<p>Something went wrong: #{json.error}","")
        else
          history_dialog_content =
              "<div class='cat-history-dialog dialog-content-wrapper'>
               <h4>#{url}</h4>
               <ul class='nav nav-tabs dialog-tabs' role='tablist'>
               <li class='nav-item active' role='presentation'>
                <a class='nav-link' role='tab' data-toggle='tab' href='#domain-history-tab' aria-controls='domain-history-tab'>
                   Domain History
                </a>
               </li>
               <li class='nav-item' role='presentation'>
                <a class='nav-link xbrs-history-tab' role='tab' data-toggle='tab' href='#xbrs-history-tab' aria-controls='xbrs-history-tab' onclick='get_xbrs_history(\"#{url}\", this)'>
                  XBRS History
                </a>
               </li>
               </ul>
                <div class='tab-pane active' role='tabpanel' id='domain-history-tab'>
                  <h5>Domain History</h5>
                  <table class='history-table'>
                    <thead>
                       <tr>
                        <th>Action</th>
                        <th>Confidence</th>
                        <th>Description</th>
                        <th>Time</th>
                        <th>User</th>
                        <th>Category</th>
                       </tr>
                    </thead>
                    <tbody>"
          for entry in json
            { action, confidence, description, time, user, category } = entry
            entry_string =
              "<tr>
                <td> #{action}</td>
                <td> #{confidence}</td>
                <td> #{description}</td>
                <td> #{time} </td>
                <td> #{user}</td>
                <td> #{category.descr}</td>
               </tr>"

            history_dialog_content += entry_string

          history_dialog_content +=
            "</tbody></table>
             </div>
             <div class='tab-pane' role='tabpanel' id='xbrs-history-tab'>
                <h5>XBRS History</h5>
                <table class='history-table xbrs-history-table' id='webcat-xbrs-history'></table>
             </div>"

          if $("history_dialog").length
            history_dialog = this
            $("#history_dialog").html(history_dialog_content)
            $('#history_dialog').dialog('open')
          else
            history_dialog = '<div id="history_dialog" title="History Information"></div>'
            $('body').append(history_dialog)
            $("#history_dialog").html(history_dialog_content)
            $('#history_dialog').dialog
              autoOpen: false
              minWidth: 600
              position: { my: "right top", at: "right top", of: window }
            $('#history_dialog').dialog('open')
            $('dialog_tabs').tabs();

      error: (response) ->
        loader.addClass('hidden')
        $(msg).addClass('cat-url-error')
        $(msg).text("No history associated with this url")
        $(msg).show()
        $(url_input).addClass('cat-url-input-error')
    , this)
  else
    loader.addClass('hidden')
    $(msg).addClass('cat-url-error')
    $(msg).text("Not a valid url")
    $(msg).show()
    $(url_input).addClass('cat-url-input-error')



window.cat_new_url = ()->
  loader = $('#categorize-diff-form .webcat-loader')
  loader.removeClass('hidden')
  categorizations_to_submit = {}

  $('#categorize-diff-form .individual-url').each ->
    url_input = $($(this).find('.url-input')[0]).val()
    cats_input_ids = $($(this).find('.cat_new_url')[0]).val()
    cats_input_names = []
    url_index = $($(this).find('.url-input')[0]).attr('id').split('_').pop()
    platform = $(this).find('.platform-new-url').val()
    tags = $(this).find('.tags-new-url').val()

    if url_input == '' || cats_input_ids == ''
      return
    else
      $(this).find('.cat_new_url .item').each ->
        cat_name = $(this).text()
        cats_input_names.push(cat_name)

      categorizations_to_submit[url_index] = {
        'url': url_input,
        'category_names': cats_input_names,
        'category_ids': cats_input_ids
        'platform': platform
        'tags': tags
      }

  data = {data: categorizations_to_submit}

  std_msg_ajax(
    url:'/escalations/api/v1/escalations/webcat/complaints/cat_new_url'
    method: 'POST'
    data: data
    success: (response) ->
      loader.addClass('hidden')
      popular_entries = []
      non_pop_entries = []
      pending_message = ""
      message = ""

      for key, val of response
        if val.popular == true
          popular_entries.push(val.url)
        else
          non_pop_entries.push(val.url)

      if popular_entries.length > 0
        pending_message = "Pending complaint entries have been created for #{popular_entries.join(',')}"
        if non_pop_entries.length > 0
          message = "All other entries have been submitted directly to WBRS."
      else
         message = "Entries have been submitted directly to WBRS."


      std_msg_success(
        'URLs categorized successfully',
        [pending_message, message],
        reload: false,
        complete: (->
          # clear url inputs
          $('.url-input').val('')

          for i in [1 .. 5]
            # clear categories inputs & tags
            $("#cat_new_url_#{i}")[0].selectize.clear()
            $("#tags_new_url_#{i}")[0].selectize.clear()
            # clear residual msg & error class
            msg = $("#cat-url-msg-#{i}")
            url_input = $(msg[0]).next().next('.url-input')
            $(msg).empty().hide()
            $(url_input).removeClass('cat-url-input-error')

        )
      )
    error: (response) ->
      std_api_error(response, "Unable to categorize url.", reload: false)
  )



window.multiple_url_categorization = () ->
  loader = $('#bulk_cat_url_loader')
  loader.removeClass('hidden')

  categorizations_to_submit = {}
  urls = $("#categorize_urls").val().split(/\n/)
  category_ids = $("#multi_cat_url_cats").val()
  category_names = []
  platform = $("#multiurl_platform_select").val()
  tags = $("#multiurl_tag_select").val()

  for category in $("#multi_cat_url_cats")
    for i in [0..5] by 1
      if category[i]
        category_names.push(category[i].text)

  $(urls).each (i) ->
    categorizations_to_submit[i] = {
      'url': this,
      'category_names': category_names,
      'category_ids': category_ids,
      'platform': platform,
      'tags': tags
    }

  data = {data: categorizations_to_submit}
  console.log data
  if $("#categorize_urls").val() != "" && category_ids != null && category_names != null
    std_msg_ajax(
      url:'/escalations/api/v1/escalations/webcat/complaints/cat_new_url'
      method: 'POST'
      data: data
      success: (response) ->
        popular_entries = []
        non_pop_entries = []
      pending_message = ""
      message = ""

      for key, val of response
        if val.popular == true
          popular_entries.push(val.url)
        else
          non_pop_entries.push(val.url)

      if popular_entries.length > 0
        pending_message = "Pending complaint entries have been created for #{popular_entries.join(',')}"
        if non_pop_entries.length > 0
          message = "All other entries have been submitted directly to WBRS."
      else
        message = "Entries have been submitted directly to WBRS."

        std_msg_success(
          'URLs categorized successfully',
          [message, pending_message],
          reload: false,
          complete: (->
            # clear form inputs
            $('#categorize_urls').val('')
            $('#multi_cat_url_cats')[0].selectize.clear()
            $('#multiurl_tag_select')[0].selectize.clear()
            loader.addClass('hidden')
          )
        )
      error: (response) ->
        loader.addClass('hidden')
        std_msg_error('Error' + ' ' + response.responseJSON.message,"", reload: false)
    )
  else
    std_msg_error('Error', ['Please check that a URL/IP has been entered and that at least one category was selected.'], reload: false)


window.drop_multiple_url_categories = () ->
  loader = $('#bulk_cat_url_loader')
  urls = {}

  for url, index in $("#categorize_urls").val().trim().split(/\s+/)
    if url != ''
      urls[index + 1] = url

  loader.removeClass('hidden')

  if $("#categorize_urls").val() != ""
    std_msg_ajax(
      url:'/escalations/api/v1/escalations/webcat/complaints/drop_current_categories'
      method: 'POST'
      data: { 'urls': urls }
      success: (response) ->
        popular_entries = []
        non_pop_entries = []
        pending_message = ""
        message = ""
        successed_response = true

        for key, value of response.json
          if value && value.popular == true
            popular_entries.push(value.url)
          else if value && value.popular != true
            non_pop_entries.push(val.url)
          if value && !(value.popular || value.code == 200)
            success_response = false

        if success_response
          if popular_entries.length > 0
            pending_message = "Pending complaint entries have been created for #{popular_entries.join(', ')}"
            if non_pop_entries.length > 0
              message = "All other entries have been submitted directly to WBRS."
          else
            message = "Entries have been submitted directly to WBRS."

          std_msg_success(
            'URLs categories successfully dropped',
            [pending_message, message],
            reload: false,
            complete: (->
              # clear form inputs
              $('#categorize_urls').val('')
              $('#multi_cat_url_cats')[0].selectize.clear()
              loader.addClass('hidden')
            )
          )

        else
          std_msg_error(
            "Error dropping categories", '',
            reload: false,
            complete: (->
              loader.addClass('hidden')
            )
          )


      error: (response) ->
        loader.addClass('hidden')
        std_msg_error("Error #{response.responseJSON.message}", '', reload: false)
    )
  else
    std_msg_error('Error', ['Please check that a URL/IP has been entered.'], reload: false)

