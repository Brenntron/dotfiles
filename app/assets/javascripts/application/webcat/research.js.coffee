$ ->
  headers =  'Token': $('input[name="token"]').val(),'Xmlrpc-Token': $('input[name="xml_token"]').val()

  $(document).ready(
    hashes = window.location.href.slice(window.location.href.indexOf('?') + 1).split('&')
    domain = hashes[0].split('=')[1]

    $('#webcat_research_search').val(domain)
  )

  $('#webcat_research_search').on('keyup', (e) ->
    if e.key == 'Enter' || e.keyCode == 13
      domain = $(this).val()
      hash = window.location.hash.split('?')[0]
      url = window.location.origin + window.location.pathname + "?domain=#{domain}"
      document.location.assign(url)
  )

  $('#webcat-research-categorize-url').click(() ->
    $('#categorize-research-urls').selectize {
      create: false,
      labelField: 'category_name',
      maxItems: 5,
      options: AC.WebCat.createSelectOptions('#categorize-research-urls'),
      persist: true,
      searchField: ['category_name', 'category_code'],
      valueField: 'category_id'
    }
  )

  window.detail_research = () ->
    domain = $('#webcat_research_search').val()
    entries = [ domain ]
    category_ids = []
    categories = []

    for id in $('#categorize-research-urls').val().split(',')
      category_ids.push id

      categories.push $('#categorize-research-urls')[0].selectize.getItem(id)[0].innerText

    $('.loader-gears').toggle()
    $('.selected-urls-wrapper').toggle()
    $('.selected-urls-categories-wrapper').toggle()

    $.ajax(
      url: '/escalations/api/v1/escalations/webcat/complaints/bulk_categorize'
      method: 'POST'
      headers: headers
      data:
        entries: entries,
        category_ids: category_ids,
        categories: categories
      success: (response) ->
        data = response.data

        $('#webcat-research-categorize-url').dropdown('toggle')
        $('.loader-gears').toggle()
        unless data.complete_failed.length > 0 || data.create_failed.length > 0
          $('#categorize-research-urls')[0].selectize.clear()

          std_msg_success('Categories Submitted', [], reload: false)
        else
          std_msg_success('Categories were not created', [], reload: false)
      error: (response) ->
        $('#webcat-research-categorize-url').dropdown('toggle')
        $('.loader-gears').toggle()
        std_api_error(response, "Categories were not created.", reload: false)
    , this)

