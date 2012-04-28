#import("../lib/redis.dart");
#import("dart:utf");

void main() {
  int nextLineSizeIsCallsCount = 0; 
  int lastNextLineSizeIsCallsCount = 0;
  int lastCallbacksCount = 0; 
  int callbacksCount = 0;
  Utils.setVerboseState();
  Decoder decoder = new Decoder();
  Function nextLineSizeIsFuncBuilder(int expectedSize) {
    return (int size) {
      nextLineSizeIsCallsCount++;
      if(size != expectedSize)
        throw "${size} != ${expectedSize}";
    };
  };
  Function nextLineSizeIsFailIfCalled = (int size){
    throw "nextLineSizeIs should not have been called";
  };
  Function futureCallbackBuilder(Object expected) {
    return (Object actual) {
      callbacksCount++;
      if("${actual}" != "${expected}")
        throw "${actual} != ${expected}";
      else
        print("Expectation OK: ${actual} == ${expected}");
    };
  }
  Function expectCallbackCountIncrease() {
    lastCallbacksCount++;
    if(lastCallbacksCount != callbacksCount)
      throw "callbackCount: ${callbacksCount} != ${lastCallbacksCount}";
    else
      print("Expectation OK: Callback called");
  }
  Function expectNextLineSizeIsCallsCountIncrease() {
    lastNextLineSizeIsCallsCount++;
    if(lastNextLineSizeIsCallsCount != nextLineSizeIsCallsCount)
      throw "callbackCount: ${nextLineSizeIsCallsCount} != ${lastNextLineSizeIsCallsCount}";
    else
      print("Expectation OK: Callback called");
  }
  
  // Sending tree request to exercise queuing
  decoder.sendRequest(['request1']).then(futureCallbackBuilder(true));
  decoder.sendRequest(['request2']).then(futureCallbackBuilder(['my spaced string']));
  decoder.sendRequest(['request3']).then(futureCallbackBuilder(['World','Hello','bar','foo']));
  
  decoder.handleReceivedLine('+OK', nextLineSizeIsFailIfCalled);
  expectCallbackCountIncrease();
  
  decoder.handleReceivedLine('*1', nextLineSizeIsFailIfCalled);
  decoder.handleReceivedLine('\$16', nextLineSizeIsFuncBuilder(16)); expectNextLineSizeIsCallsCountIncrease();
  decoder.handleReceivedLine('my spaced string', nextLineSizeIsFailIfCalled);
  expectCallbackCountIncrease();
  
  decoder.handleReceivedLine('*4', nextLineSizeIsFailIfCalled);
  decoder.handleReceivedLine('\$5', nextLineSizeIsFuncBuilder(5)); expectNextLineSizeIsCallsCountIncrease();
  decoder.handleReceivedLine('World', nextLineSizeIsFailIfCalled);
  decoder.handleReceivedLine('\$5', nextLineSizeIsFuncBuilder(5)); expectNextLineSizeIsCallsCountIncrease();
  decoder.handleReceivedLine('Hello', nextLineSizeIsFailIfCalled);
  decoder.handleReceivedLine('\$3', nextLineSizeIsFuncBuilder(3)); expectNextLineSizeIsCallsCountIncrease();
  decoder.handleReceivedLine('bar', nextLineSizeIsFailIfCalled);
  decoder.handleReceivedLine('\$3', nextLineSizeIsFuncBuilder(3)); expectNextLineSizeIsCallsCountIncrease();
  decoder.handleReceivedLine('foo', nextLineSizeIsFailIfCalled);
  expectCallbackCountIncrease();
  
  // Corner cases
  decoder.sendRequest(['request4']).then(futureCallbackBuilder([null]));
  decoder.handleReceivedLine('\$-1', nextLineSizeIsFailIfCalled);
  expectCallbackCountIncrease();
  
  decoder.sendRequest(['request5']).then(futureCallbackBuilder([null]));
  decoder.handleReceivedLine('*1', nextLineSizeIsFailIfCalled);
  decoder.handleReceivedLine('\$-1', nextLineSizeIsFailIfCalled);
  expectCallbackCountIncrease();
  
  decoder.sendRequest(['request6']).handleException(futureCallbackBuilder('Exception: remote error ERROR'));
  decoder.handleReceivedLine('-ERROR', nextLineSizeIsFailIfCalled);
  expectCallbackCountIncrease();
  
  // Problems in communication
  decoder.sendRequest(['request5']).handleException(futureCallbackBuilder('Exception: Unexpected line received: ?haha'));
  decoder.handleReceivedLine('*1', nextLineSizeIsFailIfCalled);
  decoder.handleReceivedLine('?haha', nextLineSizeIsFailIfCalled);
  expectCallbackCountIncrease();
  
}

class Request {
  Completer<Object> completer;
  List<String> params;
  Request(this.completer, this.params);
}

class Decoder {
  int _state;
  int _argsLeft;
  List<String> _args;
  List<Request> _requestQueue;
  final int START = 0;
  final int GET_NEXT_ARGUMENT = 1;
  final int GET_NEXT_ARGUMENT_CONTENT = 2;
  Decoder() {
    _state = START;
    _argsLeft = 0;
    _args = [];
    _requestQueue = [];
  }
  
  Request _popAndEndFirstRequest() {
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
    Request request = new Request(new Completer<Object>(), params);
    _requestQueue.add(request);
    if(_requestQueue.length == 1)
      _startNextRequest();
    return request.completer.future;
  }
  _startNextRequest() {
    // TODO(waltercacau): implement it
  }
}