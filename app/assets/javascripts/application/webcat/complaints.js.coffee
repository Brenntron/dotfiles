

init_tooltip = () ->
  $('.esc-tooltipped:not(.tooltipstered)').tooltipster
    theme: [
      'tooltipster-borderless'
      'tooltipster-borderless-customized'
    ]



# Store changes in local storage to see if Bulk Submit can be used
# call this when resolution is changed or a cat is added
window.store_entry_changes = (entry_id, type) ->
  if type == 'submit'
    changed = "webcat_entries_changed"
  else if type == 'review'
    changed = "webcat_entries_reviewed"

  changes = (sessionStorage.getItem(changed) || "")
  unless changes.includes(entry_id)
    entries = changes.split(",").filter((item) -> return item)
    entries.push(entry_id)
    new_changes = entries.join(",")
    sessionStorage.setItem(changed, new_changes)


# If user submits individual entry, remove it from the local storage changes
window.remove_entry_from_changes = (entry_id, type) ->
  if type == 'submit'
    changed = "webcat_entries_changed"
  else if type == 'review'
    changed = "webcat_entries_reviewed"

  changes = (sessionStorage.getItem(changed) || "")
  if changes.includes(entry_id)
    entries = changes.split(",").filter((item) -> return item)
    submitted_entry = entries.indexOf(entry_id)
    new_changes = entries.splice(submitted_entry, 1)
    sessionStorage.setItem(changed, new_changes)


getTouchedFormCount = ()->
  form_item = (sessionStorage.getItem("webcat_entries_changed") || "")
  form_item = form_item.split(",")
  form_item = form_item.filter((item) -> return item)
  return form_item.length


# Bulk webcat entry submit
# SCENARIOS:
# 1 - FIXED with new added or changed categories - correct
# 2 - FIXED with zero categories - wrong whether dropped or nothing added
# 3 - FIXED with category that was already there (should be unchanged then) - wrong
# 4 - UNCHANGED with zero categories - wrong, should fix or call invalid
# 5 - UNCHANGED with added categories - wrong, should be FIXED res
# 6 - INVALID with no categories - correct
# 7 - INVALID with added categories - wrong

window.bulk_submit_categorize_entries = () ->
  # grab what has been touched / stored in session
  changes = (sessionStorage.getItem("webcat_entries_changed")|| "" )
  if changes.split(',').length < 0
    return

  # disable the master submit button while processing
  $('#master-submit').prop('disabled', true)

  entries = changes.split(",").filter((item) -> return item)
  self_review = $('#self_review').is(':checked')

  entries_to_submit = []
  incomplete_entries = []
  submit_table = $('#complete-entries-table')
  incomplete_table = $('#incomplete-entries-table')

  $(entries).each ->
    entry_id = this
    entry_row = $('#' + entry_id)

    if $(entry_row).attr('data-categories') == ''
      curr_cats = ''
    else
      curr_cats = $(entry_row).attr('data-categories').split(',')

    if $(entry_row).attr('data-cat-ids') == ''
      curr_cat_ids = ''
    else
      curr_cat_ids = $(entry_row).attr('data-cat-ids').split(',')

    uri = $($(entry_row).find('.complaint-uri-input')[0]).val()
    status = $(entry_row).find('.resolution_radio_button:checked').val()
    comment = $(entry_row).find('textarea.internal-comment').val()
    user_action = ''
    # TODO add in resolution comments (currently in QA)

    if $('#input_cat_' + entry_id).val() != null
      cat_ids_array = $('#input_cat_' + entry_id).val()
      cat_ids = cat_ids_array.toString()
    else
      cat_ids = ''
      cat_ids_array = []

    # compare current categories to what user entered
    # check with webcat to see if they want more detailed confirmation panel
    if curr_cat_ids == ''
      curr_cat_count = 0
    else
      curr_cat_count = curr_cat_ids.length

    if cat_ids_array.length > curr_cat_count
      user_action = 'add'
    else if cat_ids_array.length < curr_cat_count
      user_action = 'remove'
    else
      # same number of cats, do they match?
      if cat_ids_array.sort().toString() == curr_cat_ids.sort().toString()
        user_action = 'none'
      else
        user_action = 'swap'

    category_name = $('#input_cat_' + entry_id).next('.selectize-control').find('.item')
    category_names_arr = []
    category_name.each ->
      category_names_arr.push($(this).text())
    category_names = category_names_arr.toString()

    table_row = '<tr><td class="entry-id-col">' + entry_id + '</td><td>' + uri + '</td><td>' + category_names_arr.join(', ') + '</td><td>' + status + '</td><td>' + user_action + '</td>'

    if (cat_ids.length == 0 && status == 'FIXED') || (user_action == 'none' && status == 'FIXED') || (status == 'UNCHANGED' && user_action != 'none') || (status == 'INVALID' && cat_ids.length != 0)
      $(incomplete_table).append(table_row)
      incomplete_entries.push(entry_id)
    else
      entries_to_submit.push({
        entry_id: entry_id,
        prefix: uri,
        categories: cat_ids,
        category_names: category_names,
        status: status,
        comment: comment,
  #      resolution_comment: resolution_comment,
        uri_as_categorized: uri,
        self_review: self_review
      })
      $(submit_table).append(table_row)

  if incomplete_entries.length == 0 && entries_to_submit.length == 0
    return
  else
    $('#bulk-submit-buttons').removeClass('hidden')
    if incomplete_entries.length > 0
      $('#incomplete-entries-wrapper').removeClass('hidden')
    if entries_to_submit.length > 0
      $('#complete-entries-wrapper').removeClass('hidden')

  # TODO - after UI testing, remove the action column from the tables, or hide
  # Populate confirmation dialog
  $('#bulk-submit-confirmation').modal('show')
  entries_to_submit = JSON.stringify(entries_to_submit)
  sessionStorage.setItem('webcat-entries-to-submit', entries_to_submit)


