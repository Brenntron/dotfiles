

init_tooltip = () ->
  $('.esc-tooltipped:not(.tooltipstered)').tooltipster
    theme: [
      'tooltipster-borderless'
      'tooltipster-borderless-customized'
    ]



# Below edge case I'm unsure of is removing a category and adding a new one,
# or adding and then removing the same one
# Consulting Adam on this one

# Store changes in local storage to see if Bulk Submit can be used
# call this when resolution is changed or a cat is added
window.store_entry_changes = (entry_id) ->
  changes = (sessionStorage.getItem("webcat_entries_changed") || "")
  unless changes.includes(entry_id)
    entries = changes.split(",").filter((item) -> return item)
    entries.push(entry_id)
    new_changes = entries.join(",")
    sessionStorage.setItem("webcat_entries_changed", new_changes)


# If user submits individual entry, remove it from the local storage changes
window.remove_entry_from_changes = (entry_id) ->
  changes = (sessionStorage.getItem("webcat_entries_changed") || "")
  if changes.includes(entry_id)
    entries = changes.split(",").filter((item) -> return item)
    submitted_entry = entries.indexOf(entry_id)
    new_changes = entries.splice(submitted_entry, 1)
    sessionStorage.setItem("webcat_entries_changed", new_changes)

getTouchedFormCount = ()->
  form_item = (sessionStorage.getItem("webcat_entries_changed") || "")
  form_item = form_item.split(",")
  form_item = form_item.filter((item) -> return item)
  return form_item.length

#NEW
# Bulk webcat entry submit
# TODO test when uri has been edited?
window.bulk_submit_categorize_entries = () ->
  debugger
  # grab what has been touched / stored in session
  changes = (sessionStorage.getItem("webcat_entries_changed")|| "" )
  if changes.split(',').length < 0
    return

  # disable the master submit button while processing
  $('#master-submit').prop('disabled', true)

  entries = changes.split(",").filter((item) -> return item)
  self_review = $('#self_review').is(':checked')

  # array if user tries to submit Fixed w/ no cats
  data = []
  incomplete_entries = []

  $(entries).each ->
    entry_row = $('#' + this)

    entry_id = this
    uri = $($(entry_row).find('.complaint-uri-input')[0]).val()
    status = $(entry_row).find('.resolution_radio_button:checked').val()
    comment = $(entry_row).find('textarea.internal-comment').val()
    # TODO add in resolution comments

    if $('#input_cat_' + entry_id).val() != null
      cat_ids = $('#input_cat_' + entry_id).val().toString()
    else
      cat_ids = null
    category_name = $('#input_cat_' + entry_id).next('.selectize-control').find('.item')
    category_names = []
    category_name.each ->
      category_names.push($(this).text())
    category_names = category_names.toString()

    if (cat_ids.length == 0) && status == 'FIXED'
      incomplete_entries.push(entry_id)
    else
      data.push({
        entry_id: entry_id,
        prefix: uri,
        categories: cat_ids,
        category_names: category_names
        status: status,
        comment: comment,
  #      resolution_comment: resolution_comment,
        uri_as_categorized: uri,
        self_review: self_review
      })

  # TODO - add confirmation modal
  std_msg_ajax(
    method: 'POST'
    url: "/escalations/api/v1/escalations/webcat/complaint_entries/master_submit"
    data: {data: data}
    success: (response) ->
      debugger
      json = JSON.parse(response)
      std_msg_success('Success',["All complaints successfully processed."], reload: true)
    error: (response) ->
      debugger
      console.log response
)




# TODO - fix this function
# Talk to Adam - maybe we allow them to do a refetch on cats if they edit the uRI?

