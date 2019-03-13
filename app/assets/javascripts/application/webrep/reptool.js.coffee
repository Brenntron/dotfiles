################################################################################
# FUNCTIONS FOR POPULATING / SUBMITTING ETC REPTOOL INFORMATION
################################################################################



#### POPULATING CURRENT REPTOOL CLASSIFICATIONS ####

## Populating the inline Adjust Reptool button for research page and research tab (individual submission form)
window.get_current_reptool =(button, page) ->
  dropdown = $(button).parents('.dropdown')[0]
  submit_button = $(dropdown).find('.dropdown-submit-button')[0]
  entry_row = $(button).parents('.research-table-row')[0]
  entry = $(entry_row).find('.entry-data-content')
  entry_content = $(entry).text().trim()
  case_id = $('#dispute_id').text().trim()
  comment_trail = ''

  ## Clear out any residual data
  # Empty table
  tbody = $(dropdown).find('table.dispute_tool_current').find('tbody')
  $(tbody).empty()
  # Empty the comment box
  comment_box = $(dropdown).find('.comment-input')
  comment_box.val('')

  if page == "show"
    comment_trail = '\n \n------------------------------- \nINDIVIDUAL SUBMISSION: \n #' + case_id + ' - ' + entry_content
  else if page == "research"
    comment_trail = '\n \n------------------------------- \nINDIVIDUAL RESEARCH SUBMISSION: \n' + entry_content

  # Send entry content to reptool
  data = {
    'entry': entry_content
  }
  std_msg_ajax(
    url: '/escalations/api/v1/escalations/webrep/disputes/bulk_reptool_get_info_for_form'
    method: 'POST'
    data: { ip_uris: entry_content }
    success: (response) ->
      response = JSON.parse(response)
      entry = response[0]
      if entry.status == "ACTIVE"
        rep_class = entry.classification.join(', ')
      else
        rep_class = '<span class="missing-data">No active classifications</span>'
      tbody.append('<tr class="reptool-entry-row" data-case-id="' + 'case_id' + '"><td class="reptool-entry-class">' + rep_class + '</td><td class="reptool-entry-expiration">' + entry['expiration'] + '</td><td class="reptool-entry-comment">' + entry['comment'] + '</td></tr>')
      comment_box.val(comment_trail)

    error: (response) ->
      std_api_error(response, "Error retrieving Reptool Data", reload: false)
  )


##  Populating the toolbar Adjust RepTool BL dropdown (bulk submission form)
window.bulk_get_current_reptool = (page) ->
# Define the variables based on the page
  if page == "show"
    checkbox = $('.dispute_check_box:checked')
    case_id = $('#dispute_id').text()
  else if page == "research"
    checkbox = $('.dispute_check_box:checked')
    case_id = ''
  else if page == "index"
    checkbox = $('.dispute-entry-checkbox:checked')
    case_id = []

  ## Clear out any residual data
  # Empty table
  tbody = $('#reptool_adjust_entries').find('table.dispute_tool_current').find('tbody')
  tbody.empty()
  # Empty the comment box
  comment_box = $('#reptool_adjust_entries').find('.comment-input')
  comment_box.val('')

  ## Get data to populate table
  # Get all the checked entry urls
  if ($(checkbox).length > 0)
    ip_uris = []
    comment_trail = ''
    comment_array = []
    $(checkbox).each ->
      if page == "show" || page == "research"
        entry_row = $(this).parents('.research-table-row')[0]
        entry_content = $(entry_row).find('.entry-data-content').text().trim()
      else if page == "index"
        entry_row = $(this).parents('.index-entry-row')[0]
        entry_content = $(entry_row).find('.entry-col-content').text().trim()
        entry_case_id = $(entry_row).attr('data-case-id')
        comment_array.push('#' + entry_case_id + ' - ' + entry_content)

      # Prep entry content to send to reptool
      ip_uris.push(entry_content)

    if page == "show"
      comment_trail = '\n \n------------------------------- \nBULK SUBMISSION: \n #' + case_id + ' - ' + ip_uris.join(', ')
    else if page == "research"
      comment_trail = '\n \n------------------------------- \nRESEARCH BULK SUBMISSION: \n' + ip_uris.join('\n')
    else if page == "index"
      comment_trail = '\n \n------------------------------- \nBULK SUBMISSION: \n' + comment_array.join('\n')

    std_msg_ajax(
      url: '/escalations/api/v1/escalations/webrep/disputes/bulk_reptool_get_info_for_form'
      method: 'POST'
      data: { ip_uris: ip_uris }
      success: (response) ->
        response = JSON.parse(response)

        for entry in response
          if entry['status'] == "ACTIVE"
            rep_class_full = entry['classification'] + ' - ' + entry['expiration']
            rep_class = entry['classification']
          else
            rep_class_full = '<span class="missing-data">No active classifications</span>'
            rep_class = ''

          tbody.append('<tr class="reptool-entry-row" data-case-id="' + case_id + '"><td class="reptool-entry-name">' + entry['entry'] + '</td><td class="reptool-entry-class" data-classification="' + rep_class + '">' + rep_class_full + '</td><td class="reptool-entry-comment">' + entry['comment'] + '</td></tr>')
        comment_box.val(comment_trail)

      error: (response) ->
        std_api_error(response, "Error retrieving Reptool Data", reload: false)
    )
  else
    std_msg_error('Error', ['Please select one row'])
    $(dropdown).removeClass('open')
    return false



