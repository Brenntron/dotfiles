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

  # enrich.js.coffee will set up the enrich data in the context tags tab
  # REFACTOR OUT THE SETTIMEOUT INTO A PROMISE OR DIFF SOLUTION. FIND BETTER SOLUTION RATHER THAN CLONING WHEN TIME AVAIL.
  setTimeout ->
    enrich_table = $('#research_tab .enrich-details-table table').clone()
    $('.area-for-enrichment').html(enrich_table)

    prevalence_table = $('#research_tab .prevalence-details-table table').clone()
    $('.area-for-prevalence').html(prevalence_table)

    # SET UP THE DT INITS ON THESE TABLES LATER ON IN TMI DEVELOPMENT, NORMAL TABLES ARE OK FOR TIME-BEING.
    # LEAVE COMMENTED BELOW FOR NOW.
#    $('.tab-context-tags .enrich-webrep-table-data-present').DataTable
#      paging: false
#      searching: false
#      info: false
#    $('.tab-context-tags .prevalence-webrep-table-data-present').DataTable
#      paging: false
#      searching: false
#      info: false
  , 4000


