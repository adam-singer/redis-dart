// Char constants
int CR = 13;
int LF = 10;

/**
 * Handles connection with a Reddis server
 * doing line buffering.
 */
class Connection {
  ByteArray lengthBuffer;
  ServerConfig serverConfig;
  ByteArray bufferToSend;
  Queue<Object> sendQueue;
  ByteArray messageBuffer;
  Socket socket;
  Function _onReceiveLine;
  Function _sendRequest;
  
  Connection([this.serverConfig]) {
    if (serverConfig === null) {
      serverConfig = new ServerConfig();
    }
    // Some preconditions check
    if (!serverConfig.password.isEmpty()) {
      throw new UnsupportedOperationException('Password connections are not implemented yet');
    }
    // Default values
    _lastWasCR = false;
    receivedChunks = [];
    receivedBytesCount = 0;
    skipCount = 0;
    
    // Bundling in the encoderDecoder by default
    EncoderDecoder encoderDecoder = new EncoderDecoder();
    encoderDecoder.sendBytes = sendBytes;
    onReceiveLine = encoderDecoder.handleReceivedLine;
    sendRequest = encoderDecoder.sendRequest;
  }
  
  set onReceiveLine(void callback(String line, Function nextLineSizeIs)) {
    _onReceiveLine = callback;
  }
  
  set sendRequest(Future<Object> func(List<String> params)) {
    _sendRequest = func;
  }

  // State variables for reading a line according to Regis
  /**
   * Chunks received but we known they don't form a complete line yet
   */
  List<List> receivedChunks;
  /**
   * Last character read was a CR
   */
  bool _lastWasCR;
  /**
   * Sum of lengths of each element of receivedChunks.
   */
  int receivedBytesCount;
  int skipCount;

  /**
   * It is possible that in the middle of a line a CRLF might appear.
   * So with information comming from the parsing of the message one could
   * inform this layer which size what will be the supposed size of the next line,
   * so if we find CRLF in the middle we can skip because we know is not the end of
   * the logical Regis line. 
   */
  void _nextLineSizeIs(int size) {
    if(receivedBytesCount > 0)
      throw new Exception('You should not call nextLineSizeIs if there are pending bytes on the buffer for next line.');
    skipCount = size;
  }

  
  /**
   * Callback for receiving messages.
   */
  _onData() {
    int len = socket.available();
    List currentChunk = new ByteArray(len);
    int readCount = socket.readList(currentChunk, 0, len);
    if(readCount != len) {
      throw 'couldn\'t read all avaiable bytes (${len}), only ${readCount}';
    }
    handleDataChunk(currentChunk);
  }
  
  /**
   * It deals with data chunks received.
   *
   * Visible for testing only! Please, do not call it!
   */
  handleDataChunk(List currentChunk) {
    
    bool found;
    do {
      // Finding CRLF (it will actually point to LF position)
      int i = Math.min(skipCount, currentChunk.length);
      skipCount -= i;
      for(; i < currentChunk.length; i++) {
        if(currentChunk[i]==LF && _lastWasCR) {
          break;
        }
        _lastWasCR = currentChunk[i] == CR;
      }
      
      found = i < currentChunk.length;
      
      if(found) {
        
        // Allocating bytearray for current line
        ByteArray line = new ByteArray(receivedBytesCount+i-1);
        
        // i=0 means the \r was in the last chunk and
        // i=1 means the beggining of this chunk 
        // i>0 means we still got something to add to the line
        if(i>1)
          receivedChunks.add(currentChunk.getRange(0, i-1));
        
        int lineIdx = 0;
        for(final List receivedChunk in receivedChunks) {
          for(int chunkIdx=0; chunkIdx < receivedChunk.length && lineIdx < line.length; chunkIdx++) {
            line[lineIdx++]=receivedChunk[chunkIdx];
          }
        }
        
        // Setting up state variables for next time
        receivedBytesCount = 0;
        receivedChunks = [];
        _lastWasCR = false;
        
        // Storing what was not used for the current line in the
        // receivedChunks
        if(currentChunk.length>i+1) {
          currentChunk = currentChunk.getRange(i+1, currentChunk.length-(i+1));
        } else {
          currentChunk = [];
        }
        
        _onReceiveLine(decodeUtf8(line), this._nextLineSizeIs);
      }
    } while(found);
    
    if(currentChunk.length > 0) {
      receivedBytesCount += currentChunk.length;
      receivedChunks.add(currentChunk);
    }
  }
  
  Future<bool> connect() {
    socket = new Socket(serverConfig.host, serverConfig.port);
    Completer completer = new Completer();
    
    if (socket is! Socket) {
      completer.completeException(new Exception('can\'t get send socket'));
    } else {
      socket.onError = (e) {  
        Utils.getLogger().debug('connect exception ${e}');
        completer.completeException(e);
      };
      socket.onConnect = () {
        completer.complete(true);
      };
      
      socket.onData = this._onData;
      return completer.future;
    }
  }
  
  close() {
    socket.onData = null;
    socket.onWrite = null;
    socket.onError = null;
    socket.close();
  }
  
  
  String end_data = '\r\n';
  Future<int> sendBytes(List bytes) {
    Completer completer = new Completer();
    socket.onWrite = () {
      completer.complete(socket.writeList(bytes, 0, bytes.length));
      // TODO(waltercacau): How to catch IO errors here?
      socket.onWrite = null;
    };
    return completer.future;
  }
  
  Future<Object> SendCommand(String cmd, [args = const[]]) {
    List params = [cmd];
    params.addAll(args);
    return _sendRequest(params);
  }
}