#### FORM MANIPULATION ####

# Reptool form manipulation to hide and show needed elements / enable submission
window.reptool_form_prep = (action, submission_type) ->
  dropdown = $(action).parents('.dropdown')[0]
  reptool_submit = $(dropdown).find('.dropdown-submit-button')[0]
  class_actions_row = $(dropdown).find('.reptool-classifications-row')[0]
  classes_row = $(dropdown).find('.reptool-class-radio-row')[0]
  action_type = $(action).attr('name')

  if action_type == 'reptool-action-radio'
    submission_action = $(action).val()
    # Show relavent pieces of the form
    if submission_action == 'reptool-maintain'
      $(class_actions_row).show()
      $(classes_row).show()
    else if submission_action == 'reptool-override'
      $(class_actions_row).show()
      $(classes_row).hide()
    else if submission_action == 'reptool-drop'
      $(class_actions_row).hide()
      $(classes_row).hide()
      $(reptool_submit).attr('disabled', false)

  else if action_type = 'classification'
    if $(dropdown).find('.reptool-class-cb:checked').length > 0
      $(reptool_submit).attr('disabled', false)
    else
      $(reptool_submit).attr('disabled', true)



#### SUBMISSION TO REPTOOL ####

## Submit individual changes to Reptool (show and research page)
window.submit_individual_reptool = (button) ->
  # Get current info: entry content, current classes, and case id if there is one
  dropdown = $(button).parents('.dropdown')[0]
  entry_row = $(button).parents('.research-table-row')[0]
  entry = $(entry_row).find('.entry-data-content')
  entry_content = $(entry).text().trim()
  current_classes = $($(dropdown).find('.reptool-entry-class')[0]).text()
  case_id = $('#dispute_id').text().trim()

  # Get reptool submission action
  submission_action = $(dropdown).find("input[name='reptool-action-radio']:checked").val()

  checked_classes = []
  #  Get all checked classifications
  if $(dropdown).find('.reptool-class-cb:checked').length > 0
    $(dropdown).find('.reptool-class-cb:checked').each ->
      checked_classes.push($(this).val())
  # Convert to string for data submission
  reptool_classes = checked_classes.join(', ')

  classification_action = $($(dropdown).find("input[name='reptool-classes-radio']:checked")).val()
  comment = $($(dropdown).find('.dropdown-comment')).val()

  # If user wants to override existing classes we only need what they've checked
  if submission_action == "reptool-override"
    api_url = '/escalations/api/v1/escalations/webrep/disputes/reptool_bl'
    success = 'The following RepTool classes have been are assigned to: ' + entry_content
    data = {
      'action': 'ACTIVE'
      'entries': entry_content
      'classifications': checked_classes.join(',')
      'comment': comment
    }
  else if submission_action == "reptool-drop"
    api_url = '/escalations/api/v1/escalations/webrep/disputes/drop_reptool_bl'
    success = 'All RepTool classes have been removed from: ' + entry_content
    data = {
      'action': 'EXPIRED'
      'entries': entry_content
      'comment': comment
    }
  else if submission_action == "reptool-maintain"
    api_url = '/escalations/api/v1/escalations/webrep/disputes/maintain_reptool_bl'
    fin_classes = []
    # Put current classes into an array (if there are any)
    if current_classes != "No active classifications"
      current_arry = current_classes.split(', ')
    else
      current_arry = []

    if classification_action == "add"
      # Checked classes plus current classes, make sure there aren't dupes
      if current_arry.length > 1
        $(current_arry).each ->
          checked_classes.push(this)
      else
        checked_classes.push(current_arry[0])

      fin_classes = checked_classes.filter(((a) ->
        if !@[a]
          @[a] = 1
          return a
        return
      ), {})
      success = 'The following RepTool classifications have been added to: ' + entry_content
    else # classification action == 'remove'
      # Subtract checked classes from current classes
      fin_classes = current_arry.filter((a) ->
        !checked_classes.includes(a)
      )
      success = 'The following RepTool classes have been removed from: ' + entry_content
    data = {
      'data': [{
        'action': 'ACTIVE'
        'entries': [entry_content]
        'classifications': [fin_classes.join(',')]
        'comment': comment
      }]
    }
  # Send to RepTool!
  std_msg_ajax(
    url: api_url
    method: 'POST'
    data: data
    success: (response) ->
      std_msg_success(success, [reptool_classes])
    error: (response) ->
      if response.responseJSON == undefined
        response_lines = response.responseText.split("\n")
        if 2 < response_lines.length
          errormsg = [response_lines[0], response_lines[1]]
        else
          errormsg = [response.responseText]
      else if response.responseJSON.error != undefined
        errormsg = [response.responseJSON.error]
      else
        errormsg = [response.responseText]
      std_msg_error('Error', ['Error adjusting RepTool classes'].concat(errormsg) )
  )


