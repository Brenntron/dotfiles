// this maintains a websocket that the client can connect to
// the client receives live changes

var https = require('https');
var pem = require('pem');
var fs = require('fs');

pem.createCertificate({days:1, selfSigned:true}, function(err, keys) {
  var app = https.createServer({key: keys.serviceKey, cert: keys.certificate}, function (req, res) {
    console.log('server created...');
    res.end('Websocket server running');
  }).listen(7000);

  var io = require('socket.io')(app);
  io.on('connection', function(socket){
    console.log('a user connected');
    sendMessage('hi');

    socket.on('amq', function(msg){
      console.log('AMQ : ' + msg);
      io.emit('incoming', msg);
    });
    socket.on('join', function(msg){
      console.log('Client: ' + msg);
    });

    function sendMessage(msg){
      socket.emit('incoming', msg);
    }
  });
});