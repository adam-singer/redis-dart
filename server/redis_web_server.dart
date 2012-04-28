#library('redis_web_server');

#import("../third_party/CrimsonHttp/core/CrimsonLib.dart");
#import("../third_party/CrimsonHttp/handlers/HandlersLib.dart");
#import("dart:io");
#import("dart:json");
#import("../lib/redis.dart", prefix:"redis");
//#import("../lib/redis.dart");
#import("dart:utf");
///Simple test server
main() {
  redis.Utils.setVerboseState();
  CrimsonHttpServer server = new CrimsonHttpServer();
  
  CrimsonModule sampleModule = new CrimsonModule(server);
  sampleModule.handlers
                    .addEndpoint(new Favicon("./test/favicon.ico"))                   
                    //.addFilter(new CookieSession())
                    //.addFilter(new PostDataFilter())
                    //.addEndpoint(new Route("/hello","GET",sayHello))
                    .addEndpoint(new Route("/exec","POST",execRedis))
                    //.addEndpoint(new Route.withMatcher(matcherFunction,"helloMatcher",sayHello))
                    .addEndpoint(new StaticFile("./public"));
//  .addEndpoint(new StaticFile("./public/TerminalRedis.html"))
//  .addEndpoint(new StaticFile("./public/Terminal.dart"))
//  .addEndpoint(new StaticFile("./public/TerminalRedis.dart"));
//  

  server.modules["*"] = sampleModule;
   
  server.listen("127.0.0.1", 8082);
}

bool matcherFunction(HttpRequest req) {
  return req.path.endsWith("matcher");
}

Future execRedis(HttpRequest req,HttpResponse res,var data) {
  Completer completer = new Completer();
//  var jsonString = """{
//        "result" : ["Dart","Java","C#","Python"],
//      }""";
 
//  req.endD
  
  Map m = new Map();
  //m["result"] = "some cool result";
  
  redis.Utils.getLogger().debug("execRedis: data = $data");
  
  //Map clientData = JSON.parse(data);
  //redis.Utils.getLogger().debug("clientData: data = ${clientData.toString()}");
  
  sendBackJson() {
  //var s = JSON.stringify(m);
  //res.outputStream.writeString(s);
  
  
  req.inputStream.onData = () {
    //int a = req.inputStream.available();
    StringBuffer strBuffer = new StringBuffer();
    while (req.inputStream.available() > 0) {
      int a = req.inputStream.available();
      List buff = new List(a);
      req.inputStream.readInto(buff);
      print(buff);
      String dec = decodeUtf8(buff);
      strBuffer.add(dec);
      print ("command = ${dec}"); // dec has the posted message. 
    }
    
    var commands = JSON.parse(strBuffer.toString());
    // command = {"cmd":"get","args":["l","l"]}
    String cmd = commands["cmd"];
    redis.Connection conn;
    switch(cmd) {
      case "keys":
        conn = new redis.Connection();
        conn.connect().then((connected) {
          if (connected == true) {
            conn.SendCommand('KEYS', commands["args"]).then((ret) {
              m["result"] = ret;
              var retStr = JSON.stringify(m);
              
              res.outputStream.writeString(retStr);
              completer.complete(null);
            });
          }
        });
        break;
        
      case "get":
        conn = new redis.Connection();
        conn.connect().then((connected) {
          if (connected == true) {
            conn.SendCommand('GET', commands["args"]).then((ret) {
              m["result"] = ret[0];
              var retStr = JSON.stringify(m);
              
              res.outputStream.writeString(retStr);
              completer.complete(null);
            });
          }
        });
        
        break;
        
      case "set":
        conn = new redis.Connection();
        conn.connect().then((connected) {
          if (connected == true) {
            conn.SendCommand('SET', commands["args"]).then((ret) {
              m["result"] = ret;
              var retStr = JSON.stringify(m);
              
              res.outputStream.writeString(retStr);
              completer.complete(null);
            });
          }
        });
        break;
    };
    
   
    // when we are ready call this completer
    //completer.complete(null);
  };
  //completer.complete(null);
  };
  sendBackJson();
//  var session = data["SESSION"];
//  if (session != null) {
//    //res.outputStream.writeString("\nFirst Visit: " + session["first-accessed"]);
//    //res.outputStream.writeString("\nMost recent Visit: " + session["last-accessed"]);
//  }
  return completer.future; 
}

Future sayHello(HttpRequest req,HttpResponse res,var data) {
  res.outputStream.writeString("Hello");
  var session = data["SESSION"];
  if (session != null) {
    res.outputStream.writeString("\nFirst Visit: " + session["first-accessed"]);
    res.outputStream.writeString("\nMost recent Visit: " + session["last-accessed"]);
  }
  return null;  
}
