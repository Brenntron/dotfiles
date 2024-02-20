# Bulk resolution tool logic
bulk_submittable_statuses = ['ASSIGNED', 'NEW', 'COMPLETED', 'REOPENED', 'RESOLVED']

apply_resolution = () ->
  data_table = $('#complaints-index').DataTable()
  selected_rows = data_table.rows({selected: true})[0]
  resolution_to_apply = $('input[name="complaint[resolution]"]:checked')[0].value.toLowerCase()

  for row in selected_rows
    {entry_id, status} = data_table.row(row).data()

    continue unless status in bulk_submittable_statuses

    $("##{resolution_to_apply}#{entry_id}").prop('checked', true)
    store_entry_changes(entry_id, 'submit')
    sessionStorage.setItem("#{entry_id}_resolution", 'staged')

apply_customer_facing_comment = () ->
  data_table = $('#complaints-index').DataTable()
  selected_rows = data_table.rows({selected: true})[0]
  customer_facing_comment = $('#email-response-to-customers').val()

  for row in selected_rows
    {entry_id, status} = data_table.row(row).data()

    continue unless status in bulk_submittable_statuses

    $("#entry_email_response_to_customers_#{entry_id}").val(customer_facing_comment)
    store_entry_changes(entry_id, 'submit')
    sessionStorage.setItem("#{entry_id}_customer_facing_comment", 'staged')

apply_category = () ->
  data_table = $('#complaints-index').DataTable()
  selected_rows = data_table.rows({selected: true})[0]
  category_option = $('input[name="complaint[category_option]"]:checked')[0].value

  if category_option is 'DROP_ALL'
    categories_to_apply = []
  else
    categories_to_apply = $('#webcat-bulk-categories')[0].selectize.items

  for row in selected_rows
    {entry_id, status} = data_table.row(row).data()

    continue unless status in bulk_submittable_statuses

    if category_option is 'ADD'
      $("#input_cat_#{entry_id}")[0].selectize.addItems(categories_to_apply)
    else if category_option is 'REPLACE'
      $("#input_cat_#{entry_id}")[0].selectize.setValue(categories_to_apply)

    store_entry_changes(entry_id, 'submit')
    sessionStorage.setItem("#{entry_id}_categories", 'staged')

apply_internal_comment = () ->
  data_table = $('#complaints-index').DataTable()
  selected_rows = data_table.rows({selected: true})[0]
  internal_comment = $('#internal_comment').val()

  for row in selected_rows
    {entry_id, status} = data_table.row(row).data()

    continue unless status in bulk_submittable_statuses

    $("#internal_comment_#{entry_id}").val(internal_comment)
    store_entry_changes(entry_id, 'submit')
    sessionStorage.setItem("#{entry_id}_internal_facing_comment", 'staged')

clear_resolution = () ->
  data_table = $('#complaints-index').DataTable()
  selected_rows = data_table.rows({selected: true})[0]

  for row in selected_rows
    {entry_id, status} = data_table.row(row).data()

    continue unless status in bulk_submittable_statuses

    $("#fixed#{entry_id}").prop('checked', true)

    unless staged_changes("#{entry_id}_resolution")
      remove_entry_from_changes(entry_id, 'submit')
      sessionStorage.removeItem("#{entry_id}_resolution")

clear_customer_facing_comment = () ->
  data_table = $('#complaints-index').DataTable()
  selected_rows = data_table.rows({selected: true})[0]

  for row in selected_rows
    {entry_id, status} = data_table.row(row).data()

    continue unless status in bulk_submittable_statuses

    $("#entry_email_response_to_customers_#{entry_id}").val('')

    unless staged_changes("#{entry_id}_customer_facing_comment")
      remove_entry_from_changes(entry_id, 'submit')
      sessionStorage.removeItem("#{entry_id}_customer_facing_comment")

clear_category = () ->
  data_table = $('#complaints-index').DataTable()
  selected_rows = data_table.rows({selected: true})[0]

  for row in selected_rows
    {entry_id, status} = data_table.row(row).data()

    continue unless status in bulk_submittable_statuses

    $("#input_cat_#{entry_id}")[0].selectize.clear()

  unless staged_changes("#{entry_id}_categories")
    remove_entry_from_changes(entry_id, 'submit')
    sessionStorage.removeItem("#{entry_id}_categories")

clear_internal_comment = () ->
  data_table = $('#complaints-index').DataTable()
  selected_rows = data_table.rows({selected: true})[0]

  for row in selected_rows
    {entry_id, status} = data_table.row(row).data()

    continue unless status in bulk_submittable_statuses

    $("#internal-comment-#{entry_id}").val('')

  unless staged_changes("#{entry_id}_internal_facing_comment")
    remove_entry_from_changes(entry_id, 'submit')
    sessionStorage.removeItem("#{entry_id}_internal_facing_comment")

staged_changes = (storage_key) ->
  storage_value = sessionStorage.getItem(storage_key) || ''

  return !!storage_value

window.clearBulkResolution = () ->
  $('.apply_button').removeClass('applied')
  clear_resolution()
  $('#email_response_to_customers').val('')
  clear_customer_facing_comment()
  $('#webcat_bulk_categories')[0].selectize.clear()
  clear_category()
  $('#internal_comment').val('')
  clear_internal_comment()

window.applyAll = () ->
  $('#resolution-apply-button').addClass('applied')
  apply_resolution()

  if $('#email_response_to_customers').val()
    $('#customer-facing-apply-button').addClass('applied')
    apply_customer_facing_comment()

  if $('#webcat_bulk_categories')[0].selectize.getValue().length > 0 || $('input[name="complaint[category_option]"]:checked').val() is 'DROP_ALL'
    $('#category-apply-button').addClass('applied')
    apply_category()

  if $('#internal_comment').val()
    $('#internal-comment-button').addClass('applied')
    apply_internal_comment()

$ ->
  if $('#complaints-index').length
    $('.resolution-apply-button').click (event) ->
      $button = $(event.target)
      button_id = $button.attr('id')
      submit_changes_button = $

      if $button.hasClass('applied')
        $button.removeClass('applied')

        switch button_id
          when 'resolution-apply-button' then clear_resolution()
          when 'customer-facing-apply-button' then clear_customer_facing_comment()
          when 'category-apply-button' then clear_category()
          when 'internal-comment-button' then clear_internal_comment()
      else
        $button.addClass('applied')

        switch button_id
          when 'resolution-apply-button' then apply_resolution()
          when 'customer-facing-apply-button' then apply_customer_facing_comment()
          when 'category-apply-button' then apply_category()
          when 'internal-comment-button' then apply_internal_comment()
