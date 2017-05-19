
@expand_job_result =(button_tag) ->
  expand_id = button_tag.getAttribute("data-expand-id")
  document.getElementById(expand_id).style.display = "none"
  collapse_id = button_tag.getAttribute("data-collapse-id")
  document.getElementById(collapse_id).style.display = ""

@collapse_job_result =(button_tag) ->
  expand_id = button_tag.getAttribute("data-expand-id")
  document.getElementById(expand_id).style.display = ""
  collapse_id = button_tag.getAttribute("data-collapse-id")
  document.getElementById(collapse_id).style.display = "none"