## TODO - Consolidate this code a bit
## Submit Bulk changes to Reptool
window.submit_bulk_reptool = () ->
  bulk_reptool_menu = $('#reptool_adjust_entries')
  submission_action = $(bulk_reptool_menu).find("input[name='reptool-action-radio']:checked").val()

  checked_classes = []
  #  Get all checked classifications
  if $(bulk_reptool_menu).find('.reptool-class-cb:checked').length > 0
    $(bulk_reptool_menu).find('.reptool-class-cb:checked').each ->
      checked_classes.push($(this).val())
  # Convert to string for data submission
  reptool_classes = checked_classes.join()

  classification_action = $(bulk_reptool_menu).find("input[name='reptool-classes-radio']:checked").val()
  comment = bulk_reptool_menu.find('.dropdown-comment').val()

  #  Get the entries
  entry_rows = $(bulk_reptool_menu).find('.reptool-entry-row')
  entries = []
  current_entries_and_classes = []
  $(entry_rows).each ->
    entry = $(this).find('.reptool-entry-name')[0]
    entries.push($(entry).text())
    current_classes = $($(this).find('.reptool-entry-class')[0]).attr('data-classification')
    current_entries_and_classes.push {
      'entry': $(entry).text()
      'classifications': current_classes
    }

  # If user wants to override existing classes we only need what they've checked
  if submission_action == "reptool-override"
    data = {
      'action': 'ACTIVE'
      'entries': entries
      'classifications': reptool_classes
      'comment': comment
    }
  else if submission_action == "reptool-drop"
    data = {
      'action': 'EXPIRED'
      'entries': entries
      'comment': comment
    }
  else if submission_action == "reptool-maintain"
    new_classifications = ''
    array_of_datas = []
    if classification_action == 'add'
      $(current_entries_and_classes).each ->
        if this.classifications.length > 0
          new_classifications = this.classifications
          new_classifications = new_classifications + ',' + reptool_classes

          #          Not sure this piece is taking into account potential duplicate classes.
          #          need to confirm
          temp_data = {
            'action': 'ACTIVE'
            'entries': [this.entry]
            'classifications': [new_classifications]
            'comment': comment
          }
          array_of_datas.push(temp_data)
        else
          new_classifications = reptool_classes

          temp_data = {
            'action': 'ACTIVE'
            'entries': [this.entry]
            'classifications': [new_classifications]
            'comment': comment
          }
          array_of_datas.push(temp_data)

        data = array_of_datas
    else
      $(current_entries_and_classes).each ->
        current = this.classifications.split(',')
        subtracted = current.filter((x) ->
          checked_classes.indexOf(x) < 0
        )
        new_classifications = subtracted.join()

        if new_classifications.length > 0
          temp_data = {
            'action': 'ACTIVE'
            'entries': [this.entry]
            'classifications': [new_classifications]
            'comment': comment
          }
          array_of_datas.push(temp_data)
          data = array_of_datas
        else
          submission_action == "reptool-drop"

          temp_data = {
            'action': 'expired'
            'entries': [this.entry]
          }
          array_of_datas.push(temp_data)
          data = array_of_datas

  # send separate api calls for each type of submission
  if submission_action == "reptool-override"
    std_msg_ajax(
      url: '/escalations/api/v1/escalations/webrep/disputes/reptool_bl'
      method: 'POST'
      data: data
      success: (response) ->
        std_msg_success('These RepTool classes (' + reptool_classes + ') are assigned to the following entries:', [entries])
      error: (response) ->
        if response.responseJSON == undefined
          response_lines = response.responseText.split("\n")
          if 2 < response_lines.length
            errormsg = [response_lines[0], response_lines[1]]
          else
            errormsg = [response.responseText]
        else if response.responseJSON.error != undefined
          errormsg = [response.responseJSON.error]
        else
          errormsg = [response.responseText]
        std_msg_error('Error', ['Error adjusting WL/BL'].concat(errormsg) )
    )
  else if submission_action == "reptool-maintain"
    std_msg_ajax(
      url: '/escalations/api/v1/escalations/webrep/disputes/maintain_reptool_bl'
      method: 'POST'
      data: {data: data}
      success: (response) ->
        std_msg_success('These RepTool classes (' + reptool_classes + ') were changed on the following entries:', [entries])
      error: (response) ->
        if response.responseJSON == undefined
          response_lines = response.responseText.split("\n")
          if 2 < response_lines.length
            errormsg = [response_lines[0], response_lines[1]]
          else
            errormsg = [response.responseText]
        else if response.responseJSON.error != undefined
          errormsg = [response.responseJSON.error]
        else
          errormsg = [response.responseText]
        std_msg_error('Error', ['Error adjusting WL/BL'].concat(errormsg) )
    )
  else if submission_action == "reptool-drop"
    std_msg_ajax(
      url: '/escalations/api/v1/escalations/webrep/disputes/drop_reptool_bl'
      method: 'POST'
      data: data
      success: (response) ->
        std_msg_success('All RepTool classes have been removed from the following entries:', [entries])
      error: (response) ->
        if response.responseJSON == undefined
          response_lines = response.responseText.split("\n")
          if 2 < response_lines.length
            errormsg = [response_lines[0], response_lines[1]]
          else
            errormsg = [response.responseText]
        else if response.responseJSON.error != undefined
          errormsg = [response.responseJSON.error]
        else
          errormsg = [response.responseText]
        std_msg_error('Error', ['Error adjusting WL/BL'].concat(errormsg) )
    )
