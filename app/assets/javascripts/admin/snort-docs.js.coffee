window.set_rule_doc_status =(rule_id, new_value) ->
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax {
    url: "/api/v1/rules/" + rule_id + "/snort_doc_status"
    type: 'PATCH'
    dataType: 'json'
    headers: headers
    data:
      snort_doc_status: new_value
  }


window.submit_rule_doc_status =(form_tag) ->
  rule_id = form_tag.querySelector("input[name=rule_id]").value
  snort_doc_status = form_tag.querySelector("select[name=snort_doc_status]").value
  set_rule_doc_status(rule_id, snort_doc_status)
  location.reload true
  true



window.upload_rule_doc_yaml =(yaml_file) ->
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax {
    url: "/api/v2/snort/rule_docs/pretty"
    type: 'GET'
    dataType: 'json'
    headers: headers
    data:
      rule_update: yaml_file
  }

window.submit_rule_doc_yaml =(form_tag) ->
  debugger
  yaml_file = form_tag.querySelector("input[name=yaml_file]").value
  upload_rule_doc_yaml(yaml_file)
  location.reload true
  true
