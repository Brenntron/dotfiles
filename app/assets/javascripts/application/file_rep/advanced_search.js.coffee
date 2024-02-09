namespace 'AC.FileRep', (exports) ->
  exports.daterangepickerFormat = 'YYYY-MM-DD'

  exports.createAssigneeOptions = ->
    std_msg_ajax(
      method: 'GET'
      url: "/escalations/api/v1/users/json"
      success_reload: false
      success: (response) ->
        element = $('#assignee-input')
        selectize = element[0].selectize

        json = JSON.parse(response)

        for assignee in json
          selectize.addOption(assignee)
    )

  exports.createPlatformOptions = ->
    std_msg_ajax(
      method: 'GET'
      url: '/escalations/api/v1/escalations/webcat/platforms_names'
      success_reload: false
      success: (response) ->
        element = $('#platform-input')
        selectize = element[0].selectize

        for platform in response.data
          selectize.addOption(platform)
    )

  exports.populateSearchCriteria = ->
    return unless localStorage.search_conditions

    searchConditions = JSON.parse localStorage.search_conditions
    for searchLabel, searchCriteria of searchConditions
      continue if searchCriteria == ''

      $search_label = null
      if searchLabel in Object.keys(common_inputs_mapping)
        $search_label = handle_common_inputs(searchLabel, searchCriteria)
      else if searchLabel in Object.keys(sliders_inputs_mapping)
        $search_label = handle_slider_inputs(searchLabel, searchCriteria)
      else if searchLabel in Object.keys(date_range_inputs_mapping)
        $search_label = handle_date_range_inputs(searchLabel, searchCriteria)
      else if searchLabel in Object.keys(multiselects_inputs_mapping)
        $search_label = handle_multiselect_inputs(searchLabel, searchCriteria)
      else if searchLabel == 'in_zoo'
        $search_label = $('#in-sample-zoo-input')
        $search_label.prop('checked', searchCriteria)

      $search_label.removeClass('hidden')


  exports.update_slider_values = (slider_id, values) ->
    $slider = $("#{slider_id}")
    $slider.slider(values: [values.from, values.to])
    $($slider.parent('.form-group').find('.ui-slider-handle')[0]).text(values.from)
    $($slider.parent('.form-group').find('.ui-slider-handle')[1]).text(values.to)

  exports.update_daterangepicker_values = (picker_id, dates) ->
    $picker = $("#{picker_id}")
    $picker.daterangepicker({locale: { format: AC.FileRep.daterangepickerFormat }}).data('daterangepicker').setStartDate(dates.from);
    $picker.daterangepicker({locale: { format: AC.FileRep.daterangepickerFormat }}).data('daterangepicker').setEndDate(dates.to);

  common_inputs_mapping = {
    'id': '#caseid-input',
    'file_name': '#file-name-input',
    'sha256_hash': '#sha256-input',
    'sample_type': '#sample-type-input',
    'detection_name': '#amp-detection-name-input',
    'submitter_type': '#submitter-type-input',
    'customer_name': '#customer-name-input',
    'customer_email': '#customer-email-input',
    'customer_company_name': '#customer-company-input',
    'status': '#status-input',
    'disposition': '#amp-disposition-input',
    'disposition_suggested': '#suggested-disposition-input',
    'detection_last_set': '#amp-detection-created-input',
    'resolution': '#resolution-input'
  }

  sliders_inputs_mapping = {
    'sandbox_score': '#sandbox-score-input',
    'threatgrid_score': '#tg-score-input'
  }

  date_range_inputs_mapping = {
    'created_at': '#time-submitted-input',
    'updated_at': '#last-updated-input'
  }

  multiselects_inputs_mapping = {
    'assigned': '#assignee-input',
    'platforms': '#platform-input'
  }

  handle_common_inputs = (label, criteria) ->
    $search_label = $(common_inputs_mapping[label])
    $search_label.val(criteria)
    return $search_label

  handle_slider_inputs = (label, criteria) ->
    $search_label = $(sliders_inputs_mapping[label])
    AC.FileRep.update_slider_values(sliders_inputs_mapping[label], criteria)
    return $search_label

  handle_date_range_inputs = (label, criteria) ->
    $search_label = $(date_range_inputs_mapping[label])
    AC.FileRep.update_daterangepicker_values(date_range_inputs_mapping[label], criteria)
    return $search_label

  handle_multiselect_inputs = (label, criteria) ->
    $search_label = $(multiselects_inputs_mapping[label])
    $search_label[0].selectize.setValue(criteria.split(','))
    return $search_label
