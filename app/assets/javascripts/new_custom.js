$(document).ready(function() {

    $('.active').show();
    $('.hidden').hide();

    $('#button_import').click(function() {
        var headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()};
        var id = $('#import_bug').val();
        $.ajax({
            url: "/api/v1/bugs/import/" + id,
            method: 'GET',
            headers: headers
        }).done(function(response) {
            window.location.replace("/bugs/"+id);
        });
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


});
