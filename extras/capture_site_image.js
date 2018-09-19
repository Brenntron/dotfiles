var system = require('system');
var url = system.args[1];
var page = new WebPage();
var width = 1024;
var height = 768;

page.viewportSize = {width: width, height: height};
page.open(url, function (status) {
  page.evaluate(function(w, h) {
    document.body.style.width = w + "px";
    document.body.style.height = h + "px";
  }, width, height);
  page.clipRect = {top: 0, left: 0, width: width, height: height};
  var base64 = page.renderBase64('JPEG');
  console.log(base64);
  page.close();
  phantom.exit();
});
