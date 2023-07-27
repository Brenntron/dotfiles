namespace 'AC.WebCat', (exports) ->

  exports.createCompanyOptions = ->
    std_msg_ajax(
      method: 'GET'
      url: "/escalations/api/v1/escalations/webcat/companies"
      success_reload: false
      success: (response) ->
        for company in JSON.parse(response)
          $('#company-input')[0].selectize.addOption(company)
      error : (response) ->
        console.log response
    )

  exports.createPlatformOptions = ->
    std_msg_ajax(
      method: 'GET'
      url: '/escalations/api/v1/escalations/webcat/platforms_names'
      success_reload: false
      success: (response) ->
        for platform in response.data
          $('#platform-input')[0].selectize.addOption({ public_name: platform })
      error : (response) ->
        console.log response
    )

  exports.createCustomerNameOptions = ->
    std_msg_ajax(
      method: 'GET'
      url: "/escalations/api/v1/escalations/webcat/customers_names_selectize"
      success_reload: false
      success: (response) ->
        for customer_name in JSON.parse(response)
          $('#name-input')[0].selectize.addOption(customer_name)

      error : (response) ->
        console.log response
    )

  exports.createAssigneeOptions = ->
    std_msg_ajax(
      method: 'GET'
      url: "/escalations/api/v1/users/json"
      success_reload: false
      success: (response) ->
        for assignee in JSON.parse(response)
          $('#assignee-input')[0].selectize.addOption(assignee)
      error : (response) ->
        console.log response
    )

  exports.populateSearchCriteria = ->

    {webcat_search_conditions, webcat_search_type} = localStorage
    advanced = webcat_search_conditions && webcat_search_type == 'advanced'
    named = webcat_search_type == 'named'

    return unless advanced || named
    # if there is no advance search or search conditions then break

    if named
      searchConditions = JSON.parse $("##{webcat_search_conditions} a").attr('data-search_conditions')

    company_val = []
    name_val = []

    for label, search_value of searchConditions
      continue if search_value == ''
      selectize_elements = ['tags','assignee','category','company','status','resolution','name','complaint','channel','entryid','complaintid','jiraid','submitter-type','platform']

      #make sure that labels match the corresponding adv search input
      label = label.replace('_',  '')
                   .replace('modified',  'modified-')
                   .replace('submitted',  'submitted-')
                   .replace('ids',  '')
      #make sure that labels match the corresponding adv search input
      if label == 'id'             then label = 'entryid'
      if label == 'userid'         then label = 'assignee'
      if label == 'platform_ids'   then label = 'platform'
      if label == 'ipor_uri'       then label = 'complaint'
      if label == 'customeremail'  then label = 'email'
      if label == 'companyname'    then label = 'company'
      if label == 'submittertype'  then label = 'submitter-type'
      if label == 'customername'   then label = 'name'

      input_element = $("##{label}-input")
      form_el = input_element.closest(".search-item")
      if selectize_elements.includes(label)
        #set values of known selectize inputs
        values = search_value.split(',').map( (val) => return val.trim())

        if label == 'company'
          # the company selectize requires a timeout to avoid timing issues
          company_val = values
          for val in company_val
            $("#company-input")[0].selectize.addOption(val)
          setTimeout ->
            $("#company-input")[0].selectize.setValue(company_val)
          ,500
        else if label == 'name'
          # the company names selectize requires a timeout to avoid timing issues
          name_val = values
          setTimeout ->
            for val in name_val
              $("#name-input")[0].selectize.addOption(val)
            $("#name-input")[0].selectize.setValue(name_val)
          ,5500
        else
          for val in values
            input_element[0].selectize.addOption({value: val, text: val })

        input_element[0].selectize.setValue(values)
      else
        if input_element[0] && input_element[0].selectize #catchall for selectize inputs that fall through the cracks
          input_element[0].selectize.setValue(search_value)
        else #set values of non selectize inputs
          input_element.val(search_value)

      # if the value has been searched, make sure that the input isn't hidden
      $(form_el).removeClass('hidden')