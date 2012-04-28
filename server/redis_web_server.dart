#library('redis_web_server');

#import("../third_party/CrimsonHttp/core/CrimsonLib.dart");
#import("../third_party/CrimsonHttp/handlers/HandlersLib.dart");
#import("dart:io");
#import("dart:json");
#import("../lib/redis.dart", prefix:"redis");

///Simple test server
main() {
  redis.Utils.setVerboseState();
  CrimsonHttpServer server = new CrimsonHttpServer();
  
  CrimsonModule sampleModule = new CrimsonModule(server);
  sampleModule.handlers
                    .addEndpoint(new Favicon("./test/favicon.ico"))                   
                    .addFilter(new CookieSession())
                    .addEndpoint(new Route("/hello","GET",sayHello))
                    .addEndpoint(new Route("/exec","POST",execRedis))
                    .addEndpoint(new Route.withMatcher(matcherFunction,"helloMatcher",sayHello))
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
  var jsonString = """{
        "result" : ["Dart","Java","C#","Python"],
      }""";
 
  redis.Utils.getLogger().debug("execRedis: data = $data");
  
  sendBackJson() {
    
  res.outputStream.writeString(jsonString);
  completer.complete(null);
  

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