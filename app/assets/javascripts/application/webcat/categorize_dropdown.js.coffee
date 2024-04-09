## WEBCAT CATEGORIZE URLS DROPDOWN FUNCTIONS ##
$ ->

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
  $('.lookup-drop-loader').removeClass('hidden')

  urls = []
  for i in [1 .. 5]
    $select= $('#cat_new_url_' + i).selectize()
    selectize = $select[0].selectize
    selectize.clear()
    urls.push($("#url_" + i ).val())

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
      $('.lookup-drop-loader').addClass('hidden')
  )



window.drop_current_categories = () ->
  $(".cat-url-error").hide()
  $(".cat-url-success").hide()
  $('.lookup-drop-loader').removeClass('hidden')
  $("#url_#{i}").css("border-width", "")
  $("#url_#{i}").css("border-color", "")

  urls = {}

  for i in [1 .. 5]
    if $("#url_" + i ).val() != ""
      urls[i] = $("#url_" + i ).val()

  std_msg_ajax(
    url:'/escalations/api/v1/escalations/webcat/complaints/drop_current_categories'
    method: 'POST'
    data: { 'urls': urls }
    success: (response) ->
      for key, value of response.json
        if value && value.code == 200
          $("#cat-url-success-message-#{key}").text("Categories successfully dropped.")
          $("#cat-url-success-#{key}").show()
          select= $("#cat_new_url_#{key}").selectize()
          selectize = select[0].selectize
          selectize.clear()
        else
          $("#url_#{key}").css("border-width", "2px")
          $("#url_#{key}").css("border-color", "#E47433")
          $("#cat-url-error-message-#{key}").text("Unable to drop categories.")
          $("#cat-url-#{key}").show()
      $('.lookup-drop-loader').addClass('hidden')
    error: (response) ->
      $('.lookup-drop-loader').addClass('hidden')
      std_msg_error("<p>There has been an error dropping categories: #{json.error}","")
  )


window.retrieve_history = (position) ->
  $(".cat-url-error").hide()
  loader = $('.lookup-drop-loader')
  loader.removeClass('hidden')
  for url_position in [1..5]
    $("#url_#{url_position}").css("border-width", "")
    $("#url_#{url_position}").css("border-color", "")

  url = $("#url_" + position).val()

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
        $("#cat-url-error-message-#{position}").text("No history associated with this url.")
        loader.addClass('hidden')
        $("#cat-url-#{position}").show()
        $("#url_#{position}").css("border-width", "2px")
        $("#url_#{position}").css("border-color", "#E47433")
    , this)
  else
    $("#cat-url-error-message-#{position}").text("No data available for blank URL.")
    $("#cat-url-#{position}").show()
    $("#url_#{position}").css("border-width", "2px")
    $("#url_#{position}").css("border-color", "#E47433")


window.cat_new_url = ()->
  categorizations_to_submit = {}

  $('#categorize-diff-form .individual-url').each ->
    url_input = $($(this).find('.url-input')[0]).val()
    cats_input_ids = $($(this).find('.cat_new_url')[0]).val()
    cats_input_names = []
    url_index = $($(this).find('.url-input')[0]).attr('id').split('_').pop()

    if url_input == '' || cats_input_ids == ''
      return
    else
      $(this).find('.selectize-input .item').each ->
        cat_name = $(this).text()
        cats_input_names.push(cat_name)

      categorizations_to_submit[url_index] = {
        'url': url_input,
        'category_names': cats_input_names,
        'category_ids': cats_input_ids
      }

  #remove this console log when ready
  console.log categorizations_to_submit

  std_msg_ajax(
    url:'/escalations/api/v1/escalations/webcat/complaints/cat_new_url'
    method: 'POST'
    data: {data: categorizations_to_submit}
    success: (response) ->
#      debugger
      popular_entries = []
      message = ""
      for key, val of response
        if val.popular == true
          popular_entries.push(val.url)

      if popular_entries.length > 0
         message = "Pending complaint entries have been created for #{popular_entries.join(',')}"
      else
         message = "No pending complaint entries have been created"

      reload_message = "</br><a href='.'>Refresh the page</a> to see the result"
      std_msg_success(
        'URLs categorized successfully',
        [message, "All other entries have been submitted directly to WBRS.", reload_message],
        reload: false,
        complete: (->
          # clear url inputs
          $('.url-input').val('')
          # clear categories inputs
          $('#cat_new_url_1')[0].selectize.clear()
          $('#cat_new_url_2')[0].selectize.clear()
          $('#cat_new_url_3')[0].selectize.clear()
          $('#cat_new_url_4')[0].selectize.clear()
          $('#cat_new_url_5')[0].selectize.clear()
        )
      )
    error: (response) ->
      debugger
      # TODO - Find out where this response text is generated and fix, it makes no sense
      if response.responseText.includes('Either no products have been defined to enter bugs against or you have not been given access to any.')
        std_api_error(response, "Please make sure you have the appropriate permissions. Unable to categorize url.", reload: false)
      else
        std_api_error(response, "Unable to categorize url.", reload: false)
  )



window.multiple_url_categorization = () ->
  loader = $('.lookup-drop-loader')
  loader.removeClass('hidden')

  urls = $("#categorize_urls").val().split(/\n/)
  category_ids = $("#multi_cat_url_cats").val()
  category_names = []
  for category in $("#multi_cat_url_cats")
    for i in [0..5] by 1
      if category[i]
        category_names.push(category[i].text)

  if $("#categorize_urls").val() != "" && category_ids != null && category_names != null
    std_msg_ajax(
      url:'/escalations/api/v1/escalations/webcat/complaints/multi_cat_new_url'
      method: 'POST'
      data: {urls: urls, category_names: category_names, category_ids: category_ids}
      success: (response) ->
        loader.addClass('hidden')
        std_msg_success('Success',["URLs/IPs successfully categorized."], reload: false)
      error: (response) ->
        loader.addClass('hidden')
        std_msg_error('Error' + ' ' + response.responseJSON.message,"", reload: false)

    )
  else
    std_msg_error('Error', ['Please check that a URL/IP has been inputted and that at least one category was selected.'], reload: false)


window.drop_multiple_url_categories = () ->
  loader = $('.lookup-drop-loader')
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
        for key, value of response.json
          if value && value.code == 200
            loader.addClass('hidden')
            std_msg_success('Success', ["URLs/IPs categories successfully dropped."], reload: true)
          else
            std_msg_error('Error', ['Unable to drop categories.'], reload: false)
      error: (response) ->
        loader.addClass('hidden')
        std_msg_error("Error #{response.responseJSON.message}", '', reload: false)
    )
  else
    std_msg_error('Error', ['Please check that a URL/IP has been inputted.'], reload: false)

