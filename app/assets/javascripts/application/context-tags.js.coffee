# context tags specific logic for webrep and filerep - this tab exists on both
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

  # move this to enrich.coffee later on possibly
  $('#datatable-enrichment').DataTable
    paging: false
    searching: false
    info: false

  $('#datatable-prevalence').DataTable
    paging: false
    searching: false
    info: false