window.process_bulk_submission = () ->
  $('#incomplete-entries-wrapper').addClass('hidden')
  $('#complete-entries-wrapper').addClass('hidden')
  $('#bulk-submit-buttons').addClass('hidden')
  $('#bulk-submit-confirmation .loader-wrapper').removeClass('hidden')
  entries_to_submit = sessionStorage.getItem('webcat-entries-to-submit')
  data = JSON.parse(entries_to_submit)

  std_msg_ajax(
    method: 'POST'
    url: "/escalations/api/v1/escalations/webcat/complaint_entries/master_submit"
    data: {data: data}
    success: (response) ->
      #TODO - need to figure out partial success / fails w/ api calls
      json = JSON.parse(response)
      console.log json

      $('#bulk-submit-confirmation').modal('hide')
      $('#incomplete-entries-wrapper tbody').empty()
      $('#bulk-submit-confirmation .loader-wrapper').addClass('hidden')
      success_entries = []
      entries = $('#complete-entries-wrapper .entry-id-col')
      $(entries).each ->
        entry = $(this).text()
        success_entries.push(entry)

      # remove the entries that were successful from the touched entries
      sessionStorage.removeItem('webcat-entries-to-submit')
      changed = sessionStorage.getItem("webcat_entries_changed").split(',')
      remaining_to_change = changed.filter((x) ->
        success_entries.indexOf(x) < 0
      )
      sessionStorage.setItem("webcat_entries_changed", remaining_to_change)
      $('#complete-entries-wrapper tbody').empty()

      std_msg_success('Success',["All entries successfully processed."], reload: true)
    error: (response) ->
      console.log response
      $('#bulk-submit-confirmation').modal('hide')
      $('#bulk-submit-confirmation .loader-wrapper').addClass('hidden')
      msg = response.responseJSON.error
      std_msg_error('Error processing entries', [msg], reload: false)
)



window.webcat_reset_search = ()->
  inputs = document.getElementsByClassName('form-control')
  for i in inputs
    i.value = ""

  els = ['tags','assignee','category','company','status','resolution','name','complaint','channel','entryid','complaintid','jiraid','submitter-type','platform']
  for el in els
    selectize_el = $("##{el}-input")[0].selectize
    selectize_el.clear()