# New layout does not save this separately from submitting the updates, need to rethink how this is done
# pretty sure this is not needed
#window.updateURI = (event, complaint_entry_id) ->
#  event.preventDefault()
#
#  uri = $("#complaint_prefix_#{complaint_entry_id}").val()
#
#  std_msg_ajax(
#    method: 'POST'
#    url: "/escalations/api/v1/escalations/webcat/complaints/update_uri"
#    data: {complaint_entry_id: complaint_entry_id, uri: uri }
#    success: (response) ->
#      {current_categories, category, wbrs_score, domain, subdomain, path, status} = response.json
#
#      if subdomain
#        qual_subdomain = subdomain + '.' + domain
#      else
#        qual_subdomain = domain
#
#      $(".simple-nested-table#entry-table-#{complaint_entry_id} tbody > tr").remove()
#
#      if 'ip' == status
#        std_msg_error("Cannot edit IP entries.","")
#      else
#        $("#domain_#{complaint_entry_id}").tooltipster('content', uri);
#        $("#site-search-#{complaint_entry_id}").tooltipster('content', uri);
#        $("#entry-uri-#{complaint_entry_id}").tooltipster('content', uri);
#        $.each current_categories, (key, entry) ->
#          $(".simple-nested-table#entry-table-#{complaint_entry_id}").append("<tr><td>#{entry.confidence}</td><td>#{entry.mnem} - #{entry.descr}</td><td>#{entry.top_certainty}</span></td></tr>")
#
#        $("#domain_#{complaint_entry_id}").text(domain)
#        $("#subdomain_#{complaint_entry_id}").text(subdomain)
#        $("#path_#{complaint_entry_id}").text(path)
#        $("#category_#{complaint_entry_id}").text(category)
#        $("#wbrs_score_#{complaint_entry_id}").text(wbrs_score)
#        query_who_params = "#{domain}, #{complaint_entry_id}"
#        $("#entry-uri-#{complaint_entry_id}").html("<a href='http://#{uri}' target='_blank' onclick='select_cat_text_field(#{complaint_entry_id})' >#{uri}</a>")
#        $("#site-search-#{complaint_entry_id}").html("<a href='https://www.google.com/search?q=site%3A#{uri}' target='_blank' onclick='select_cat_text_field(#{complaint_entry_id})'>#{uri}</a>")
#
#        $("#lookup-#{complaint_entry_id}").replaceWith('<button class="secondary" id="lookup-' + complaint_entry_id + '" data-fqdn="' + qual_subdomain + '" onclick="WebCat.RepLookup.whoIsLookups(' + complaint_entry_id  + ',\'' + qual_subdomain + '\')">Whois</button>')
#        $("#history-#{complaint_entry_id}").replaceWith('<button class="secondary" id="history-' + complaint_entry_id + '" onclick="history_dialog(' + complaint_entry_id + ',\'' + uri + '\')">History</button>')
#    error: (response) ->
#      std_msg_error("Unable to update URI", [response.responseJSON.message], reload: false)
#
# )



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
  selected_rows = $("tr.highlight-second-review.shown")
  self_review = $('#self_review').is(':checked')
  if selected_rows.length < 1
    return
  entries_to_update = []
  selected_rows.each ->
    entry_id = this.id
    prefix = $('#complaint_prefix_'+entry_id)[0].value
    status = $('[name=resolution_review_'+entry_id+']:checked').val()
    comment = $('#complaint_comment_'+entry_id)[0].value
    resolution_comment = $('#complaint_resolution_comment_'+entry_id)[0].value
    resolution = $('.complaint-resolution'+entry_id).text()
    #get the selectize control for the category input
    selectizeControl = $('#input_cat_'+entry_id).selectize()[0].selectize
    if $('#input_cat_'+entry_id).val() == null
      categories = null
    else
      categories = $('#input_cat_'+entry_id).val().toString()

    named_categories = ""
    if categories == null
      cat_array = []
    else
      cat_array = categories.split(',')
      for cat, i in cat_array
        named_categories = named_categories + selectizeControl.getItem(cat).text()
        if i < cat_array.length
          named_categories += ", "
    if status != "ignore"
      entries_to_update.push({
        'self_review': self_review,
        'id': entry_id,
        'prefix': prefix,
        'commit':status,
        'status':resolution,
        'comment':comment,
        'resolution_comment': resolution_comment,
        'categories': categories,
        'category_names':named_categories
      })

    std_msg_ajax(
      url: '/escalations/api/v1/escalations/webcat/complaint_entries/update_pending'
      method: 'POST'
      data: {data: entries_to_update}
      success: (response) ->
        window.location.reload(false);
      error: (response) ->
        notice_html = "<p>Something went wrong</p>"
    , this)





## Allows analyst to set ticket status to reopened and allows them to interact
# with the submission form
window.reopenComplaint = (entry_id, button) ->

