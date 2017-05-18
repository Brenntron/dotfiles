
@expand_job_result =(button_tag) ->
  alert(button_tag.getAttribute("data-collapse"))

@collapse_job_result =(button_tag) ->
  alert(button_tag.getAttribute("data-expand"))

