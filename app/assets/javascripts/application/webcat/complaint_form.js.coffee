$ ->
  $('#new-complaint').on 'click', ->
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    $.ajax(
      url: '/api/v1/escalations/webcat/customers'
      method: 'GET'
      dataType: 'json'
      headers: headers
      success: (response) ->
        $('#customerList').empty()
        i = 0
        while i < response.data.length
          $('#customerList').append '<option value=\'' + response.data[i] + '\'></option>'
          i++
    )

  $('#new-complaint-form').submit (e) ->
    e.preventDefault()
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    ips_urls = this.ips_urls.value
    desc = this.description.value
    customer = this.customers.value
    tags = $('.selectized').val()

    $.ajax(
      url: '/api/v1/escalations/webcat/complaints'
      method: 'POST'
      headers: headers
      data:
        ips_urls: ips_urls,
        description: desc,
        customer: customer,
        tags: tags
      success: (response) ->
        std_msg_success('Complaint Created.', [], reload: true)
      error: (response) ->
        std_api_error(response, "Complaint was not created.", reload: false)
    )


  createSelectOptions = ->
    tags = $('#complaint_tag_list')[0]
    if tags
      tag_list = tags.value
      array = tag_list.split(',')
      options = []
      for x in array
        options.push {name: x}
      return options

  $('#select-to-new').selectize {
    persist: false,
    create: (input) ->
      {name: input}
    maxItmes: null
    valueField: 'name'
    labelField: 'name'
    searchField: 'name'
    options: createSelectOptions()

  }