# Bulk submission of Pending (in review) entries
window.review_bulk_submit = () ->
  # grab what has been touched / stored in session
  changes = (sessionStorage.getItem("webcat_entries_reviewed")|| "" )
  if (changes.split(',').length < 0) || (changes == '')
    std_msg_error('No changes to submit', ['Select "Commit" or "Decline on at least 1 entry."'])

  entries = changes.split(",").filter((item) -> return item)
  self_review = $('#self_review').is(':checked')

  entries_to_update = []
  declined_entries = []
  approved_entries = []
  declined_table = $('#declined-entries-table')
  approved_table = $('#approved-entries-table')

  $(entries).each ->
    entry_id = this
    entry_row = $('#' + entry_id)
    uri = $($(entry_row).find('.complaint-uri-input')[0]).val()
    status = $(entry_row).find('.review_radio_button:checked').val()
    comment = $(entry_row).find('textarea.internal-comment').val()

    if $('#input_cat_' + entry_id).val() != null
      cat_ids_array = $('#input_cat_' + entry_id).val()
      cat_ids = cat_ids_array.toString()
    else
      cat_ids = ''
      cat_ids_array = []

    category_name = $('#input_cat_' + entry_id).next('.selectize-control').find('.item')
    category_names_arr = []
    category_name.each ->
      category_names_arr.push($(this).text())
    category_names = category_names_arr.toString()

    table_row = '<tr><td class="entry-id-col">' + entry_id + '</td><td>' + uri + '</td><td>' + category_names_arr.join(', ') + '</td>'

    if status == 'commit'
      $(approved_table).append(table_row)
      approved_entries.push(entry_id)
    else if status == 'decline'
      $(declined_table).append(table_row)
      declined_entries.push(entry_id)

    if status != "ignore"
      entries_to_update.push({
        id: entry_id,
        prefix: uri,
        commit: status,
#        status: resolution, #I dont see the old var in current dom??
        comment: comment,
#        resolution_comment: resolution_comment,
        categories: cat_ids,
        category_names: category_names,
        self_review: self_review
      })

  if entries_to_update.length > 0
    $('#bulk-submit-review-buttons').removeClass('hidden')
    if approved_entries.length > 0
      $('#approved-entries-wrapper').removeClass('hidden')
    if declined_entries.length > 0
      $('#declined-entries-wrapper').removeClass('hidden')

  $('#bulk-submit-review-confirmation').modal('show')
  entries_to_update = JSON.stringify(entries_to_update)
  sessionStorage.setItem('webcat-reviewed-entries-to-submit', entries_to_update)



window.process_bulk_reviews = () ->
  $('#bulk-submit-review-buttons').addClass('hidden')
  $('#approved-entries-wrapper').addClass('hidden')
  $('#declined-entries-wrapper').addClass('hidden')
  $('#bulk-submit-review-confirmation .loader-wrapper').removeClass('hidden')
  reviewed_entries =   sessionStorage.getItem('webcat-reviewed-entries-to-submit')
  data = JSON.parse(reviewed_entries)

  std_msg_ajax(
    url: '/escalations/api/v1/escalations/webcat/complaint_entries/update_pending'
    method: 'POST'
    data: {data: data}
    success: (response) ->
      #TODO - need to figure out partial success / fails
      json = JSON.parse(response)
      console.log json

      $('#bulk-submit-review-confirmation').modal('hide')

      sessionStorage.removeItem('webcat-reviewed-entries-to-submit')
      sessionStorage.removeItem('webcat_entries_reviewed')

      $('#approved-entries-wrapper tbody').empty()
      $('#declined-entries-wrapper tbody').empty()
      $('#bulk-submit-review-confirmation .loader-wrapper').addClass('hidden')

      std_msg_success('Success',["All reviewed entries successfully processed."], reload: true)

    error: (response) ->
      console.log response
      $('#bulk-submit-review-confirmation').modal('hide')
      $('#bulk-submit-review-confirmation .loader-wrapper').addClass('hidden')
      msg = response.responseJSON.error
      std_msg_error('Error processing reviewed entries', [msg], reload: false)
  , this)




