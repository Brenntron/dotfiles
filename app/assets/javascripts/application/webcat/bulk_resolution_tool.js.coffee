# Bulk resolution tool logic
message_timeout = null
submittable_rows = []

apply_resolution = () ->
  entry_ids = []
  resolution_to_apply = $('input[name="complaint[resolution]"]:checked')[0].value

  for row in submittable_rows
    {entry_id, status} = row

    entry_ids.push(entry_id)
    $("##{resolution_to_apply.toLowerCase()}#{entry_id}").prop('checked', true)
    store_entry_changes(entry_id, 'submit')

  return {applied_resolution: resolution_to_apply, updated_entry_ids: entry_ids}

apply_customer_facing_comment = () ->
  bulk_tool_resolution = $('.bulk-resolution-radio:checked').val()
  $email_select = $('#email-response-to-customers-select')
  email_template = $email_select.val()
  email_options = $email_select[0].options
  customer_facing_comment = $('#email-response-to-customers').val()

  for row in submittable_rows
    {entry_id} = row
    row_resolution = $(".resolution_radio_button[name='resolution#{entry_id}']:checked").val()

    continue unless bulk_tool_resolution is row_resolution

    for option in email_options
      $option = $(option)
      data = $option.data()
      name = $option.val()

      template_option = """
                        <option class='webcat-resolution-template-option' val='#{name}'
                          data-body='#{data.body}'
                          data-description='#{data.description}'>
                          #{name}
                        </option>
                        """
      $("#entry-email-response-to-customers-select_#{entry_id}").append(template_option)

    $("#entry-email-response-to-customers-select_#{entry_id}").val(email_template)
    $("#entry-email-response-to-customers_#{entry_id}").val(customer_facing_comment)
    store_entry_changes(entry_id, 'submit')

apply_internal_comment = () ->
  internal_comment = $('#internal_comment').val()

  return unless !!internal_comment

  for row in submittable_rows
    {entry_id, status} = row

    $("#internal_comment_#{entry_id}").val(internal_comment)
    store_entry_changes(entry_id, 'submit')

has_submittable_status = (rowData) ->
  submittable_statuses = ['ASSIGNED', 'NEW', 'REOPENED']
  is_reopened = $("##{rowData.entry_id}").find('.state-row td').text() is 'REOPENED'


  rowData.status in submittable_statuses || is_reopened

get_unique_rows = () ->
  unique_rows = []
  unique_ids = []

  for row in submittable_rows
    unless unique_ids.includes(row.entry_id)
      unique_rows.push(row)
      unique_ids.push(row.entry_id)

  unique_rows

display_success_message = () ->
  html = """
         <div class='bulk-resolution-message-container'>
           <span class='bulk-icon bulk-success-icon'></span>
           <p class='bulk-message bulk-success'>
             Successfully applied to selected entries.
           </p>
         </div>
         """

  append_message(html)

display_warning_message = () ->
  html = """
         <div class='bulk-resolution-message-container'>
           <span class='bulk-icon bulk-warning-icon'></span>
           <p class='bulk-message bulk-warning'>
             Unable to apply to all selected entries, applied to submittable entries only.
           </p>
         </div>
         """

  append_message(html)

display_error_message = () ->
  html = """
         <div class='bulk-resolution-message-container'>
           <span class='bulk-icon bulk-error-icon'></span>
           <p class='bulk-message bulk-error'>
             Unable to apply resolution to one or more entries.
           </p>
         </div>
         """

  append_message(html)

append_message = (html) ->
  clearTimeout(message_timeout)
  $('.bulk-resolution-message-container').remove()


  $(".edit-resolution-container .top-text").append(html)

  message_timeout = setTimeout(() ->
    $('.bulk-resolution-message-container').fadeOut("slow",
      $('.bulk-resolution-message-container').remove()
    )
  , 10000)


window.bulk_resolution_select_handler = (dt, indexes) ->
  newly_selected_submmittable_rows = dt.rows(indexes).data().toArray().filter(has_submittable_status)
  submittable_rows = [submittable_rows..., newly_selected_submmittable_rows...]

  submittable_rows = get_unique_rows()

  return if submittable_rows.length is 0

  $('#apply_resolution_button').prop('disabled', false)

window.bulk_resolution_deselect_handler = (dt, indexes) ->
  rows_to_remove = dt.rows(indexes).data().pluck('DT_RowId').toArray()
  submittable_rows = submittable_rows.filter((row) -> !rows_to_remove.includes(row.entry_id))

  return if submittable_rows.length > 0

  $('#apply_resolution_button').prop('disabled', true)

window.clearBulkResolution = () ->
  $('#webcat_resolution_unchanged_option').prop('checked', true)

  get_resolution_templates('UNCHANGED', 'bulk')

  $('#internal_comment').val('')

window.applyAll = () ->
  {applied_resolution, updated_entry_ids} = apply_resolution()

  apply_customer_facing_comment()

  apply_internal_comment()

  if submittable_rows.length is $('#complaints-index').DataTable().rows({selected: true}).count()
    display_success_message()
  else
    display_warning_message()