# context tags dt logic for webrep and filerep - this tab exists in both places
$ ->
  $('#tmi-datatable').DataTable
    paging: false
    searching: false
    info: false
    order: [[ 1, 'asc']]
    columnDefs: [
      {
        targets: [ 0 ]
        orderable: false
        sortable: false
      }
    ]

# refactor how this works when time avail
window.context_tab_move_data = () ->
  # get the enrich table and data, move it here, init the table as a dt
  # refactor below as loop
  enrich_table = $('#research_tab .enrich-details-table table').detach()
  $('.area-for-enrichment').html(enrich_table)

  if $('.area-for-enrichment tbody tr:first').html() == ""
    $('.area-for-enrichment tbody tr:first').remove()  # clean out first row for dt init

  $('#enrichment-datatable').DataTable
    paging: false
    searching: false
    info: false

  # get the prev table and data, move it here, init the table as a dt
  prevalence_table = $('#research_tab .prevalence-details-table table').detach()
  $('.area-for-prevalence').html(prevalence_table)

  if $('.area-for-prevalence tbody tr:first').html() == ""
    $('.area-for-prevalence tbody tr:first').remove()

  $('#prevalence-datatable').DataTable
    paging: false
    searching: false
    info: false