## Allows analyst to set ticket status to reopened and allows them to interact
# with the submission form
window.reopenComplaint = (entry_id) ->
  # Redrawing the row redraws the whole datatable and removes the 'reopened' entry from the results
  # Faking the update on the front after success to avoid DT resetting
  std_msg_ajax(
    url: '/escalations/api/v1/escalations/webcat/complaint_entries/reopen_complaint_entry'
    method: 'POST'
    data: {'complaint_entry_id': entry_id}
    success: (response) ->
      debugger
    entry_row = $('#' + entry_id)

    $(entry_row).find('.state-row td').text('REOPENED')
    $(entry_row).find('.resolution_radio_button').each ->
      $(this).prop('disabled', false)
    $('#edit_uri_input_' + entry_id).removeAttr('disabled')

    # res comment when avail
    cat_input = $('#input_cat_' + entry_id)
    cat_input =   $('#input_cat_' + entry_id)[0].selectize
    cat_input.enable()

    comment_dropdown = $('#internal_comment_dropdown_' + entry_id)
    comment = $('#internal_comment_' + entry_id)
    if $(comment).text() != ''
      comment_text = $(comment).text()
    else
      comment_text = ''
    comment_input = '<textarea id="' + entry_id + '" placeholder="Internal note for choosing categories" class="intenral-comment">' + comment_text + '</textarea>'
    comment.remove()
    $(comment_dropdown).append(comment_input)

    button = $('#reopen_' + entry_id)
    $(button).attr('onclick', 'submit_changes(' + entry_id + ');')
    $(button).text('Submit')
    $(button).attr('id', 'submit_changes_' + entry_id)

    error: (response) ->
      console.log response
      std_msg_error(response,"", reload: false)
  )



selected_options = (category_names) ->
  options = []
  if category_names
    options = category_names.split(',')

    #splice together 'Conventions, Conferences and Trade Shows' due to extra comma
    if category_names.includes('Conferences and Trade Shows')
      $(options).each (i, category) ->
        if category == 'Conventions'
          options.splice(i, 1)
        else if category == ' Conferences and Trade Shows'
          i2 = i - 1
          options.splice(i2, 1, 'Conventions, Conferences and Trade Shows')
  return options




window.fetch_complaints = () ->
  std_msg_ajax(
    method: 'POST'
    url: '/escalations/api/v1/escalations/webcat/complaints/fetch'
    data: {}
    success_msg: 'Complaint updates requested from Talos-Intelligence.  Please refresh your page shortly.'
    error_prefix: 'Error fetching complaints.'
  )



#bulk submit old
# TODO - api error handling, below for reference temporarily
#processSubmitMaster = () ->
#  std_msg_ajax(
#    method: 'POST'
#    url: "/escalations/api/v1/escalations/webcat/complaint_entries/master_submit"
#    data: {data: data}
#    success: (response) ->
#      errors = false
##      api_errors = []

#      api_boiler_plate =  "The following entries could not be saved due to API errors: " + api_errors.toString() + "<br>"
#
#      error_msg = ''

#      if errors == true
#        std_msg_error(error_msg,"")
#      else
#      std_msg_error("Unable to submit changes for selected entries.","", reload: false)




# Checks if there have been changes on the page
# Enables the bulk submit button if there have been
window.verifyMasterSubmit = () ->
  changes = getTouchedFormCount()
  boolean = false
  if $(changes).length > 0
    boolean = true
  return boolean



window.updateResolutionDialog = (confirm) ->
#   { status } = row
#  if status == 'COMPLETED'
#    reopened = true
#    disabled = false
#  if  status == 'RESOLVED' || status == 'NEW' || status == 'ASSIGNED'|| status == 'REOPENED'
#    invalid_unchanged = true
#    disabled = false

  $('#complaint_entries_to_update').empty()
  resolution = $('#complaint_resolution')[0].value
  selected_rows = $('tr.selected')
  pending_msg = ''
  complaint_entries = []
  for row in selected_rows
    { id } = row
    status = $(row).find('.state-col').text()
    if status == 'PENDING'
      if pending_msg == ''
        pending_msg = "<div class='small pending-note'>*Entries with a PENDING status cannot be edited.<div>"
    else
      push_row = false
      if resolution == 'REOPENED' && status == 'COMPLETED'
        push_row = true

      if resolution == 'RESOLVED' || status == 'NEW' || status == 'ASSIGNED'|| status == 'REOPENED'
        if resolution == 'INVALID' || resolution == 'UNCHANGED'
          push_row = true

      if push_row
        $(row).addClass('filtered-row')
        complaint_entries.push(id)
        full_domain = ''
        domain = $(row).find("#domain_#{id}").attr('data-full')
        $('#complaint_entries_to_update').append("<tr><td><span class='res_id'>#{id} |</span> <span class='webcat-full-domain'>#{domain}</span></td></tr>")
  $('#resolution_dialog').modal("show")
  if selected_rows.length > 1
    html = "Set the following #{complaint_entries.length} entries to <span class='bold'>RESOLUTION</span> <span class='resolution-emp bold'>#{resolution}.</span>"
  else
    html = "Set the following entry to <span class='bold'>RESOLUTION</span> <span class='resolution-emp bold'>#{resolution}.</span>"
  html += pending_msg
  $('#resolution_text').html(html)

  tbody = $('#resolution_dialog').find('tbody')
  setTimeout ->
    if $('#complaint_entries_to_update').height() > 399
      $(tbody).addClass('scrollable-table')
      $('#resolution_text').css('padding-left', 0)
    else
      $('#resolution_text').css('padding-left', '7px')
  , 200

