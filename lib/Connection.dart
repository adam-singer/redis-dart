class Connection {
  Map<int,Completer<Object>> replyCompleters;
  ByteArray lengthBuffer;
  ServerConfig serverConfig;
  ByteArray bufferToSend;
  Queue<Object> sendQueue;
  ByteArray messageBuffer;
  Socket socket;  
  
  Connection([this.serverConfig]) {
    if (serverConfig === null) {
      serverConfig = new ServerConfig();
    }
  }
  
  Future<bool> connect() {
    socket = new Socket(serverConfig.host, serverConfig.port);
    Completer completer = new Completer();
    
    if (socket is! Socket) {
      completer.completeException(new Exception( "can't get send socket"));
    } else {
      socket.onError = (e) {  
        Utils.getLogger().debug("connect exception ${e}");
        completer.completeException(e);
      };
      socket.onConnect = () {
        if (!serverConfig.password.isEmpty()) {
          // TODO: send auth command
        }
        
        completer.complete(true);
      };
      return completer.future;
    }
  }
  
  close() {
    socket.onData = null;
    socket.onWrite = null;
    socket.onError = null;
    socket.close();
  }
  
  sendBufferFromOnWrite() => sendBuffer("from OnWrite");
  sendBuffer(String origin){
    
    // When done sending the data null the write. 
    socket.onWrite = null; 
  }
  
  receiveData() {

  }
  
  String end_data = '\r\n';
  Future<Object> sendCommand(String message) {
    // Add data to queue
    Completer completer = new Completer();
    socket.onWrite = () {
      Utils.getLogger().debug("Connection.sendCommand = $message");
      List m = encodeUtf8("$message");
      //m.add(0);
      //m.addAll(encodeUtf8(end_data));
      //var m = encodeUtf16("$message");
      
//      var m = [];
//      m.addAll(mm);
//      m.add(0);
//      m.addAll(encodeUtf8(end_data));
      
      Utils.getLogger().debug("Connection.sendCommand = $m");
      socket.writeList(m, 0, m.length);
      socket.onWrite = null;
    };
    
    socket.onData = () {
      var available = socket.available();
      if (available == 0) {
        completer.complete(null);
      }
        
      
      ByteArray buffer = new ByteArray(available);
      int numBytes = socket.readList(buffer, 0, available);
      socket.onData = null;
      
      
      String r = decodeUtf8(buffer, 0, numBytes);
      Utils.getLogger().debug("response = $r");
      
      // TODO: decode data here?
      completer.complete(r);
    };
    
    return completer.future;
  }
}