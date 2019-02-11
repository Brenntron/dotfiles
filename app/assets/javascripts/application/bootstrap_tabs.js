/**
 * Created by mtaylor on 12/18/18.
 */

/* Below allows tabs to be linked to directly from other pages so on page load a specific tab can be opened */

$(function(){
    var hash = window.location.hash;
    hash && $('ul.nav a[href="' + hash + '"]').tab('show');

    $('.nav-tabs a').click(function (e) {
        $(this).tab('show');
        var scrollmem = $('body').scrollTop() || $('html').scrollTop();
        window.location.hash = this.hash;
        $('html,body').scrollTop(scrollmem);
    });
});

$(function(){
    var hash = window.location.hash;
    hash && $('.nav-tab-button[href="' + hash + '"]').tab('show');

    $('.nav-tab-button').click(function (e) {
        $(this).tab('show');
        var scrollmem = $('body').scrollTop() || $('html').scrollTop();
        window.location.hash = this.hash;
        $('html,body').scrollTop(scrollmem);
    });
});
