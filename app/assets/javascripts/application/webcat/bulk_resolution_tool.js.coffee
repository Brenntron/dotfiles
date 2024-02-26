# Bulk resolution tool logic
window.webcat_submittable_rows = []

apply_resolution = () ->
  entry_ids = []
  resolution_to_apply = $('input[name="complaint[resolution]"]:checked')[0].value

  for row in window.webcat_submittable_rows
    {entry_id, status} = row

    entry_ids.push(entry_id)
    $("##{resolution_to_apply.toLowerCase()}#{entry_id}").prop('checked', true)
    store_entry_changes(entry_id, 'submit')
    sessionStorage.setItem("#{entry_id}_resolution", 'staged')

  # Update the resolution templates for the submittable rows
  get_resolution_templates(resolution_to_apply, 'individual', entry_ids)
  # Enable the customer facing comment button if there is an applied resolution status
  $('#customer-facing-apply-button').prop('disabled', false)

apply_customer_facing_comment = () ->
  email_template = $('#email-response-to-customers-select').val()
  customer_facing_comment = $('#email-response-to-customers').val()

  for row in window.webcat_submittable_rows
    {entry_id, status} = row

    $("#entry-email-response-to-customers-select_#{entry_id}").val(email_template)
    $("#entry-email-response-to-customers_#{entry_id}").val(customer_facing_comment)
    store_entry_changes(entry_id, 'submit')
    sessionStorage.setItem("#{entry_id}_customer_facing_comment", 'staged')

apply_category = () ->
  category_option = $('input[name="complaint[category_option]"]:checked')[0].value

  categories_to_apply = $('#webcat-bulk-categories')[0].selectize.items

  for row in window.webcat_submittable_rows
    {entry_id, status} = row

    if category_option is 'ADD'
      $("#input_cat_#{entry_id}")[0].selectize.addItems(categories_to_apply)
    else if category_option is 'REPLACE'
      $("#input_cat_#{entry_id}")[0].selectize.setValue(categories_to_apply)
    else if category_option is 'DROP_ALL'
      $("#input_cat_#{entry_id}")[0].selectize.clear()

    store_entry_changes(entry_id, 'submit')
    sessionStorage.setItem("#{entry_id}_categories", 'staged')

apply_internal_comment = () ->
  internal_comment = $('#internal_comment').val()

  for row in window.webcat_submittable_rows
    {entry_id, status} = row

    $("#internal_comment_#{entry_id}").val(internal_comment)
    store_entry_changes(entry_id, 'submit')
    sessionStorage.setItem("#{entry_id}_internal_facing_comment", 'staged')

clear_resolution = () ->
  entry_ids = []

  for row in window.webcat_submittable_rows
    {entry_id, status} = row

    $("#fixed#{entry_id}").prop('checked', true)

    entry_ids.push(entry_id)

    if staged_changes("#{entry_id}_resolution")
      remove_entry_from_changes(entry_id, 'submit')
      sessionStorage.removeItem("#{entry_id}_resolution")

  # Update the resolution templates for the submittable rows
  get_resolution_templates('FIXED', 'individual', entry_ids)
  # Disable the customer facing comment button if there is not applied resolution status
  $('#customer-facing-apply-button').prop('disabled', true)

clear_customer_facing_comment = () ->
  entry_ids = []

  for row in window.webcat_submittable_rows
    {entry_id, status} = row

    entry_ids.push(entry_id)

    if staged_changes("#{entry_id}_customer_facing_comment")
      remove_entry_from_changes(entry_id, 'submit')
      sessionStorage.removeItem("#{entry_id}_customer_facing")

  get_resolution_templates('FIXED', 'individual', entry_ids)

clear_category = () ->
  for row in window.webcat_submittable_rows
    {entry_id, status} = row

    $("#input_cat_#{entry_id}")[0].selectize.clear()

  if staged_changes("#{entry_id}_category")
    remove_entry_from_changes(entry_id, 'submit')
    sessionStorage.removeItem("#{entry_id}_category")

