#library("command_tests");

#import("../lib/redis-dart.dart");
#import("dart:io");
#import('dart:builtin');
#import('../third_party/testing/unittest/unittest_vm.dart');

fluashAllTest() {
  Redis r = new Redis();
  
  r.open().then((bool connected) {
    Utils.getLogger().debug("connected = $connected");
    
    if (connected) {
      r.FlushAll().then((v) {
        Utils.getLogger().debug("response = $v");
        callbackDone();  
        r.connection.close();
      });
    }
    
    //callbackDone();  
  });
  
  
  
//  Connection conn = new Connection();
//  conn.connect().then((connected) {
//    
//    Expect.equals(true, connected);
//    callbackDone();  
//  }); 
}



void main() {
  Utils.setVerboseState();
  group("Command tests:", () {
    asyncTest("Test socket connection",1, fluashAllTest);
    // asyncTest("Test socket failed connection",1, connectionFailTest);
  });
}