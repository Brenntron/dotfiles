namespace 'AC.WebCat', (exports) ->

  exports.createCompanyOptions = ->
    std_msg_ajax(
      method: 'GET'
      url: "/escalations/api/v1/escalations/webcat/companies"
      success_reload: false
      success: (response) ->
        element = $('#company-input')
        selectize = element[0].selectize

        json = JSON.parse(response)

        for company in json
          selectize.addOption(company)

        { webcat_search_conditions, webcat_search_type } = localStorage

        if webcat_search_type?
          if webcat_search_type == 'advanced'
            { company_name } = JSON.parse localStorage.webcat_search_conditions

            if company_name
              element[0].selectize.setValue(company_name)
    )

  exports.createCustomerNameOptions = ->
    std_msg_ajax(
      method: 'GET'
      url: "/escalations/api/v1/escalations/webcat/customers_names_selectize"
      success_reload: false
      success: (response) ->
        element = $('#name-input')
        selectize = element[0].selectize

        json = JSON.parse(response)

        for customer_name in json
          selectize.addOption(customer_name)

        { webcat_search_conditions, webcat_search_type } = localStorage

        if webcat_search_type?
          if webcat_search_type == 'advanced'
            { customer_name } = JSON.parse localStorage.webcat_search_conditions

            if customer_name
              element[0].selectize.setValue(customer_name)
    )

  exports.createAssigneeOptions = ->
    std_msg_ajax(
      method: 'GET'
      url: "/escalations/api/v1/users/json"
      success_reload: false
      success: (response) ->
        element = $('#assignee-input')
        selectize = element[0].selectize

        json = JSON.parse(response)

        for assignee in json
          selectize.addOption(assignee)

        { webcat_search_conditions, webcat_search_type } = localStorage

        if webcat_search_type?
          if webcat_search_type == 'advanced'
            { user_id } = JSON.parse localStorage.webcat_search_conditions

            if user_id
              element[0].selectize.setValue(user_id)
    )

  exports.populateSearchCriteria = ->
    return unless localStorage.webcat_search_conditions
    searchConditions = JSON.parse localStorage.webcat_search_conditions
    for label, search_value of searchConditions
      continue if search_value == ''

      console.log 'ininin'
      selectize_elements = ['tags','assignee','category','company','status','resolution','name','complaint','channel','entryid','complaintid','jiraid','submitter-type']

      if label == 'id'             then label = 'entryid'
      if label == 'user_id'        then label = 'assignee'
      if label == 'platform_ids'   then label = 'platform'
      if label == 'ip_or_uri'      then label = 'complaint'
      if label == 'customer_email' then label = 'email'
      if label == 'company_name'    then label = 'company'
      
      #make sure that labels match the corresponding adv search input
      search_label = label.replace('_',  '').replace('ids',  '')
      input_element = $("##{search_label}-input")
      if selectize_elements.includes(search_label)
        #set values of known selectize inputs
        values = search_value.split(', ')
        for val in values
          input_element[0].selectize.addOption({ value: val, text: val })
          input_element[0].selectize.setValue(values)
      else if input_element[0] && input_element[0].selectize
        #catchall for inputs that fall through the cracks
        input_element[0].selectize.setValue(search_value)
      else
        #set values of non selectize inputs
        input_element.val(search_value)

      # if the value has been searched, make sure that the input isn't hidden
      input_element.removeClass('hidden')
