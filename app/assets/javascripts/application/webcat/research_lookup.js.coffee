window.select_or_deselect_cluster = (cluster_id)->
  $('.cluster-path-checkbox_' + cluster_id).prop('checked', $('#' + cluster_id).prop('checked'))

$('#cluster_filter_field').keyup (event) ->
  if event.keyCode == 13
    apply_filter_to_table()
  return

$(window).load ->
  $('.lookup-detail').addClass('active')

window.lookup_view = (view) ->
  active_class= '.lookup-' + view
  if view == 'detail'
    inactive_class = '.lookup-quick'
  else if view == 'quick'
    inactive_class = '.lookup-detail'

  $(active_class).addClass('active')
  $(inactive_class).removeClass('active')