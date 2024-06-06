namespace 'AC.DataLoaders', (exports) ->
  milisecondsInHour = 3600000
  milisecondsInDay  = 86400000

  exports.load_plaforms = ->
    plaform_list = getItemWithExpiry('platform_list')
    if plaform_list
      return Promise.resolve(plaform_list)
    else
      headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
      $.ajax(
        url: "/escalations/api/v1/escalations/webcat/platforms_names"
        method: 'GET'
        headers: headers
        success: (response) ->
          setItemWithExpiry('platform_list', response, milisecondsInDay)
          return response
        error: (response) ->
          console.log response
      )

  exports.load_customer_names = ->
    customer_list = getItemWithExpiry('customers_names_selectize')
    if customer_list
      return Promise.resolve(customer_list)
    else
      headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
      $.ajax(
        url: "/escalations/api/v1/escalations/webcat/customers_names"
        method: 'GET'
        headers: headers
        success: (response) ->
          setItemWithExpiry('customers_names_selectize', response, milisecondsInHour)
          return response.data
        error: (response) ->
          console.log response
      )


  exports.load_users_list = ->
    user_list = getItemWithExpiry('users_list')
    if user_list
      return Promise.resolve(user_list)
    else
      headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
      $.ajax(
        url: "/escalations/api/v1/users/json"
        method: 'GET'
        headers: headers
        success: (response) ->
          setItemWithExpiry('users_list', JSON.parse(response), milisecondsInHour)
          return response
        error: (response) ->
          console.log response
      )

  exports.load_customers_emails = ->
    customer_emails = getItemWithExpiry('customers_emails')
    if customer_emails
      return Promise.resolve(customer_emails)
    else
      headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
      $.ajax(
        url: "/escalations/api/v1/escalations/webcat/customers_email"
        method: 'GET'
        headers: headers
        success: (response) ->
          setItemWithExpiry('customers_emails', response.data, milisecondsInHour)
          return response.data
        error: (response) ->
          console.log response
      )