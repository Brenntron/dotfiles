namespace 'AC.WebCat', (exports) ->

  ## I think we fetch this entirely too many times per page, there must be a simpler way ##
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
    if $(id)[0] != undefined
      AC.WebCat.getAUPCategories().then( (categories) =>
        webcat_options = []
        for key, value of categories
          cat_code = key.split(' - ')[1]
          value_name = key.split(' - ')[0]
          webcat_options.push {category_id: value, category_name: value_name, category_code: cat_code}
        if $(id)[0]?
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
        if $(id)[0]?
          $(id)[0].selectize.addOption(webcat_options)
    )

  exports.getCategoryIds = (category_names, id) ->
    AC.WebCat.getAUPCategories().then( (categories) =>
      category_ids = []
      for name in category_names
        for x, y of categories
          value_name = x.split(' - ')[0]
          if name.trim() == value_name
            category_ids.push(y)

      id = id.slice(1)
      $edit_cats = $(document.getElementById(id))

      if $edit_cats[0]?
        edit_cats_selectize = $edit_cats[0].selectize

        # in case options didn't load yet, lets check those first
        options = edit_cats_selectize.options
        options_count = Object.keys(options).length
        if options_count < 1
          webcat_options = []
          for key, value of categories
            cat_code = key.split(' - ')[1]
            value_name = key.split(' - ')[0]
            webcat_options.push {category_id: value, category_name: value_name, category_code: cat_code}
          edit_cats_selectize.addOption(webcat_options)

        # Add the cat items
        if category_ids.length > 0
          $(category_ids).each ->
            cat_id = this
            edit_cats_selectize.addItem(cat_id)

    )