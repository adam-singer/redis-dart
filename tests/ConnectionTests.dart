#library("connection_tests");

#import("../lib/redis.dart");
#import("dart:io");
#import("dart:utf");
#import('dart:builtin');
#import('../third_party/testing/unittest/unittest_vm.dart');

connectionTest() {
  Connection conn = new Connection();
  List<List<String>> keyValuePairs = [
     ['key', 'va\r\nÀue'],
     ['henry', 'is cool']
  ];

  conn.connect().then((connected) {
    Expect.equals(true, connected);
    callbackDone();
    
    // SET
    var doneCount = 0;
    for(final List<String> pair in keyValuePairs) {
      conn.SendCommand('SET', pair).then((Object ret) {
        expect(ret).equals(true);
        callbackDone();
        
        conn.SendCommand('GET', [pair[0]]).then((Object retBack) {
          expect(retBack.length).equals(1);
          expect(retBack[0]).equals(pair[1]);
          callbackDone();
          doneCount++;
          if(doneCount == keyValuePairs.length) {
            conn.close();
          }
        });
        
      });
    }
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
    asyncTest("Test socket connection and set", 5, connectionTest);
    asyncTest("Test socket failed connection",1, connectionFailTest);
    test("Test receiving data chunk", handleDataChunkTest);
  });
}