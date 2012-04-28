#library("redis_tests");

#import("../lib/redis.dart");
#import("dart:io");
#import('dart:builtin');
#import('../third_party/testing/unittest/unittest_vm.dart');

void testSet(Redis client) {
  client.set("key1", "value1").then({
		Expect.equals("value1", client.get("key1"));
  });
  
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

void testGet() {
	
}

void main() {
	Utils.setVerboseState();
	Redis redis = new Redis();
	group("Connection tests:", () {
	  asyncTest("Test get value", 1, testGet(redis));
	  asyncTest("Test set value", 1, testSet(redis));
	  // asyncTest("Test socket failed connection",1, connectionFailTest);
	});    
}