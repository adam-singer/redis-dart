#import("../lib/redis.dart");
#import("dart:utf");

void main() {
  String okStr = "+OK";
  String getStr = "\$16\r\nmy spaced string\r\n";
  String listStr = "*4\r\n\$5\r\nWorld\r\n\$5\r\nHello\r\n\$3\r\nbar\r\n\$3\r\nfoo\r\n";
  Utils.setVerboseState();
  Decoder decoder = new Decoder(listStr);
  var i = decoder.decode();
  Utils.getLogger().debug("listStr = ${i.toString()}");
  decoder = new Decoder(getStr);
  i = decoder.decode();
  Utils.getLogger().debug("getStr = ${i.toString()}");
  decoder = new Decoder(okStr);
  i = decoder.decode();
  Utils.getLogger().debug("okStr = ${i.toString()}");
}

class Decoder {
  String data;
  int line = 0;
  int char = 0;
  Decoder(this.data);
  
  String readline() {
    char = 0;
    return data.split('\r\n')[line++];
  }
  
  String read(int c) {
    var ret_s = data.split('\r\n')[line].substring(char,c);
    char += c;
    return ret_s;
  }
  
  decode() {
    //Utils.getLogger().debug("data = ${resp.toString()}");
    String resp = readline();
    if (resp == null) {
      throw "resp is null";
    }
    
    if (resp.trim().endsWith("\$-1") || resp.trim().endsWith("*-1")) {
      return null;
    }
    
    var fb = resp[0];
    resp = resp.substring(1);
    Utils.getLogger().debug("fb = ${fb.toString()}");
    Utils.getLogger().debug("resp = ${resp.toString()}");
    
    if (fb == "+") {
      Utils.getLogger().debug("resp = ${resp.substring(resp.length-2)}");
      return resp.substring(resp.length-2);
    }
    
    if (fb == "-") {
      throw "ERR = ${resp}";
    }
    
    if (fb == ":") {
      Utils.getLogger().debug("Math.parseInt(resp) = ${Math.parseInt(resp)}");
      return Math.parseInt(resp);
    }
    
    if (fb == "\$") {
      int c = Math.parseInt(resp);
      resp = read(c);
      readline(); // advance to next line
      return resp;
    }
    
    if (fb == "*") {
      int j = Math.parseInt(resp);
      var ret = [];
      for (int i=0; i<j; i++) {
        ret.add(decode());
      }
      
      return ret;
    }
    
  }
}