clear_internal_comment = () ->
  for row in window.webcat_submittable_rows
    {entry_id, status} = row

    $("#internal-comment-#{entry_id}").val('')

  if staged_changes("#{entry_id}_internal_comment")
    remove_entry_from_changes(entry_id, 'submit')
    sessionStorage.removeItem("#{entry_id}_internal_comment")

staged_changes = (storage_key) ->
  storage_value = sessionStorage.getItem(storage_key) || ''

  !!storage_value

has_submittable_status = (rowData) ->
  submittable_statuses = ['ASSIGNED', 'NEW', 'REOPENED', 'RESOLVED']

  rowData.status in submittable_statuses

should_clear = (button_id) ->
  item_key = button_id.replace(/-apply-button|-button/, '')

  # Fields should only clear if all submittable rows have staged changes
  for row in window.webcat_submittable_rows
    if staged_changes("#{row.entry_id}_#{item_key}")
      continue
    else
      return false

  return true

window.bulk_resolution_select_handler = (dt, indexes) ->
  newly_selected_submmittable_rows = dt.rows(indexes).data().toArray().filter(has_submittable_status)
  window.webcat_submittable_rows = window.webcat_submittable_rows.concat(newly_selected_submmittable_rows)

  category_option = $('input[name="complaint[category_option]"]:checked')[0].value

  staged_resolution_changes_for_selected = window.webcat_submittable_rows.some((row) -> staged_changes("#{row.entry_id}_resolution"))

  $('#resolution-apply-button').prop('disabled', false)
  $('#customer-facing-apply-button').prop('disabled', false) if staged_resolution_changes_for_selected
  $('#category-apply-button').prop('disabled', false) if $('#webcat-bulk-categories')[0].selectize.getValue().length > 0 || category_option is 'DROP_ALL'
  $('#internal-comment-button').prop('disabled', false) if $('#internal_comment').val()

window.bulk_resolution_deselect_handler = (dt, indexes) ->
  rows_to_remove = dt.rows(indexes).data().pluck('DT_RowId').toArray()
  window.webcat_submittable_rows = window.webcat_submittable_rows.filter((row) -> !rows_to_remove.includes(row.entry_id))

  return if window.webcat_submittable_rows.length > 0

  $('#resolution-apply-button').prop('disabled', true)
  $('#customer-facing-apply-button').prop('disabled', true)
  $('#category-apply-button').prop('disabled', true)
  $('#internal-comment-button').prop('disabled', true)

window.clearBulkResolution = () ->
  return if window.webcat_submittable_rows.length is 0

  clear_resolution()

  # reset customer facing comment in the bulk resolution tool
  get_resolution_templates('UNCHANGED', 'bulk')
  clear_customer_facing_comment()

  unless $('#category-apply-button').prop('disabled')
    $('#webcat-bulk-categories')[0].selectize.clear()
    clear_category()

  unless $('#internal-comment-button').prop('disabled')
    $('#internal_comment').val('')
    clear_internal_comment()

window.applyAll = () ->
  return if window.webcat_submittable_rows.length is 0

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
      return if window.webcat_submittable_rows.length is 0

      button_id = $(event.target).attr('id')

      if should_clear(button_id)
        switch button_id
          when 'resolution-apply-button' then clear_resolution()
          when 'customer-facing-apply-button' then clear_customer_facing_comment()
          when 'category-apply-button' then clear_category()
          when 'internal-comment-button' then clear_internal_comment()
      else
        switch button_id
          when 'resolution-apply-button' then apply_resolution()
          when 'customer-facing-apply-button' then apply_customer_facing_comment()
          when 'category-apply-button' then apply_category()
          when 'internal-comment-button' then apply_internal_comment()

    $('input[name="complaint[category_option]"]').on 'change', () ->
      $('#category-apply-button').prop('disabled', false) if window.webcat_submittable_rows.length > 0

    $('textarea#internal_comment').on 'input', () ->
      $('#internal-comment-button').prop('disabled', false) if $('#internal-comment-button').prop('disabled') && window.webcat_submittable_rows.length > 0
