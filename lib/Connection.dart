#library('Connection');
#import("dart:io");
#import("dart:utf");
#import("ServerConfig.dart");

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
  }
  
  set onReceiveLine(void callback(ByteArray line)) {
    _onReceiveLine = callback;
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
  void nextLineSizeIs(int size) {
    if(receivedBytesCount > 0)
      throw new Exception('You should not call nextLineSizeIs if there are pending bytes on the buffer for next line.');
    skipCount = size;
  }

  
  /**
   * Callback for receiving messages.
   */
  _onData() {
    List currentChunk = socket.inputStream.read(socket.available());
    _onDataChunk(currentChunk);
  }
  
  _onDataChunk(List currentChunk) {
    
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
        
        _onReceiveLine(line);
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
  
  sendBufferFromOnWrite() => sendBuffer('from OnWrite');
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
      Utils.getLogger().debug('Connection.sendCommand = $message');
      List m = encodeUtf8("$message");
      //m.add(0);
      //m.addAll(encodeUtf8(end_data));
      //var m = encodeUtf16("$message");
      
//      var m = [];
//      m.addAll(mm);
//      m.add(0);
//      m.addAll(encodeUtf8(end_data));
      
      Utils.getLogger().debug('Connection.sendCommand = $m');
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
      Utils.getLogger().debug('response = $r');
      
      // TODO: decode data here?
      completer.complete(r);
    };
    
    return completer.future;
  }
}

assertEquals(a, b) {
  if(a!=b)
    throw new Exception("$a !== $b");
  print("Assert ok!");
}

void main() {
  Connection conn =  new Connection();
  List<String> expected = [
    'line1',
    'startline2 endline2',
    '\n',
    'lineA\r\nlineB',
    'lineA',
    'lineB'
  ];
  int expectedIdx = 0;
  conn.onReceiveLine = (ByteArray bline) {
    String line = decodeUtf8(bline);
    assertEquals(line, expected[expectedIdx++]);
  };
  conn._onDataChunk(encodeUtf8('line1\r\nstartline2'));
  conn._onDataChunk(encodeUtf8(' endline2\r'));
  conn._onDataChunk(encodeUtf8('\n\n'));
  conn._onDataChunk(encodeUtf8('\r\n'));
  conn.nextLineSizeIs(12);
  conn._onDataChunk(encodeUtf8('lineA\r\nlineB\r\n'));
  conn._onDataChunk(encodeUtf8('lineA\r\nlineB\r\n'));
  assertEquals(expectedIdx, expected.length);
}