# Getting all the fields that need to be interactive if reopened
  # Changing these on the fly so the full page doesn't need to be reloaded
  editable_stuff = $(button).parents('.nested-complaint-editable-data')[0]
  inputs = $(editable_stuff).find('.nested-table-input')
  radios = $(editable_stuff).find('.resolution_radio_button')
  wrapper = $(button).parents('.nested-complaint-data-wrapper')[0]
  nested_row = $(wrapper).parents('tr')[0]
  parent_row = $(nested_row).prev()
  status_col = $(parent_row).find('.state-col')

  std_msg_ajax(
    url: '/escalations/api/v1/escalations/webcat/complaint_entries/reopen_complaint_entry'
    method: 'POST'
    data: {'complaint_entry_id': entry_id}
    success: (response) ->
      $(inputs).each ->
        $(this).prop('disabled', false)
      $(radios).each ->
        $(this).prop('disabled', false)
      select_input =   $('#input_cat_' + entry_id)[0].selectize
      select_input.enable()
      $("#reopen_" + entry_id).addClass('hidden')
      $("#submit_changes_" + entry_id).removeClass('hidden')
      $(status_col).text('REOPENED')
    error: (response) ->
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
# For bulk submissions do we reload the page or do the same thing that we do w/ indv submissions
# confirm with Adam
#processSubmitMaster = () ->
#  debugger
#  data = []
#  selectedEntryDomains = (sessionStorage.getItem("webcat_entries_changed")|| "" )
#  return if selectedEntryDomains.length == 0
#
#  # disable the master submit button while processing
#  $('#master-submit').prop('disabled', true)
#
#  # remove empty values
#  selectedEntryDomains = selectedEntryDomains.split(',').filter((item) -> item);
#  selectedEntries = []
#  self_review = $('#self_review').is(':checked')
#
#  $('#complaints-index').DataTable().rows (idx, data, node) ->
#    entry_item = data.domain || data.ip_address
#    if selectedEntryDomains.includes(entry_item)
#      selectedEntries.push data
#    false
#  for entry in selectedEntries
#    data_wrapper = $("##{entry.entry_id}").closest('tr').next().find('.nested-complaint-data-wrapper')
#    entry_id = data_wrapper.find('tr').attr('entry_id')
#    row_id = data_wrapper.find('tr').attr('row_id')
#    type = data_wrapper.find('tr').attr('type')
#
#    if type == 'submit_changes' && entry_id && row_id
#      prefix = data_wrapper.find("#complaint_prefix_#{entry_id}")[0].value
#
#      category_names = []
#      categories = ""
#      if data_wrapper.find("#input_cat_#{entry_id}").val()
#        categories = data_wrapper.find("#input_cat_#{entry_id}").val().toString()
#      category_name = data_wrapper.find("#input_cat_#{entry_id}").next('.selectize-control').find('.item')
#      category_name.each ->
#        category_names.push($(this).text())
#      category_names = category_names.toString()
#      status = data_wrapper.find("[name=resolution#{entry_id}]:checked").val()
#      comment = data_wrapper.find("#complaint_comment_#{entry_id}")[0].value
#      resolution_comment = data_wrapper.find("#complaint_resolution_comment_#{entry_id}")[0].value
#      uri_as_categorized = data_wrapper.find("#complaint_prefix_#{entry_id}")[0].value
#      if (categories.length > 0 && status == 'FIXED') || ((categories.length == 0) && (status == 'INVALID' || status == 'UNCHANGED'))
#        data.push({
#          entry_id: entry_id,
#          error: false,
#          row_id: row_id,
#          prefix: prefix,
#          categories: categories,
#          category_names: category_names,
#          status: status,
#          comment: comment,
#          resolution_comment: resolution_comment,
#          uri_as_categorized: uri_as_categorized})
#
#      else if status == 'UNCHANGED' || status == 'INVALID'
#        data.push({
#          entry_id: entry_id,
#          error: false,
#          row_id: row_id,
#          prefix: prefix,
#          categories: categories,
#          category_names: category_names,
#          status: status,
#          comment: comment,
#          resolution_comment: resolution_comment,
#          uri_as_categorized: uri_as_categorized,
#          self_review: self_review
#        })
#      else if (categories.length == 0) && status == 'FIXED'
#        data.push({entry_id, error: true, reason: 'nil_categories'})
#  std_msg_ajax(
#    method: 'POST'
#    url: "/escalations/api/v1/escalations/webcat/complaint_entries/master_submit"
#    data: {data: data}
#    success: (response) ->
#      errors = false
#
#      nil_categories_errors = []
#      api_errors = []
#      success = []
#
#      json = JSON.parse(response)
#
#      table = $('#complaints-index').DataTable()
#
#      for entry in json
#        if entry.error == true && entry.reason == 'nil_categories'
#          nil_categories_errors.push(entry.entry_id)
#          errors = true
#        else if entry.error == true && entry.reason == 'api'
#          api_errors.push(entry.entry_id)
#          errors = true
#        else
#          success.push(entry.entry_id)
#
#          temp_row = table.row(entry.row_id)
#          temp_row.data().status = entry.status
#          temp_row.data().resolution = entry.resolution
#          temp_row.data().internal_comment = entry.comment
#          temp_row.data().resolution_comment = entry.resolution_comment
#          temp_row.data().category = entry.category_names
#          temp_row.data().category_names = entry.category_names
#          temp_row.invalidate().page(table_page).draw(false)
#          temp_row.child().remove()
#          temp_row.child(format(temp_row)).show()
#          nested_tooltip()
#          $('#input_cat_'+ entry.entry_id).selectize {
#            persist: false,
#            create: false,
#            maxItems: 5,
#            closeAfterSelect: true,
#            valueField: 'category_id',
#            labelField: 'category_name',
#            searchField: ['category_name', 'category_code'],
#            options: AC.WebCat.createSelectOptions('#input_cat_'+ entry.entry_id)
#            items: selected_options(entry.categories)
#          }
#          $('#input_cat_pending'+ entry.entry_id).selectize {
#            persist: false,
#            create: false,
#            maxItems: 5,
#            closeAfterSelect: true,
#            valueField: 'category_id',
#            labelField: 'category_name',
#            searchField: ['category_name', 'category_code'],
#            options: AC.WebCat.createSelectOptions('#input_cat_pending'+ entry.entry_id)
#            items: selected_options(entry.categories)
#          }
#
#      success_boiler_plate = "The following entries were successfully saved: " + success.toString() + "<br>"
#      api_boiler_plate =  "The following entries could not be saved due to API errors: " + api_errors.toString() + "<br>"
#      no_cats_boiler_plate = "The following entries could not be saved (no categories): " + nil_categories_errors.toString()
#
#      error_msg = ''
#
#      if success.length > 0
#        error_msg += success_boiler_plate
#      if api_errors.length > 0
#        error_msg += api_boiler_plate
#
#      if nil_categories_errors.length > 0
#        error_msg += no_cats_boiler_plate
#
#      if errors == true
#        std_msg_error(error_msg,"")
#      else
#        std_msg_success('Success',["All complaints successfully processed."], reload: true)
#
#      tds = $('#complaints-index tbody').closest('td')
#      for td in tds
#        if td.className == ''
#          td.classList.add('nested-complaint-data-wrapper')
#
#      $('#master-submit').prop('disabled', false)
#    error: (response) ->
#      std_msg_error("Unable to submit changes for selected entries.","", reload: false)
#      $('#master-submit').prop('disabled', false)
#
#  , this)


#window.master_submit = () ->
#  selectedItems = $('tr.selected')
#  thingsSelected = getTouchedFormCount()
#  if thingsSelected > selectedItems.length
#    std_msg_confirm(
#      "Changes have been made to at least " + thingsSelected +  " complaints but only " + selectedItems.length + " items are selected.", ["Updating selected items will reload the page and other changes will be lost."],
#      {
#        reload: false,
#        confirm_dismiss: true,
#        confirm: ->
#          processSubmitMaster()
#      })
#  else
#    processSubmitMaster()


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
    store_entry_changes(id)
    $('#master-submit').removeAttr('disabled')



  $('#complaints_check_box, #complaints_select_all').click ->
    checked = $(this).prop('checked')
    if checked
      $('#complaints-index').DataTable().rows( { page: 'current' } ).select()
    else
      $('#complaints-index').DataTable().rows().deselect()

    $("#complaints_check_box").prop('checked', checked)
    $("#complaints_select_all").prop('checked', checked)
    return

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






