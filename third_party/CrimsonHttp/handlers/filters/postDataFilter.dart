class PostDataFilter  implements CrimsonFilter{
  Logger logger;
  CrimsonHttpServer server;
  
  
  final String NAME = "PostDataFilter";
 
  
  PostDataFilter() {
    logger = LoggerFactory.getLogger("postDataFilter");
    
  }
  
  Future<CrimsonData> handle(HttpRequest req, HttpResponse res, CrimsonData data) {
    
    Completer completer = new Completer();
    if (req.path.endsWith("favicon.ico")) {
      //don't do session checking for favicon
      return null;
    }
    
    print("PostDataFilter:handler:data = $data");
    print("PostDataFilter:handler:data = ${req.queryParameters}");
    req.inputStream.onData = () {
      int a = req.inputStream.available();
      var buf = new List(a);
      req.inputStream.readInto(buf, 0, a);
      print("reading data");
      print("buf = ${buf}");
      completer.complete(buf);
    };
    
    return completer.future;
  }
}
