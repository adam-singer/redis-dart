#library("connection_tests");

#import("../lib/redis.dart");
#import("dart:io");
#import('dart:builtin');
#import('../third_party/testing/unittest/unittest_vm.dart');

connectionTest() {
  Connection conn = new Connection();
  conn.connect().then((connected) {
    Expect.equals(true, connected);
    callbackDone();  
    conn.close();
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

void main () {
  Utils.setVerboseState();
  group("Connection tests:", () {
    asyncTest("Test socket connection",1, connectionTest);
    asyncTest("Test socket failed connection",1, connectionFailTest);
  });
}