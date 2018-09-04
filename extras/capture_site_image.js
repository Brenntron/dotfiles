var system = require('system');
var url = system.args[1];
var filename = system.args[2];
var page = new WebPage();

page.viewportSize = {
  width: 800,
  height: 600
};
page.open(url, function (status) {
  var base64 = page.renderBase64('PNG');
  console.log(base64);
  page.close();
  phantom.exit();
});
