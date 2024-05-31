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

  exports.get_current_categories = (entry_id, is_index_page, error_callback) ->
    std_msg_ajax(
      method: 'POST'
      url: '/escalations/api/v1/escalations/webcat/complaint_entries/retrieve_current_categories'
      data: { 'id': entry_id }
      success: (response) ->
        { current_category_data: current_categories, master_categories, sds_category, sds_domain_category, id: row_id } = JSON.parse(response)
        # If sds category or sds domain category is undefined or null, set it to an empty string
        sds_category = if !sds_category then '' else sds_category
        sds_domain_category = if !sds_domain_category then '' else sds_domain_category
        tooltip_table = ''

        if is_index_page
          # If there are any current categories (WBRS)
          # Put the top one in the list
          # All other cat details will be in a tooltip
          primary_cat = '<span class="missing-data">No current external categories</span>'

          if (current_categories || sds_category || sds_domain_category)
            tooltip_table = '<div class="current-external-cat-info">'

          wbrs_table = "<label class='tooltip-table-label'>WBRS</label>"
        else
          wbrs_table = ''

        wbrs_table += "<table class='#{if is_index_page then 'category-tooltip-table' else 'categories-table'}'>
                         <thead>
                           <tr>
                             <th>
                               Conf
                             </th>
                             <th>
                               WBRS Categories
                             </th>
                             <th>
                               Certainty
                             </th>
                             <th colspan='3'>
                               Feeds
                             </th>
                           </tr>
                         </thead>
                         <tbody>"

        if Object.keys(current_categories).length > 0
          $.each current_categories, (conf, current_category) ->
            return 'continue' unless current_category.is_active

            { confidence, mnem: mnemonic, descr: name, category_id: cat_id, top_certainty, certainties } = current_category
            rowspan = if certainties && certainties.length > 0 then certainties.length else 0
            wbrs_table += "<tr>
                             <td rowspan='#{rowspan}'>
                               #{confidence}
                             </td>
                             <td rowspan='#{rowspan}'>
                               #{mnemonic} - #{name}
                             </td>
                             <td rowspan='#{rowspan}'>
                               #{top_certainty}
                             </td>"

            # This adds another row to the feeds column
            if certainties
              certainties_cell = ''
              certainties.forEach (certainty, index) ->
                { certainty: source_certainty, source_description, source_mnemonic } = certainty
                certainties_cell += '<tr>' unless index == 0

                certainties_cell += "<td class='alt-col'>
                                 #{source_certainty}
                               </td>
                               <td class='alt-col'>
                                 #{source_mnemonic}
                               </td>
                               <td class='alt-col'>
                                 #{source_description}
                               </td>"

              certainties_cell += '</tr>'
              wbrs_table += certainties_cell
            else
              wbrs_table += "<td colspan='3'></td></tr>"

            if conf == '1.0' && is_index_page
              primary_cat = '<a class="esc-tooltipped tooltip-underline">' + current_category.mnem + ' - ' + current_category.descr + ' <span class="ex-category-source">WBRS</span></a>'
        else
          wbrs_table += '<tr><td style="text-align: center;" colspan="4">No assigned categories.</td></tr>'

          if sds_category && is_index_page
            primary_cat = "<a class='esc-tooltipped tooltip-underline'>
                            #{sds_category} <span class='ex-category-source'>SDS URI</span>
                           </a>"

          else if sds_domain_category && is_index_page
            primary_cat = "<a class='esc-tooltipped tooltip-underline'>
                            #{sds_domain_category} <span class='ex-category-source'>SDS Domain</span>
                           </a>"


        wbrs_table += '</tbody></table>'

        # build the rest of the tooltip if there is stuff from SDS
        sds_table = if is_index_page
          "<label class='tooltip-table-label'>SDS</label>"
        else
          ''

        sds_table += "<table class=#{ if is_index_page then 'category-tooltip-table' else 'categories-table' }>
                        <thead>
                          <tr>
                            <th>SDS URI Category</th>
                            <th>SDS Domain Category</th>
                          </tr>
                        </thead>
                        <tbody>
                          <tr>
                            <td>#{ sds_category || 'No SDS URI Catgory' }</td>
                            <td>#{ sds_domain_category || 'No SDS Domain Category' }</td>
                          </tr>
                        </tbody>
                      </table>"

        if is_index_page
          tooltip_table += wbrs_table + sds_table + '</div>'

          $('#current_cat_' + entry_id).html(primary_cat)

          if tooltip_table != '</div>'
            $('#current_cat_' + entry_id + ' a.esc-tooltipped').tooltipster
              content: $(tooltip_table),
              theme: [
                'tooltipster-borderless'
                'tooltipster-borderless-customized'
              ],
              minWidth: '820'
        else
          current_category_tables = wbrs_table + sds_table
          $('#current_categories_loader').hide()
          $('.external-categories-section').append current_category_tables
      error: (response) ->
        error_callback(response)
    )
