namespace 'AC.WebCat', (exports) ->

  exports.getAUPCategories = ->
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    $.ajax(
      url: "/escalations/api/v1/escalations/webcat/complaints/category_list"
      method: 'GET'
      headers: headers
      success: (response) ->
        return response
      error: (response) ->
        return response
    )


  exports.createSelectOptions = (id) ->
#    debugger
    if id != undefined
      AC.WebCat.getAUPCategories().then( (categories) =>
        webcat_options = []
        for key, value of categories
          cat_code = key.split(' - ')[1]
          value_name = key.split(' - ')[0]
          webcat_options.push {category_id: value, category_name: value_name, category_code: cat_code}
        $(id)[0].selectize.addOption(webcat_options)
      )

    else return

  exports.createSelectOptionsForIds = (ids) ->
    AC.WebCat.getAUPCategories().then( (categories) =>
      webcat_options = []
      for key, value of categories
        cat_code = key.split(' - ')[1]
        value_name = key.split(' - ')[0]
        webcat_options.push {category_id: value, category_name: value_name, category_code: cat_code}
      for id in ids
        $(id)[0].selectize.addOption(webcat_options)
    )

  exports.getCategoryIds = (category_names, id) ->

    AC.WebCat.getAUPCategories().then( (categories) =>
      category_ids = []
      for name in category_names
        for x, y of categories
          value_name = x.split(' - ')[0]

          if name == value_name
            category_ids.push(y)

      $(id)[0].selectize.addItem(category_ids)
    )
