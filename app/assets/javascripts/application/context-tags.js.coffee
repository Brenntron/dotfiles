# context tags dt logic for webrep and filerep - this tab exists in both places
$ ->
  $('#datatable-tmi').DataTable
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

  # below dt init will be enhanced later on, placeholder for now
  $('#datatable-enrichment').DataTable
    paging: false
    searching: false
    info: false

  # below dt init will be enhanced later on, placeholder for now
  $('#datatable-prevalence').DataTable
    paging: false
    searching: false
    info: false
