# Bulk resolution tool logic
submittable_rows = []

apply_resolution = () ->
  entry_ids = []
  resolution_to_apply = $('input[name="complaint[resolution]"]:checked')[0].value

  for row in submittable_rows
    {entry_id, status} = row

    entry_ids.push(entry_id)
    $("##{resolution_to_apply.toLowerCase()}#{entry_id}").prop('checked', true)
    store_entry_changes(entry_id, 'submit')

  # Update the resolution templates for the submittable rows
  get_resolution_templates(resolution_to_apply, 'individual', entry_ids)
  # Enable the customer facing comment button if there is an applied resolution status
  $('#customer-facing-apply-button').prop('disabled', false)

apply_customer_facing_comment = () ->
  email_template = $('#email-response-to-customers-select').val()
  customer_facing_comment = $('#email-response-to-customers').val()

  for row in submittable_rows
    {entry_id, status} = row

    continue unless $("#entry-email-response-to-customers-select_#{entry_id}").val()

    $("#entry-email-response-to-customers-select_#{entry_id}").val(email_template)
    $("#entry-email-response-to-customers_#{entry_id}").val(customer_facing_comment)
    store_entry_changes(entry_id, 'submit')

apply_category = () ->
  category_option = $('input[name="complaint[category_option]"]:checked')[0].value

  categories_to_apply = $('#webcat-bulk-categories')[0].selectize.items

  for row in submittable_rows
    {entry_id, status} = row

    if category_option is 'ADD'
      $("#input_cat_#{entry_id}")[0].selectize.addItems(categories_to_apply)
    else if category_option is 'REPLACE'
      $("#input_cat_#{entry_id}")[0].selectize.setValue(categories_to_apply)
    else if category_option is 'DROP_ALL'
      $("#input_cat_#{entry_id}")[0].selectize.clear()

    store_entry_changes(entry_id, 'submit')

apply_internal_comment = () ->
  internal_comment = $('#internal_comment').val()

  for row in submittable_rows
    {entry_id, status} = row

    $("#internal_comment_#{entry_id}").val(internal_comment)
    store_entry_changes(entry_id, 'submit')

has_submittable_status = (rowData) ->
  submittable_statuses = ['ASSIGNED', 'NEW', 'REOPENED']

  rowData.status in submittable_statuses

window.get_webcat_submittable_rows = () ->
  submittable_rows

window.bulk_resolution_select_handler = (dt, indexes) ->
  newly_selected_submmittable_rows = dt.rows(indexes).data().toArray().filter(has_submittable_status)
  submittable_rows = submittable_rows.concat(newly_selected_submmittable_rows)

  return if submittable_rows.length is 0

  category_option = $('input[name="complaint[category_option]"]:checked')[0].value

  $('#resolution-apply-button').prop('disabled', false)
  $('#customer-facing-apply-button').prop('disabled', false)
  $('#category-apply-button').prop('disabled', false) if $('#webcat-bulk-categories')[0].selectize.getValue().length > 0 || category_option is 'DROP_ALL'
  $('#internal-comment-button').prop('disabled', false) if $('#internal_comment').val()

window.bulk_resolution_deselect_handler = (dt, indexes) ->
  rows_to_remove = dt.rows(indexes).data().pluck('DT_RowId').toArray()
  submittable_rows = submittable_rows.filter((row) -> !rows_to_remove.includes(row.entry_id))

  return if submittable_rows.length > 0

  $('#resolution-apply-button').prop('disabled', true)
  $('#customer-facing-apply-button').prop('disabled', true)
  $('#category-apply-button').prop('disabled', true)
  $('#internal-comment-button').prop('disabled', true)

window.clearBulkResolution = () ->
  return if submittable_rows.length is 0

  $('#webcat_resolution_unchanged_option').prop('checked', true)

  get_resolution_templates('UNCHANGED', 'bulk')

  $('#webcat-bulk-categories')[0].selectize.clear()

  $('#internal_comment').val('')

window.applyAll = () ->
  return if submittable_rows.length is 0

  apply_resolution()

  if $('#email-response-to-customers').val()
    apply_customer_facing_comment()

  if $('#webcat-bulk-categories')[0].selectize.getValue().length > 0 || $('input[name="complaint[category_option]"]:checked').val() is 'DROP_ALL'
    apply_category()

  if $('#internal_comment').val()
    apply_internal_comment()

$ ->
  if $('#complaints-index').length
    $('.resolution-apply-button').click (event) ->
      return if submittable_rows.length is 0

      button_id = $(event.target).attr('id')

      switch button_id
        when 'resolution-apply-button' then apply_resolution()
        when 'customer-facing-apply-button' then apply_customer_facing_comment()
        when 'category-apply-button' then apply_category()
        when 'internal-comment-button' then apply_internal_comment()

    $('input[name="complaint[category_option]"]').on 'change', () ->
      $('#category-apply-button').prop('disabled', false) if submittable_rows.length > 0

    $('textarea#internal_comment').on 'input', () ->
      if $('#internal-comment-button').prop('disabled') && submittable_rows.length > 0 && $(this).val()
        $('#internal-comment-button').prop('disabled', false)
      else if !!$(this).val()
        $('#internal-comment-button').prop('disabled', true)
