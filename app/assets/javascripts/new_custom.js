$(document).ready(function() {

    $('.active').show();
    $('.hidden').hide();

    $('#button_import').click(function() {
        var headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()};
        var id = $('#import_bug').val();
        $.ajax({
            url: "/api/v1/bugs/import/" + id,
            method: 'GET',
            data: {'api_key': 'h93hq@hwo9%@ah!jsh'},
            headers: headers
        }).done(function(response) {
            window.location.replace("/bugs");
        });
    });

    $(".reset").click(function(e) {
        e.preventDefault();
        $(this).closest('form').find("input").val("");
        $(this).closest('form').find("select").val("");
    });

    $("input[name='bug_range']").on("click", function(){
        if($('input[name="bug_range"]').prop('checked')) {
            $(".bugzilla_max").show();
        } else {
            $(".bugzilla_max").hide();
        }

    });

    $(function () {
        $('#myTab a:first').tab('show');
    });

    $('.rules').click(function () {
        var tab = $(this).attr("id");
        if(tab!="remove" && tab!="test") {
            $('.row.active').addClass('hidden').removeClass('active');
            $('.' + tab).addClass('active').removeClass('hidden');
        }
        $('.active').show();
        $('.hidden').hide();
    });

    $('#change_summary').click(function () {
        var headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()};
        var id = $('input[name="id"]').val();
        var summary = $('input[name="summary"]').val();
        $.ajax({
            url: "/bugs/" + id,
            method: 'PUT',
            data: {'bug': {'summary': summary}},
            headers: headers
        }).done(function (response) {
            $('.bug_summary').html(response.bug.summary);
        });
    });

    $('document').on('click', '#add_reference', function () {
        var headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()};
        var id = $('input[name="id"]').val();
        var reference = $('#reference-bugs-type').val();
        var content = $('input[name="content"]').val();
        $.ajax({
            url: "/bugs/" + id + "/references",
            method: 'POST',
            data: {reference: {'reference_data': content, 'reference_type_id': reference}},
            headers: headers
        }).done(function (response) {
            console.log(response);
            alert('success');
        });
    });


    $(document).on('click', '.connection, .scratch_connection', function () {
        var form = $(this).parents('.standard_form');
        if (form.find('.connection').prop("checked"))
        {
            form.find('.scratch_connection_text').prop('disabled', true);
        } else {
            form.find('.scratch_connection_text').prop('disabled', false);
        };
    });

    $(document).on('click', '.flow, .scratch_flow', function () {
        var form = $(this).parents('.standard_form');
        if (form.find('.flow').prop("checked"))
        {
            form.find('.scratch_flow_text').prop('disabled', true);
        } else {
            form.find('.scratch_flow_text').prop('disabled', false);
        };
    });
    $(document).on('click', '.metadata, .scratch_metadata', function () {
        var form = $(this).parents('.standard_form');
        if (form.find('.metadata').prop("checked"))
        {
            form.find('.scratch_metadata_text').prop('disabled', true);
        } else {
            form.find('.scratch_metadata_text').prop('disabled', false);
        };
    });

    var reference_form = '<div class="form-inline" style="padding:0 20px 10px 50px;">'+
        '<div class="form-group">'+
        '<select name="bug[rules][][reference][][reference_type_id]" class="form-control select-sm code">'+
        '<option class="text-muted" value="" selected> - </option>'+
        '"<% @ref_types.each do |ref| %> <option value=<%= ref.id %>><%= ref.name %></option><% end %>"'+
        '</select>'+
        '</div>'+
        '<div class="form-group">'+
        '<input class="form-control select-sm code" placeholder="reference data" name="bug[rules][][reference][][reference_data]" required="true">'+
        '</div>'+
        '<div class="form-group"> <button class="btn select-sm btn-link remove-ref">remove</button> </div>'+
        '</div>';

    $(document).on('click', '.add_reference_btn', function() {
        var reference = $(this).parents('.references_add');
        $(reference_form).appendTo(reference);
        return false;
    });

    $(document).on('click', '.remove-ref', function(e) {
        e.preventDefault();
        $(this).parents('.form-inline').remove();
    });


});