window.updateResolution = () ->
  resolution = $('#complaint_resolution')[0].value
  selected_rows = $('tr.selected.filtered-row')
  internal_comment = $('#internal_comment')[0].value
  customer_facing_comment = $('#customer_facing_comment')[0].value

  complaint_entries = []
  for row in selected_rows
    status = $(row).find('.state-col').text()
    if status != 'PENDING'
      complaint_entries.push(row.id)

  std_msg_ajax(
    method: 'POST'
    url: "/escalations/api/v1/escalations/webcat/complaint_entries/update_resolution"
    data: {'complaint_entries': complaint_entries, 'resolution': resolution, 'internal_comment': internal_comment, 'customer_facing_comment': customer_facing_comment}
    success_reload: true
    success: (response) ->
      $('#resolution_dialog').modal('hide')
      data = JSON.parse(response)
      resolution = data[0].resolution
      modal_message = ""
      error = []
      success = []
      for entry in data
        { host, status, state} = entry
        if state == "ERROR"
          error_msg = "<li><span class='resolution-error-host'>#{host}</span> Cannot change entry with status of <span class='resolution-emp bold'>#{status}</span> to <span class='resolution-emp bold'>#{resolution}</span></li>"
          error.push(error_msg)
        else
          success.push(host)

      if success.length
        modal_message = "<div class='resolution-message'>Successfully updated <span class='bold'>RESOLUTION</span> to <span class='resolution-emp bold'>#{resolution}</span> for #{success.length} Complaint Entries</div>"
        if !error.length
          std_msg_success("All entries were successfully updated.", [modal_message], reload: true)
      if error.length
        error_list = error.join('')

        modal_message += "<div class='resolution-message'>Error updating the  following #{error.length} Complaint Entries:</div> <ul class='update-resolution-entries'>#{error_list}</ul>"
        std_msg_error("Error updating resolutions.", [modal_message], reload: true)
        setTimeout ->
          if $('.update-resolution-entries').height() > 300
            $('.update-resolution-entries').addClass('scrollable-list')
        ,200
      # Determine whether to render a success or error modal accordingly

  )

$ ->



  # If resolution is changed (to unchanged or invalid) enable the bulk submit button
  $(document).on 'change', '.resolution_radio_button', ->
    id = this.name.split("resolution")[1]
    store_entry_changes(id, 'submit')
    $('#master-submit').removeAttr('disabled')


  $(document).on 'change', '.review_radio_button', ->
    id = this.name.split("resolution_review")[1]
    res = $('input[name="resolution_review' + id + '"').val()
    if res != 'ignore'
      $('#submit_changes_' + id).removeAttr('disabled')
      store_entry_changes(id, 'review')
    else
      $('#submit_changes_' + id).attr('disabled', 'true')



  # TODO - is this needed?
  $(document).ready ->
    if !window.location.pathname.includes('/escalations/webcat')
      $('#filter-complaints-nav').hide()
      $('#fetch').hide()
      $('#complaints-nav-search-wrapper').hide()
      $('#new-complaint-nav-wrapper').hide()
    else
      $('#filter-complaints').show()
      $('#fetch').show()
      $('#complaints-nav-search-wrapper').show()
      $('#new-complaint-nav-wrapper').show()

  # If a stupidly long email address is returned it will wrap
  # rather than pushing the column into the column beside it
  $('.email-row').find('.case-history-author').each ->
    if $(this).text().length > 28
      $(this).addClass('break-word')
