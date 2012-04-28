class RedisRequest {
  Completer<Object> completer;
  List<String> params;
  RedisRequest(this.completer, this.params);
}

class EncoderDecoder {
  int _state;
  int _argsLeft;
  List<String> _args;
  List<RedisRequest> _requestQueue;
  Function _sendBytes;
  final int START = 0;
  final int GET_NEXT_ARGUMENT = 1;
  final int GET_NEXT_ARGUMENT_CONTENT = 2;
  EncoderDecoder() {
    _state = START;
    _argsLeft = 0;
    _args = [];
    _requestQueue = [];
  }
  
  set sendBytes(Future<int> func(ByteArray bytes)) {
    _sendBytes = func;
  }
  
  RedisRequest _popAndEndFirstRequest() {
    var request = _requestQueue[0];
    _requestQueue.removeRange(0, 1);
    if(_requestQueue.length > 0)
      _startNextRequest();
    return request;
  }
  _completeFirstRequest(Object response) {
    _popAndEndFirstRequest().completer.complete(response);
  }
  
  _completeExceptionFirstRequest(Exception exception) {
    _popAndEndFirstRequest().completer.completeException(exception);
  }
  
  handleReceivedLine(String line, Function nextLineSizeIs) {
    // If no request was received
    if(_requestQueue.length == 0) {
      Utils.getLogger().error("No request issued, but a line was received from the redis server: ${line}");
      return; 
    }
    if(line == null) {
      Utils.getLogger().error("Received null line");
      return;
    }
    
    switch(_state) {
      case START:
        
        var fb = line[0];
        line = line.substring(1);
        Utils.getLogger().debug("fb = ${fb.toString()}");
        Utils.getLogger().debug("resp = ${line.toString()}");
        
        if (fb == "+") {
          _completeFirstRequest(true);
        } else if (fb == "-") {
          _completeExceptionFirstRequest(new Exception("remote error ${line}"));
        } else if (fb == ":") {
          Utils.getLogger().debug("Math.parseInt(resp) = ${Math.parseInt(line)}");
          
          // TODO(waltercacau): Maybe check if it is really an integer here? Can parseInt throw an exception
          _completeFirstRequest([Math.parseInt(line)]);
          
        } else if (fb == "*") {
          _argsLeft = Math.parseInt(line);
          _state = GET_NEXT_ARGUMENT;
        } else if (fb == "\$") {
          int size = Math.parseInt(line);
          if(size >= 0) {
            _argsLeft = 1;
            nextLineSizeIs(size);
            _state = GET_NEXT_ARGUMENT_CONTENT;
          } else {
            _completeFirstRequest([null]);
          }
        } else {
          _completeExceptionFirstRequest(new Exception("Unexpected line received: ${fb}${line}"));
        }
        
        break;
      
      case GET_NEXT_ARGUMENT:
        var fb = line[0];
        line = line.substring(1);
        
        if (fb == "\$") {
          int size = Math.parseInt(line);
          if(size >= 0) {
            nextLineSizeIs(size);
            _state = GET_NEXT_ARGUMENT_CONTENT;
          } else {
            _addNextArgument(null);
          }
        } else {
          _completeExceptionFirstRequest(new Exception("Unexpected line received: ${fb}${line}"));
        }
        break;
      
      case GET_NEXT_ARGUMENT_CONTENT:
        _addNextArgument(line);
        break;
    }
  }
  _addNextArgument(Object arg) {
    _args.add(arg);
    _argsLeft--;
    if(_argsLeft == 0) {
      _completeFirstRequest(_args);
      _args = [];
      _state = START;
    } else {
      _state = GET_NEXT_ARGUMENT;
    }
  }
  
  Future<Object> sendRequest(List<String> params) {
    if(params.length == 0)
      throw "Request params should not be empty!";
    RedisRequest request = new RedisRequest(new Completer<Object>(), params);
    _requestQueue.add(request);
    if(_requestQueue.length == 1)
      _startNextRequest();
    return request.completer.future;
  }
  _startNextRequest() {
    List bytes = [];
    RedisRequest request = _requestQueue[0];
    bytes.addAll('\*${request.params.length}\r\n'.charCodes());
    for(String param in request.params) {
      List paramInBytes = encodeUtf8(param);
      bytes.addAll('\$${paramInBytes.length}\r\n'.charCodes());
      bytes.addAll(paramInBytes);
      bytes.addAll('\r\n'.charCodes());
    }
    Future<int> future = _sendBytes(bytes);
    future.then((int written) {
      if(written != bytes.length)
        _completeExceptionFirstRequest(new Exception('Written only ${written}, but needed to write ${bytes.length}'));
    });
    future.handleException((Exception exception) {
      _completeExceptionFirstRequest(exception);
    });
  }
}