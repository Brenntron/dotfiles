################################################################################
# FUNCTIONS FOR POPULATING, SUBMITTING, ETC. REPTOOL INFORMATION
################################################################################



#### POPULATING CURRENT REPTOOL CLASSIFICATIONS ####

## Populating the inline Adjust Reptool dropdown for
## research page and research tab (individual submission form)
$(document).ready ->
  $('.webrep_auto_resolve').each ->
    $(this).dialog({autoOpen : false, width: 500});

window.show_webrep_auto_resolve = (entry) ->
  dialog = $('#webrep_auto_resolve-' + entry)
  dialog.dialog('open')

window.get_current_reptool =(button, page) ->
  dropdown = $(button).parents('.dropdown')[0]
  submit_button = $(dropdown).find('.dropdown-submit-button')[0]
  entry_row = $(button).parents('.research-table-row')[0]
  entry = $(entry_row).find('.entry-data-content')
  entry_content = $(entry).text().trim()   # entry_content is simply the URL in this row, this is working
  case_id = $('#dispute_id').text().trim()
  comment_trail = ''

  ## Clear out any residual data
  # Empty table
  tbody = $(dropdown).find('table.dispute_tool_current').find('tbody')
  $(tbody).empty()
  # Find the comment div inside this dropdown
  comment_box = $(dropdown).find('.reptool-generated-comment')

  # Can leave the \n's, they will get replaced with spaces on submission to Reptool
  if page == "show"
    comment_trail = 'AC INDIVIDUAL SUBMISSION: \n TE.ACE-' + case_id
  else if page == "research"
    comment_trail = 'AC INDIVIDUAL RESEARCH SUBMISSION: \n' + entry_content

  # ensure ip_uris is valid for the endpoint, it is just the URL for this row
  ip_uris = entry_content

  # Send entry content to reptool
  data = {
    'entry': entry_content
  }

  std_msg_ajax(
    url: '/escalations/api/v1/escalations/webrep/disputes/bulk_reptool_get_info_for_form'
    method: 'POST'
    data: { ip_uris: [entry_content] }
    success: (response) ->
      response = JSON.parse(response)
      entry = response[0]
      if entry.status == "ACTIVE"
        rep_class = entry.classification.join(', ')
      else
        rep_class = '<span class="missing-data">No active classifications</span>'

      full_comment = entry['comment']
      full_comment = full_comment.replace(': ,', ':')  # one-off string fix

      # ellipsis-trick the reptool dropdown comment
      if full_comment.length > 80
        truncated_comment = full_comment.substring(0, 80) + '...'
        full_comment = '<span title="' + full_comment + '">' + truncated_comment + '</span>'

      tbody.append('<tr class="reptool-entry-row" data-case-id="' + 'case_id' + '"><td class="reptool-entry-class">' + rep_class + '</td><td class="reptool-entry-expiration">' + entry['expiration'] + '</td><td class="reptool-entry-comment">' + full_comment + '</td></tr>')

      $(comment_box).html(comment_trail)  # put the auto-generated comment into the read-only div

    error: (response) ->
      std_api_error(response, "Error retrieving Reptool Data", reload: false)
  )


