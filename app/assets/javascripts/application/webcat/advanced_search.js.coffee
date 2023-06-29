namespace 'AC.WebCat', (exports) ->

  exports.createCompanyOptions = ->
    std_msg_ajax(
      method: 'GET'
      url: "/escalations/api/v1/escalations/webcat/companies"
      success_reload: false
      success: (response) ->
        element = $('#company-input')[0].selectize
        json = JSON.parse(response)
        for company in json
          element.addOption(company)
    )

  exports.createCustomerNameOptions = ->
    std_msg_ajax(
      method: 'GET'
      url: "/escalations/api/v1/escalations/webcat/customers_names_selectize"
      success_reload: false
      success: (response) ->
        json = JSON.parse(response)
        for customer_name in json
          $('#name-input')[0].selectize.addOption(customer_name)
    )

  exports.createAssigneeOptions = ->
    std_msg_ajax(
      method: 'GET'
      url: "/escalations/api/v1/users/json"
      success_reload: false
      success: (response) ->
        element = $('#assignee-input')[0].selectize
        json = JSON.parse(response)
        for assignee in json
          element.addOption(assignee)
    )

  exports.populateSearchCriteria = ->
    return unless localStorage.webcat_search_conditions
    searchConditions = JSON.parse localStorage.webcat_search_conditions
    company_val = []
    name_val = []
    
    for label, search_value of searchConditions
      continue if search_value == ''
      selectize_elements = ['tags','assignee','category','company','status','resolution','name','complaint','channel','entryid','complaintid','jiraid','submitter-type']

      #make sure that labels match the corresponding adv search input
      label = label.replace('_',  '')
                   .replace('modified',  'modified-')
                   .replace('submitted',  'submitted-')
                   .replace('ids',  '')
      #make sure that labels match the corresponding adv search input
      if label == 'id'             then label = 'entryid'
      if label == 'user_id'        then label = 'assignee'
      if label == 'platform_ids'   then label = 'platform'
      if label == 'ip_or_uri'      then label = 'complaint'
      if label == 'customeremail' then label = 'email'
      if label == 'companyname'    then label = 'company'
      if label == 'submittertype'  then label = 'submitter-type'
      if label == 'customername'   then label = 'name'

      input_element = $("##{label}-input")

      if selectize_elements.includes(label)
        #set values of known selectize inputs
        values = search_value.split(', ')

        if label == 'company'
          # the company selectize requires a timeout to avoid timing issues
          company_val = values
          setTimeout ->
            $("#company-input")[0].selectize.setValue(company_val)
          ,500
        else if label == 'name'
          # the company names electize requires a timeout to avoid timing issues
          name_val = values
          setTimeout ->
            $("#name-input")[0].selectize.setValue(name_val)
          ,2500
        else
          for val in values
            input_element[0].selectize.addOption({ value: val.trim(), text: val.trim() })

        input_element[0].selectize.setValue(values)
      else
        if input_element[0] && input_element[0].selectize
          #catchall for selectize inputs that fall through the cracks
          input_element[0].selectize.setValue(search_value)
        else
          #set values of non selectize inputs
          input_element.val(search_value)

#       if the value has been searched, make sure that the input isn't hidden
      input_element.removeClass('hidden')
