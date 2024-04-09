namespace 'AC.SDR', (exports) ->
  exports.populate_search_criteria = ->
    { sdr_search_conditions, sdr_search_type } = localStorage

    advanced = sdr_search_conditions && sdr_search_type == 'advanced'
    named = sdr_search_conditions && sdr_search_type == 'named'
    return unless advanced || named
    # if there is no advance search or search conditions then break

    $("input[name=search_name]").val(localStorage.sdr_search_name) if named

    search_conditions = JSON.parse sdr_search_conditions
    company_val = []
    name_val = []
    cat_val = []
    selectize_elements = [
                          'assignee',
                          'category',
                          'channel',
                          'company',
                          'complaint',
                          'complaintid',
                          'entryid',
                          'jiraid',
                          'name',
                          'platform',
                          'resolution',
                          'status',
                          'submitter-type',
                          'tags'
                        ]

    # Hide all search-critia so we don't display criteria outside of the search parameters.
    $('.search-item').addClass('hidden')
    $('.search-criteria-label').parent('li').removeClass('hidden')

    for label, search_value of search_conditions
      continue if search_value == '' || ['category', 'platforms'].includes(label)

      #make sure that labels match the corresponding adv search input
      switch label
        when 'id' then label = 'disputeid'
        when 'case_owner' then label = 'owner'
        when 'platform_ids' then label = 'platform'
        when 'customer_email' then label = 'email'
        when 'company_name' then label = 'company'
        when 'submitter_type' then label = 'submitter-type'
        when 'customer_name' then label = 'name'
        else
          #make sure that labels match the corresponding adv search input
          label = label.replace('_',  '')
                        .replace('modified',  'modified-')
                        .replace('submitted',  'submitted-')
                        .replace('ids',  '')

      $input_element = $("##{label}-input")
      $search_item = $($input_element.parent(".search-item"))

      if $input_element[0] && $input_element[0].selectize
        $selectize = $input_element[0].selectize
        values = search_value.split(',').map( (val) -> return val.trim())

        switch label
          when 'assignee'
            $assignee_selectize = $selectize
            assignee_items = values

            setTimeout ->
              $assignee_selectize.setValue(assignee_items)
            , 500
          when 'category'
            $category_selectize = $selectize
            category_items = values

            setTimeout ->
              $category_selectize.setValue(category_items)
            , 5000
          when 'company'
            $company_selectize = $selectize
            company_options = []
            company_items = values

            for val in values
              company_options.push { company_name: val }

            $company_selectize.addOption(company_options)

            $company_selectize.setValue(company_items)
          when 'email'
            $email_selectize = $selectize
            email_options = []
            email_items = values

            for val in values
              $email_selectize.addOption({ email: val })

            setTimeout ->
              $email_selectize.setValue(email_items)
            , 500
          when 'name'
            $name_selectize = $selectize
            name_options = []
            name_items = values

            for val in values
              $name_selectize.addOption({ name: val })

            setTimeout ->
              $name_selectize.setValue(name_items)
            , 500
          when 'platform'
            $platform_selectize = $selectize
            platform_options = []
            platform_items = values

            for val in values
              platform_options.push { public_name: val }

            $platform_selectize.addOption

            setTimeout ->
              $platform_selectize.setValue(platform_items)
            , 500
          else
            options = []
            for val in values
              options.push {value: val, text: val }

            $selectize.addOption options

            $selectize.setValue values
      else
        $input_element.val search_value

      # if the value has been searched, make sure that the input isn't hidden
      $search_item.removeClass('hidden')
      $("#{label}-cb").parent('li').addClass('hidden')

    search_pref = {}
    # Update advanced search preferences to match the edited saved search.
    $('.form-control').each ->
      search_item_id = $(this).attr('id')

      if $(this).hasClass('hidden')
        search_pref[search_item_id] = 'false'
      else
        search_pref[search_item_id] = 'true'

    data = search_pref

    # save to db
    std_msg_ajax(
      url: "/escalations/api/v1/escalations/user_preferences/update"
      method: 'POST'
      data: { data, name: 'SDRAdvancedSearchFieldsDisplayed' }
      dataType: 'json'
      success: (response) ->
        return false
    )