##  Populating the toolbar Adjust RepTool BL dropdown
## (bulk submission form) - works on index, research page, and show page
window.bulk_get_current_reptool = (page) ->
  # Define the variables based on the page
  if page == "show" || page == "research"
    checkbox = $('.dispute_check_box:checked')
  else if page == "index"
    checkbox = $('.dispute-entry-checkbox:checked')

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
    closed_status = false
    entry_status = ''
    entry_case_id = ''
    $(checkbox).each ->
      if page == "show" || page == "research"
        entry_row = $(this).parents('.research-table-row')[0]
        entry_content = $(entry_row).find('.entry-data-content').text().trim()
        # Note - status and id do not exist on BFRP
        entry_status = $(entry_row).find('.entry-data-status').text().trim()
        entry_case_id = $('#dispute_id').text()
      else if page == "index"
        entry_row = $(this).parents('.index-entry-row')[0]
        entry_content = $(entry_row).find('.entry-col-content').text().trim()
        entry_status = $(entry_row).find('.entry-col-status').text().trim()
        entry_case_id = $(entry_row).attr('data-case-id')

      # Prep entry content to send to reptool
      ip_uris.push(entry_content)

    entry_comment = 'TE.ACE-' + entry_case_id
    if comment_array.indexOf(entry_comment) == -1
      comment_array.push(entry_comment)

    if page == "show"
      comment_trail = 'AC INDIVIDUAL SUBMISSION: \n' + comment_array.join('\n')
    else if page == "research"
      comment_trail = 'AC Research Bulk Submission: \n' + ip_uris.join('\n')
    else if page == "index"
      comment_trail = 'AC Bulk Submission: \n' + comment_array.join('\n')

    if entry_status ==  "RESOLVED_CLOSED"
      closed_status = true

    if closed_status
      std_msg_error('Error', ['Please reopen dispute before adjusting reptool.'])
    else
      #TODO - back end is accepting multiple entries but only returning one here
      std_msg_ajax(
        url: '/escalations/api/v1/escalations/webrep/disputes/bulk_reptool_get_info_for_form'
        method: 'POST'
        data: { ip_uris: ip_uris }
        success: (response) ->
          response = JSON.parse(response)

          for entry in response
            if entry.status == "ACTIVE"
              rep_entry = entry.entry
              rep_class_exp = entry.expiration
              rep_class_list = entry.classification
              rep_class_td_content = rep_class_list.join(', ')
              comment = entry.comment
            else
              rep_entry = entry.entry
              rep_class_exp = ''
              rep_class_list = ''
              rep_class_td_content = '<span class="missing-data">No active classifications</span>'
              comment = ''

            entry_row =
              '<tr class="reptool-entry-row" data-case-id="' + entry_case_id + '">' +
                '<td class="reptool-entry-name">' + rep_entry + '</td>' +
                '<td class="reptool-entry-class" data-classification="' + rep_class_list + '">' + rep_class_td_content + '</td>' +
                '<td>' + rep_class_exp + '</td>' +
                '<td class="reptool-entry-comment" id="'+ rep_entry + '_comment">' + comment + '</td>' +
              '</tr>'
            tbody.append(entry_row)

            if comment.length > 50
              comment_cell = $(document.getElementById(rep_entry + '_comment'))
              comment_cell.text(comment.substring(0, 50) + '...')
              comment_cell.addClass('esc-tooltipped')
              comment_cell.attr('title', comment)

            # put the auto-generated comment into the read-only div
            $('.reptool-generated-comment').html(comment_trail)
        error: (response) ->
          std_api_error(response, "Error retrieving Reptool Data", reload: false)
      )
  else
    std_msg_error('Error', ['Please select one row'])
    return false



#### FORM MANIPULATION ####

