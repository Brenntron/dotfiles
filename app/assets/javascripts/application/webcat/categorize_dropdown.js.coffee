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



submit_categorize_urls = () ->
  data = {}
  isEmpty = true
  $('#categorize-urls').dropdown('toggle')
  for i in [1...6] by 1
    categories = []
    for j in [0...5] by 1
      if $("#cat_new_url_#{i}")[0][j]
        categories.push($("#cat_new_url_#{i}")[0][j].text)

    data[i] = {url: $("#url_#{i}").val(), category_names: categories, category_ids: $("#cat_new_url_#{i}").val()}

    if data[i].url.length > 0 && data[i].category_ids != null
      isEmpty = false

  if !isEmpty
    std_msg_ajax(
      url:'/escalations/api/v1/escalations/webcat/complaints/cat_new_url'
      method: 'POST'
      data: {data: data}
      success: (response) ->
        timesTouched = 0
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
            $('#url_1').val('')
            $('#url_2').val('')
            $('#url_3').val('')
            $('#url_4').val('')
            $('#url_5').val('')
            # clear categories inputs
            $('#cat_new_url_1')[0].selectize.clear()
            $('#cat_new_url_2')[0].selectize.clear()
            $('#cat_new_url_3')[0].selectize.clear()
            $('#cat_new_url_4')[0].selectize.clear()
            $('#cat_new_url_5')[0].selectize.clear()
          )
        )
      error: (response) ->
        if response.responseText.includes('Either no products have been defined to enter bugs against or you have not been given access to any.')
          std_api_error(response, "Please make sure you have the appropriate permissions. Unable to categorize url.", reload: false)
        else
          std_api_error(response, "Unable to categorize url.", reload: false)
    )
  else
    std_msg_error("Unable to categorize", ["Please confirm that a URL and at least one category for each desired entry exists."], reload: false)



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
        std_msg_success('Success',["URLs/IPs successfully categorized."])
      error: (response) ->
        loader.addClass('hidden')
        std_msg_error('Error' + ' ' + response.responseJSON.message,"", reload: false)

    )
  else
    std_msg_error('Error', ['Please check that a URL/IP has been inputted and that at least one category was selected.'], reload: false)