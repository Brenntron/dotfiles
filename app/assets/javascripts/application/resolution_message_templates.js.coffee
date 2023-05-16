$ ->
  ## Manage Resolution Message Templates

  $('#resolution-message-templates-table').DataTable(
    order: [[ 1, "asc" ]]
    paging: false
    info: false
    searching: false
    autoWidth: false
    columnDefs: [
      { targets: [0], orderable: false }
      { targets: [-1], orderable: false }
    ]
    language:
      emptyTable: "<p class='empty-table-message'>No resolution templates have been created.</p>"
  )

  $('#createResolutionMessageTemplatesDialog').dialog
    autoOpen: false
    minWidth: 450
    maxWidth: 1000
    position: { my: "left center", at: "left center", of: window }

  $('#editResolutionMessageTemplatesDialog').dialog
    autoOpen: false
    minWidth: 450
    maxWidth: 1000
    position: { my: "left center", at: "left center", of: window }

  window.manage_resolution_message_templates = () ->
    $('#createResolutionMessageTemplatesDialog').dialog 'open'

  window.close_resolution_template_dialog = () ->
    $('#createResolutionMessageTemplatesDialog').dialog 'close'
    $('#editResolutionMessageTemplatesDialog').dialog 'close'

  window.get_resolution_template_data = (action)->
    name: $(".#{action} input[name=name]").val()
    resolution_type:  $(".#{action} select[name=resolution_type]").val();
    description: $(".#{action} textarea[name=description]").val();
    body: $(".#{action} textarea[name=body]").val();
    ticket_type: $(".resolution-message-template-form").attr('data-ticket-type');

  # Create new resolution message template
  window.create_resolution_message_template = (type) ->
    std_msg_ajax(
      method: 'POST'
      url: "/escalations/api/v1/escalations/#{type}/resolution_message_templates"
      data: get_resolution_template_data('create')
      success_reload: false
      success: (response) ->
        std_msg_success('Resolution Message template Created.', [], reload: true)
      error: (response) ->
        std_api_error(response, "There was an error creating the resolution message template.", reload: false)
    )

  get_and_populate_resolved_message = (template_id, is_footer)->
    std_msg_ajax(
      method: 'GET'
      url: "/escalations/api/v1/escalations/webrep/resolution_message_templates/#{template_id}"
      success_reload: false
      success: (response) ->
        $(".update select[name=resolution_type]").val(response.resolution_type)
        $(".update .resolution-template-resolution-type").text(response.resolution_type)
        $(".update input[name=name]").val(response.name);
        $(".update .resolution-template-name").text(response.name);
        $(".update .resolution-template-description").html(response.description);
        $(".update .resolution-template-message").html(response.body);

        #do not show resolution type select when editing footer
        if is_footer?
          $('#editResolutionMessageTemplatesDialog select').addClass('hide-temporarily')
          $('#editResolutionMessageTemplatesDialog .resolution-template-footer-text').removeClass('hide')
        else
          $('#editResolutionMessageTemplatesDialog select').removeClass('hide-temporarily')
          $('#editResolutionMessageTemplatesDialog .resolution-template-footer-text').addClass('hide')

        $('#editResolutionMessageTemplatesDialog').dialog 'open'

      error: (response) ->
        std_api_error(response, "There was a problem retrieving resolution message template.", reload: false)
    )


  # Edit a resolution message template (fetch existing data and populate form)
  $('.edit-resolution-message-template').on 'click', (event)->
    $('#createResolutionMessageTemplatesDialog').dialog 'close'
    template_id = $(this).attr('data-resolution-message-template-id')
    $('.update input[name=template-id]').val(template_id)

    is_footer = $(this).attr('data-is-footer')
    get_and_populate_resolved_message(template_id, is_footer)


  # Update resolution message template
  window.update_resolved_resolution_message_template = (type) ->
    template_id = $('.update input[name=template-id]').val();
    std_msg_ajax(
      method: 'PUT'
      url: "/escalations/api/v1/escalations/#{type}/resolution_message_templates/#{template_id}"
      data: get_resolution_template_data('update')
      success_reload: true
      success: (response) ->
        std_msg_success('Resolution Message Template Updated.', [], reload: true)
        $('#editResolutionMessageTemplatesDialog').dialog 'close'
      error: (response) ->
        std_api_error(response, "There was an error updating the resolution message template.", reload: false)
    )

  # Delete resolution message template
  $('.manage-response-delete-icon').on 'click', ->
    ticket_type = $('.resolution-message-template-form').attr('data-ticket-type')
    path = 'webrep' #using this as default, it works with any path technically
    switch ticket_type
      when 'Dispute'
       path = 'webrep'
      when 'FileReputationDispute'
        path = 'file_rep'
      when 'SenderDomainReputationDispute'
        path = 'sdr'

    template_id = $(this).attr('data-resolution-message-template-id')
    std_msg_confirm(
      'Are you sure you want to delete this template?',
      [],
      {
        confirm_dismiss: false,
        confirm: ->
          std_msg_ajax(
            method: 'DELETE'
            url: "/escalations/api/v1/escalations/#{path}/resolution_message_templates/#{template_id}"
            success_reload: true
            success: (response) ->
              std_msg_success('Resolution message template deleted.', [], reload: true)
            error: (response) ->
              std_api_error(response, "Resolution message template could not be deleted.", reload: false)
          )
      })

  # Submit button disable/enable for new resolution template form
  $('.resolution-message-template-form').on 'keyup', ->
    name_input = $(".create input[name=name]").val();
    message_input = $(".create textarea[name=body]").val();
    if name_input && message_input != ''
      $('#create-resolution-template-submit').attr('disabled', false)
    else
      $('#create-resolution-template-submit').attr('disabled', true)

  # Tooltips for Manage Resolution Templates table
  tooltip_delay = 400
  manage_resolution_templates_table = $('#resolution-message-templates-table')

  manage_resolution_templates_table.delegate '.edit-resolution-message-template:not(.tooltipstered)', 'mouseenter', (e) ->
    target = $(this)
    target.tooltipster
      debug: false
      interactive: true
      content: $(this).prop('title')
      trigger: 'hover'
      theme: ['tooltipster-default', 'tooltipster-default-customized']

    #set interval so that each new tooltip is only displayed after half a second of hovering
    setInterval ->
      if target.is(':hover')
        target.tooltipster('open')
    , tooltip_delay

  manage_resolution_templates_table.delegate '.manage-response-delete-icon:not(.tooltipstered)', 'mouseenter', (e) ->
    target = $(this)
    target.tooltipster
      debug: false
      interactive: true
      content: $(this).prop('title')
      trigger: 'hover'
      theme: ['tooltipster-default', 'tooltipster-default-customized']

    #set interval so that each new tooltip is only displayed after half a second of hovering
    setInterval ->
      if target.is(':hover')
        target.tooltipster('open')
    , tooltip_delay

  ## Resolution Picker Dropdown ##

  $('#select-new-resolution-message-template-status').on 'change', ->
    template_id = this.value

    std_msg_ajax(
      method: 'GET'
      url: "/escalations/api/v1/escalations/webrep/resolution_message_templates/#{template_id}"
      success_reload: false
      success: (response) ->
        $('.ticket-status-comment').val(response.body)
      error: (response) ->
        std_api_error(response, "There was a problem retrieving resolution message template.", reload: false)
    )

  $('#select-new-resolution-message-template-resolution').on 'change', ->
    template_id = this.value

    std_msg_ajax(
      method: 'GET'
      url: "/escalations/api/v1/escalations/webrep/resolution_message_templates/#{template_id}"
      success_reload: false
      success: (response) ->
        $('.ticket-resolution-comment').val(response.body)
      error: (response) ->
        std_api_error(response, "There was a problem retrieving resolution message template.", reload: false)
    )

  #Fetch resolutions by resolution, for use in template selects
  window.get_resolution_templates_by_resolution = (route, resolution, ticket_type) ->

    if route == 'webrep' #show if web or email ticket for webrep
      data = {resolution: resolution, ticket_type: ticket_type}
    else
      data = {resolution: resolution}

    std_msg_ajax(
      method: 'GET'
      url: "/escalations/api/v1/escalations/#{route}/resolution_message_templates"
      data: data
      dataType: 'json'
      success_reload: false
      success: (response) ->
        response
      error: (response) ->
        std_api_error(response, "There was an error fetching the resolution message templates", reload: false)
    )

  # Change resolution template select - Tickets
  $('.resolution-message-template-select').on 'change', (i, e) ->
    comment = $('.resolution-message-template-select option:selected').attr('data-body')
    $('.ticket-resolution-comment').val comment
    description = $('.resolution-message-template-select option:selected').attr('data-description')
    $('.ticket-resolution-description').text description

  # Change resolution template select - Entries
  $('.entry-resolution-message-template-select').on 'change', (i, e) ->
    comment = $('.entry-resolution-message-template-select option:selected').attr('data-body')
    $('.entry-status-comment').val comment
    description = $('.entry-resolution-message-template-select option:selected').attr('data-description')
    $('.entry-resolution-description').text description

  ## Webrep specific ##

  window.create_webrep_resolution_message_template = (route) ->
    if $("input[name='dispute-type']:checked").val() == 'web'
      ticket_type = 'WebDispute'
      resolution_type = $(".create select[name=resolution_type_web]").val();
    else
      ticket_type = 'EmailDispute'
      resolution_type = $(".create select[name=resolution_type_email]").val();

    data = {
      name: $(".create input[name=name]").val()
      resolution_type: resolution_type
      description: $(".create textarea[name=description]").val()
      body: $(".create textarea[name=body]").val()
      ticket_type: ticket_type
    }

    std_msg_ajax(
      method: 'POST'
      url: "/escalations/api/v1/escalations/#{route}/resolution_message_templates"
      data: data
      success_reload: false
      success: (response) ->
        std_msg_success('Resolution Message template Created.', [], reload: true)
      error: (response) ->
        std_api_error(response, "There was an error creating the resolution message template.", reload: false)
    )

  window.get_webrep_resolution_template_data = (action, is_footer) ->
    if is_footer == true
      resolution_type = 'Customer Footer'
    else
      resolution_type = $(".#{action} select[name=resolution_type]").val()

    data = {
      name: $(".#{action} input[name=name]").val()
      resolution_type: resolution_type
      description: $(".#{action} textarea[name=description]").val()
      body: $(".#{action} textarea[name=body]").val()
      ticket_type: $(".resolution-message-template-form").attr('data-ticket-type')
    }
    return data

  window.update_webrep_resolved_resolution_message_template = (type) ->
    template_id = $('.update input[name=template-id]').val();
    is_footer = false
    #check if footer is being updated
    if !$(".resolution-template-footer-text").hasClass('hide')
      is_footer = true
    std_msg_ajax(
      method: 'PUT'
      url: "/escalations/api/v1/escalations/#{type}/resolution_message_templates/#{template_id}"
      data: get_webrep_resolution_template_data('update', is_footer)
      success_reload: true
      success: (response) ->
        std_msg_success('Resolution Message Template Updated.', [], reload: true)
        $('#editResolutionMessageTemplatesDialog').dialog 'close'
      error: (response) ->
        std_api_error(response, "There was an error updating the resolution message template.", reload: false)
    )

  get_and_populate_webrep_resolved_message = (template_id, template_type, is_footer)->
    std_msg_ajax(
      method: 'GET'
      url: "/escalations/api/v1/escalations/webrep/resolution_message_templates/#{template_id}"
      success_reload: false
      success: (response) ->
        $(".update select[name=resolution_type]").val(response.resolution_type)
        $(".update .resolution-template-resolution-type").text(response.resolution_type)
        $(".update input[name=name]").val(response.name);
        $(".update .resolution-template-name").text(response.name);
        $(".update .resolution-template-description").html(response.description);
        $(".update .resolution-template-message").html(response.body);

        #set current edit modal to current data-ticket-type (WebDispute or EmailDispute)
        $('#editResolutionMessageTemplatesDialog .resolution-message-template-form.update').attr('data-ticket-type', template_type)

        if is_footer?
          $('#editResolutionMessageTemplatesDialog select').addClass('hide-temporarily')
          $('#editResolutionMessageTemplatesDialog .resolution-template-footer-text').removeClass('hide')
        else
          $('#editResolutionMessageTemplatesDialog select').removeClass('hide-temporarily')
          $('#editResolutionMessageTemplatesDialog .resolution-template-footer-text').addClass('hide')

        $('#editResolutionMessageTemplatesDialog').dialog 'open'
      error: (response) ->
        std_api_error(response, "There was a problem retrieving resolution message template.", reload: false)
    )

  # Edit a webrep resolution message template (fetch existing data and populate form) - different function to check if web or email
  $('.edit-webrep-resolution-message-template').on 'click', (event)->
    $('#createResolutionMessageTemplatesDialog').dialog 'close'
    template_id = $(this).attr('data-resolution-message-template-id')
    $('.update input[name=template-id]').val(template_id)
    template_type = $(this).attr('data-ticket-type')
    is_footer = $(this).attr('data-is-footer')

    get_and_populate_webrep_resolved_message(template_id, template_type, is_footer)

  # Switch webrep form type
  $('#resolved-resolution-message-dialogue-form-information input[type=radio][name=dispute-type]').change (event)->
    if $(this).val() == 'email'
      $('.resolution-message-template-form.create').attr('data-ticket-type', 'EmailDispute')
    else
      $('.resolution-message-template-form.create').attr('data-ticket-type', 'WebDispute')

  $('#resolved-resolution-message-dialogue-form-information input[type=radio][name=dispute-type]').change (event)->
    if $(this).attr('id') == 'dispute-type-email'
      $('#create-form_resolution_type_web').addClass('hide')
      $('#create-form_resolution_type_email').removeClass('hide')
    else
      $('#create-form_resolution_type_web').removeClass('hide')
      $('#create-form_resolution_type_email').addClass('hide')