# Reptool form manipulation to hide and show needed elements /
# enable form submission
window.reptool_form_prep = (action, submission_type) ->
  dropdown = $(action).parents('.dropdown')[0]
  reptool_submit = $(dropdown).find('.dropdown-submit-button')[0]
  class_actions_row = $(dropdown).find('.reptool-classifications-row')[0]
  classes_row = $(dropdown).find('.reptool-class-radio-row')[0]
  comment_row = $(dropdown).find('.comment-wrapper')[0]
  action_type = $(action).attr('name')

  if action_type == 'reptool-action-radio'
    submission_action = $(action).val()
    # Show relavent pieces of the form
    if submission_action == 'reptool-maintain'
      $(class_actions_row).show()
      $(classes_row).show()
      $(comment_row).show()
    else if submission_action == 'reptool-override'
      $(class_actions_row).show()
      $(classes_row).hide()
      $(comment_row).show()
    else if submission_action == 'reptool-drop'
      $(class_actions_row).hide()
      $(classes_row).hide()
      $(comment_row).hide()
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
  force_check = $(dropdown).find('.reptool-toolbar-force:checked')
  if force_check.length > 0
    force_commit = true

  # Get reptool submission action
  submission_action = $(dropdown).find("input[name='reptool-action-radio']:checked").val()

  checked_classes = []
  #  Get all checked classifications
  if $(dropdown).find('.reptool-class-cb:checked').length > 0
    $(dropdown).find('.reptool-class-cb:checked').each ->
      checked_classes.push($(this).val())

  classification_action = $($(dropdown).find("input[name='reptool-classes-radio']:checked")).val()
  comm_typed_in = ''
  comm_generated = ''
  comment = ''

  # Comment reconstruction for Reptool, it needs a single-line format now w/o newlines
  # get the 'typed in' part of the comment from the dropdown for inline
  comm_typed_in = $(dropdown).find('.typed-in-comment-inline').val()  # get the 'typed in' part of the comment, textarea
  comm_typed_in = comm_typed_in.replace(/(\r\n|\n|\r)/gm, " ")  # replace newlines w/ spaces if there are any

  # get the 'auto-generated' part of the comment from the dropdown for inline
  comm_generated = $(dropdown).find('.reptool-generated-comment').text()
  comm_generated = comm_generated.replace(/(\r\n|\n|\r)/gm, ", ")  # replace newlines w/ commas
  comm_generated = comm_generated.replace(': ,', ':')  # one-off comment fix

  # if they typed anything as an additional comment above the auto-generated part, add it to the end
  if comm_typed_in.trim() != ''
    comment = "#{comm_generated} || Comment: #{comm_typed_in}"
  else
    comment = comm_generated

  # comment is now ready to send to Reptool
  console.clear()
  console.log comment
  # End: comment is now a single-line, and ready for Reptool now

  data = {}
  # If user wants to override existing classes we only need what they've checked
  if submission_action == "reptool-override"
    api_url = '/escalations/api/v1/escalations/webrep/disputes/reptool_bl'
    success = 'The following RepTool classes have been assigned to: <br/>' + entry_content
    reptool_classes = checked_classes.join(', ')

    data = {
      'action': 'ACTIVE'
      'entries': [entry_content]
      'classifications': checked_classes
      'comment': comment
      'force': force_commit
    }
  else if submission_action == "reptool-drop"
    api_url = '/escalations/api/v1/escalations/webrep/disputes/drop_reptool_bl'
    success = 'All RepTool classes have been removed from: <br/>' + entry_content
    reptool_classes = ''
    data = {
      'action': 'EXPIRED'
      'entries': [entry_content]
      'force': force_commit
    }

  else if submission_action == "reptool-maintain"
    # Put current classes into an array (if there are any)
    if current_classes != "No active classifications"
      current_arry = current_classes.split(', ')
    else
      current_arry = []

    fin_classes = []
    if classification_action == "add"
      api_url = '/escalations/api/v1/escalations/webrep/disputes/maintain_reptool_bl'
      # Checked classes plus current classes, make sure there aren't dupes
      fin_classes = current_arry.concat checked_classes.filter((item) ->
        current_arry.indexOf(item) == -1
      )
      success = 'The following RepTool classifications have been added to: <br/>' + entry_content
      reptool_classes = checked_classes.join(', ')

      data = {
        'data': [{
          'action': 'ACTIVE'
          'entries': [entry_content]
          'classifications': fin_classes
          'comment': comment
          'force': force_commit
        }]
      }

    else # classification action == 'remove'
      # Subtract checked classes from current classes
      fin_classes = current_arry.filter((a) ->
        !checked_classes.includes(a)
      )

      # User is removing all classes currently on entry
      if fin_classes.length < 1
        api_url = '/escalations/api/v1/escalations/webrep/disputes/drop_reptool_bl'
        success = 'All RepTool classes have been removed from: <br/>' + entry_content
        reptool_classes = ''
        data = {
          'action': 'EXPIRED'
          'entries': [entry_content]
          'force': force_commit
        }

      else
        api_url = '/escalations/api/v1/escalations/webrep/disputes/maintain_reptool_bl'
        success = 'The following RepTool classes have been removed from:<br/> ' + entry_content
        reptool_classes = checked_classes.join(', ')

        data = {
          'data': [{
            'action': 'ACTIVE'
            'entries': [entry_content]
            'classifications': fin_classes
            'comment': comment
            'force': force_commit
          }]
        }

  # Send to RepTool!
  std_msg_ajax(
    url: api_url
    method: 'POST'
    data: data
    success: (response) ->
      if reptool_classes == ''
        std_msg_success(success, [])
      else
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
## Submit Bulk changes to Reptool - toolbar dropdown form
## This works on index, research page, and research tab of show page
window.submit_bulk_reptool = () ->
  bulk_reptool_menu = $('#reptool_adjust_entries')   # this is the dropdown
  submission_action = $(bulk_reptool_menu).find("input[name='reptool-action-radio']:checked").val()

  checked_classes = []
  #  Get all checked classifications
  if $(bulk_reptool_menu).find('.reptool-class-cb:checked').length > 0
    $(bulk_reptool_menu).find('.reptool-class-cb:checked').each ->
      checked_classes.push($(this).val())

  classification_action = $(bulk_reptool_menu).find("input[name='reptool-classes-radio']:checked").val()
  comm_typed_in = ''
  comm_generated = ''
  comment = ''
  force_check = $(bulk_reptool_menu).find('.reptool-toolbar-force:checked')
  if force_check.length > 0
    force_commit = true

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

  # Comment reconstruction for Reptool, it needs a single-line format now without any newlines
  # get the 'typed in' part of the comment
  comm_typed_in = $(bulk_reptool_menu).find('.typed-in-comment-bulk').val()  # get the 'typed in' part of the comment, textarea
  comm_typed_in = comm_typed_in.replace(/(\r\n|\n|\r)/gm, " ")  # replace newlines w/ spaces

  # get the 'auto-generated' part of the comment
  comm_generated = $(bulk_reptool_menu).find('.reptool-generated-comment').text()
  comm_generated = comm_generated.replace(/(\r\n|\n|\r)/gm, ", ")  # replace newlines w/ commas
  comm_generated = comm_generated.replace(': ,', ':')  # one-off comment fix

  # if they typed anything as an additional comment (optional but they should), append it
  if comm_typed_in.trim() != ''
    comment = "#{comm_generated} || Comment: #{comm_typed_in}"
  else
    comment = comm_generated

  # comment is now ready to send to Reptool
  console.clear()
  console.log comment
  # End: comment is now a single-line, and ready for Reptool now

  data = {}
  # If user wants to override existing classes we only need what they've checked
  if submission_action == "reptool-override"
    api_url = '/escalations/api/v1/escalations/webrep/disputes/reptool_bl'
    success = 'The following RepTool classes have been assigned to: <br/>' + entries.join('<br/>')
    success_msg_arry = checked_classes
    data = {
      'action': 'ACTIVE'
      'entries': entries
      'classifications': checked_classes
      'comment': comment
      'force': force_commit
    }
  else if submission_action == "reptool-drop"
    api_url = '/escalations/api/v1/escalations/webrep/disputes/drop_reptool_bl'
    success = 'All RepTool classes have been removed from: '
    success_msg_arry = entries
    data = {
      'action': 'EXPIRED'
      'entries': entries
      'force': force_commit
    }
  else if submission_action == "reptool-maintain"
    api_url = '/escalations/api/v1/escalations/webrep/disputes/maintain_reptool_bl'
    array_of_datas = []

    if classification_action == 'add'
      success = 'The following RepTool classifications have been added:'
      success_msg_arry = []
      $(current_entries_and_classes).each ->
        # current_classes is a string from data-classifications attribute
        current_classes = this.classifications
        fin_classes = []

        if current_classes != ''
          if current_classes.includes(',')
            current_classes = current_classes.split(',')
          else
            current_classes = [current_classes]
          # Combine existing classes & checked classes to add to entry
          fin_classes = current_classes.concat checked_classes.filter((item) ->
            current_classes.indexOf(item) == -1
          )
        else
          # Only need new checked classes
          fin_classes = checked_classes

        entry_data = {
          'action': 'ACTIVE'
          'entries': [this.entry]
          'classifications': fin_classes
          'comment': comment
          'force': force_commit
        }
        array_of_datas.push(entry_data)
        succ_msg_entry = this.entry + ':<br/>' + checked_classes.join(', ')
        success_msg_arry.push(succ_msg_entry)
        data = array_of_datas

    else # classification action == 'remove'
      # Remove specific classes
      # There is an edge case where user can maintain -> remove ALL of the classes on ALL
      # selected entries and it will fail, but it's unlikely since they can use the 'Drop All' action instead.
      # Therefore not handling at this time.
      success = 'The following RepTool classes have been removed:'
      success_msg_arry = []
      $(current_entries_and_classes).each ->
        current_classes = this.classifications
        fin_classes = []

        if current_classes != ''
          if current_classes.includes(',')
            current_classes = current_classes.split(',')
          else
            current_classes = [current_classes]

          fin_classes = current_classes.filter((x) ->
            !checked_classes.includes(x)
          )
          entry_data = {
            'action': 'ACTIVE'
            'entries': [this.entry]
            'classifications': fin_classes
            'comment': comment
            'force': force_commit
          }
          array_of_datas.push(entry_data)
          succ_msg_entry = this.entry + ':<br/>' + checked_classes.join(', ')
          success_msg_arry.push(succ_msg_entry)
          data = array_of_datas
        else
          # entry has no current classes, nothing to remove
          # add entry info to response message
    console.log data

  # send separate api calls for each type of submission
  if submission_action == "reptool-override"
    std_msg_ajax(
      url: api_url
      method: 'POST'
      data: data
      success: (response) ->
        std_msg_success(success, success_msg_arry)
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
        std_msg_error('Error', ['Error adjusting Reptool classes'].concat(errormsg) )
    )
  else if submission_action == "reptool-maintain"

    std_msg_ajax(
      url: '/escalations/api/v1/escalations/webrep/disputes/maintain_reptool_bl'
      method: 'POST'
      data: {data: data}
      success: (response) ->
        std_msg_success(success, success_msg_arry)
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
        std_msg_error('Error', ['Error adjusting Reptool classes'].concat(errormsg) )
    )
  else if submission_action == "reptool-drop"
    std_msg_ajax(
      url: api_url
      method: 'POST'
      data: data
      success: (response) ->
        std_msg_success(success, entries)
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
        std_msg_error('Error', ['Error adjusting Reptool classes'].concat(errormsg) )
    )


# page-load on webrep show page or bfrp page, manage the reptool comments from growing too huge
$ ->
  # ellipsis-trick the reptool class table cell in research row
  if $('span.entry-reptool-comment').length > 0  # user is on a webrep show page or bfrp results page?
    $('span.entry-reptool-comment').each ->
      full = $(this).text().trim()
      if full.indexOf('Comment:') > 0  # this means a "real" comment was typed in, we don't need the auto-generated
        typed_in = full.split('Comment: ')[1]
        $(this).attr('title', typed_in)  # mouseover the text to see full comment
        if typed_in.length > 80   # if its huge, ellipsis-trick the comment
          typed_in = typed_in.substring(0, 80) + '...'
        $('.entry-reptool-comment').text(typed_in)
      else
        $(this).text('')  # leave empty

