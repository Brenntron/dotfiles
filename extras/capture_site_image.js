var system = require('system');
var args = system.args;

var page = require('webpage').create();
page.onResourceError = function(resourceError) {
    page.reason = resourceError.errorString;
    page.reason_url = resourceError.url;
};

page.viewportSize = {
    width: 1024,
    height: 768,
};

// Set a custom UA String
page.settings.userAgent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/71.0.3578.98 Safari/537.36';
page.settings.resourceTimeout = 5000;

page.open("http://" + args[1], function(status) {
    if (status == 'success') {

        // Fix for transparent backgrounds causing black images
        page.evaluate(function() {
            var text = document.createTextNode('body { background: #fff }');
            var style = document.createElement('style');
            style.setAttribute('type', 'text/css');
            style.appendChild(text);
            document.head.insertBefore(style, document.head.firstChild);
        });

        // Wait settleSeconds seconds before grabbing the image
        window.setTimeout(function () {
            page.clipRect = {top: 0, left: 0, width: 1024, height: 768};
            var base64 = page.renderBase64('JPEG');
            console.log(base64);
            // page.render(args[2]);
            phantom.exit(0);
        }, 1000);

    } else {
        console.log(
            "Error opening url \"" + page.reason_url
            + "\": " + page.reason
        );
        phantom.exit(1);
    }
});
