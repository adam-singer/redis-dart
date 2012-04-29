#library("connection_tests");

#import("../lib/redis-dart.dart");
#import("dart:io");
#import("dart:utf");
#import('dart:builtin');
#import('../third_party/testing/unittest/unittest_vm.dart');

connectionTest() {
  final Connection conn = new Connection();
  String unsetKey = 'REALLY_UNKNOWN_KEY_THAT_SHOULD_NOT_BE_SET_IN_REDIS';
  List<List<String>> keyValuePairs = [
     ['key', 'va\r\nÀue'],
     ['henry', 'is cool'],
     ['empty', ''],
     ['pushingIt','Iñtërnâtiônàlizætiøn'],
     ['Iñtërnâtiônàlizætiøn','i18n']
  ];

  conn.connect().then((connected) {
    int remaningCount = 2*keyValuePairs.length+1;
    int doneCount = 0;
    internalCallbackDone() {
      doneCount++;
      if(doneCount == remaningCount) {
        conn.close();
        callbackDone();
      }
    }
    
    Expect.equals(true, connected);
    final List<String> keyList = [];
    final List<String> valueList = [];
    // SET
    for(final List<String> pair in keyValuePairs) {
      keyList.add(pair[0]);
      valueList.add(pair[1]);
      conn.SendCommand('SET', pair).then((Object ret) {
        expect(ret).equals(true);
        internalCallbackDone();
      });
      conn.SendCommand('GET', [pair[0]]).then((List retBack) {
        expect(retBack).equalsCollection([pair[1]]);
        internalCallbackDone();
      });
    }
    keyList.add(unsetKey);
    valueList.add(null);
    conn.SendCommand('MGET', keyList).then((List retBack) {
      expect(retBack).equalsCollection(valueList);
      internalCallbackDone();
    });
    
  });
}

connectionFailTest() {
  ServerConfig serverConfig = new ServerConfig("127.0.0.1", 9999);
  Connection conn = new Connection(serverConfig);
  
  Future f = conn.connect();
  f.then((connected) {
    Expect.equals(false, connected);
  });
  
  f.handleException((o) {
    callbackDone(); 
    //conn.close();
    return true;
  });
}

handleDataChunkTest() {
  Connection conn =  new Connection();
  List<String> expected = [
    'line1',
    'startline2 endline2',
    '\n',
    'lineA\r\nlineB',
    'lineA',
    'lineB',
    'lineA\r\nlineB',
  ];
  int expectedIdx = 0;
  Function nextLineSizeIsFunc = null;
  conn.onReceiveLine = (String line, Function nextLineSizeIs) {
    expect(line).equals(expected[expectedIdx++]);
    nextLineSizeIsFunc = nextLineSizeIs;
  };
  conn.handleDataChunk(encodeUtf8('line1\r\nstartline2'));
  conn.handleDataChunk(encodeUtf8(' endline2\r'));
  conn.handleDataChunk(encodeUtf8('\n\n'));
  conn.handleDataChunk(encodeUtf8('\r\n'));
  nextLineSizeIsFunc(12);
  conn.handleDataChunk(encodeUtf8('lineA\r\nlineB\r\n'));
  conn.handleDataChunk(encodeUtf8('lineA\r\nlineB\r\n'));
  nextLineSizeIsFunc(12);
  conn.handleDataChunk(encodeUtf8('lineA\r'));
  conn.handleDataChunk(encodeUtf8('\nli'));
  conn.handleDataChunk(encodeUtf8('neB\r\n'));
  
  expect(expectedIdx).equals(expected.length);
}

void main () {
  Utils.setVerboseState();
  group("Connection tests:", () {
    asyncTest("Test socket connection and set", 1, connectionTest);
    asyncTest("Test socket failed connection",1, connectionFailTest);
    test("Test receiving data chunk", handleDataChunkTest);
  });
}