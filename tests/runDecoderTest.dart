#import("../lib/redis.dart");
#import("dart:utf");

void main() {
  int nextLineSizeIsCallsCount = 0; 
  int lastNextLineSizeIsCallsCount = 0;
  int lastCallbacksCount = 0; 
  int callbacksCount = 0;
  List lastSentBytes = null;
  expectNotToSend() {
    if(lastSentBytes != null) {
      String sentString = decodeUtf8(lastSentBytes);
      throw 'Expected not to send, but got: ${sentString}';
    } else {
      print("Expectation OK: not to send");
    }
  }
  expectToSend(String actual) {
    if(lastSentBytes == null)
      throw "No bytes sent!";
    String expected = decodeUtf8(lastSentBytes);
    if("${actual}" != "${expected}")
      throw "${actual} != ${expected}";
    else
      print("Expectation OK: sent correct bytes");
    lastSentBytes = null;
  }
  Utils.setVerboseState();
  
  
  Future<int> fakeSendBytes(List bytes) {
    if(lastSentBytes != null) {
      String sentString = decodeUtf8(lastSentBytes);
      throw 'There are bytes in the test buffer that were not expected: ${sentString}';
    }
    lastSentBytes = bytes;
    Completer<int> completer = new Completer<int>();
    completer.complete(bytes.length);
    return completer.future;
  };
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
        print("Expectation OK: callback called correctly");
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
  
  // Building the encoder/decoder
  EncoderDecoder decoder = new EncoderDecoder();
  decoder.sendBytes = fakeSendBytes;
  
  // Sending tree request to exercise queuing
  decoder.sendRequest(['SET','mykey','myvalue']).then(futureCallbackBuilder(true));
  expectToSend('*3\r\n\$3\r\nSET\r\n\$5\r\nmykey\r\n\$7\r\nmyvalue\r\n');
  decoder.sendRequest(['request2']).then(futureCallbackBuilder(['my spaced string']));
  expectNotToSend();
  decoder.sendRequest(['request3']).then(futureCallbackBuilder(['World','Hello','bar','foo']));
  expectNotToSend();
  
  decoder.handleReceivedLine('+OK', nextLineSizeIsFailIfCalled);
  expectCallbackCountIncrease();
  expectToSend('*1\r\n\$8\r\nrequest2\r\n');
  
  decoder.handleReceivedLine('*1', nextLineSizeIsFailIfCalled);
  decoder.handleReceivedLine('\$16', nextLineSizeIsFuncBuilder(16)); expectNextLineSizeIsCallsCountIncrease();
  decoder.handleReceivedLine('my spaced string', nextLineSizeIsFailIfCalled);
  expectCallbackCountIncrease();
  expectToSend('*1\r\n\$8\r\nrequest3\r\n');
  
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
  expectNotToSend();
  
  // Corner cases
  // À = 2 bytes in UTF8
  decoder.sendRequest(['request4','À']).then(futureCallbackBuilder([null]));
  expectToSend('*2\r\n\$8\r\nrequest4\r\n\$2\r\nÀ\r\n');
  decoder.handleReceivedLine('\$-1', nextLineSizeIsFailIfCalled);
  expectCallbackCountIncrease();
  
  decoder.sendRequest(['request5']).then(futureCallbackBuilder([null]));
  expectToSend('*1\r\n\$8\r\nrequest5\r\n');
  decoder.handleReceivedLine('*1', nextLineSizeIsFailIfCalled);
  decoder.handleReceivedLine('\$-1', nextLineSizeIsFailIfCalled);
  expectCallbackCountIncrease();
  
  decoder.sendRequest(['request6']).handleException(futureCallbackBuilder('Exception: remote error ERROR'));
  expectToSend('*1\r\n\$8\r\nrequest6\r\n');
  decoder.handleReceivedLine('-ERROR', nextLineSizeIsFailIfCalled);
  expectCallbackCountIncrease();
  
  // Problems in communication
  decoder.sendRequest(['request7']).handleException(futureCallbackBuilder('Exception: Unexpected line received: ?haha'));
  expectToSend('*1\r\n\$8\r\nrequest7\r\n');
  decoder.handleReceivedLine('*1', nextLineSizeIsFailIfCalled);
  decoder.handleReceivedLine('?haha', nextLineSizeIsFailIfCalled);
  expectCallbackCountIncrease();
  
}