#import("../lib/redis.dart");
#import("dart:utf");
//#import("../third_party/log4dart/LogLib.dart");

encode(cmd, [List args=null]) {
  StringBuffer sb = new StringBuffer();
  sb.add("*${args.length+1}\r\n\$${cmd.length}\r\n${cmd}\r\n");
  if (args is List) {
    args.forEach((parameter) {
      sb.add("\$${parameter.length}\r\n${parameter}\r\n");
    });
  }
  
  Utils.getLogger().debug("encode = ${sb.toString()}");
  return sb.toString();
}

decode(String res) {
  // http://redis.io/topics/protocol , Replies
  // TODO: do some error checking
  List resulting_data;
  String line = res.split('\n')[0];
  Utils.getLogger().debug("decode = $line");
  //String c = line[0];
  
  if (line[0] == "+") {
    //With a single line reply the first byte of the reply will be "+"
    Utils.getLogger().debug("decode = return OK");
    return line.substring(1); // OK
  }
  
  if (line.startsWith("-ERR")) {
    // With an error message the first byte of the reply will be "-"
    Utils.getLogger().debug("decode = throw -ERR");
    throw "Error: ${res}";
  }
  
  if (line[0] == ":") {
    //With an integer number the first byte of the reply will be ":"
   
    var n = Math.parseInt(line.substring(1).trim());
    Utils.getLogger().debug("decode = n = $n");
    return n;
  }
  
  if (line[0] == "*") {
    // With multi-bulk reply the first byte of the reply will be "*"
    int size = Math.parseInt(line.substring(1).trim());
    Utils.getLogger().debug("decode = size = $size");
    if (size <= 0) {
      return [];
    }
    

    var ret = [];
    for(int i=0; i<size; i++) {
      Utils.getLogger().debug("decode = loop = $i");
      resulting_data = res.split('\n');
      resulting_data.removeRange(0, 1);
      res = Strings.join(resulting_data, '\n');
      ret.add(read_bulk(res, ""));
    }
    
    Utils.getLogger().debug("decode = (*) return = $ret");
    return ret;
  }
  
  //resulting_data = res.split('\n');
  //resulting_data.removeRange(0, 1);
  //res = Strings.join(resulting_data, '\n');
  Utils.getLogger().debug("decode = read_bulk($res, $line)");
  return read_bulk(res, line);
}

read_bulk(String res, String head) {
  var data = [];
  if (head == "") {
    head = res.split('\n')[0];
  }
  
  switch (head[0]) {
    case ':':
      data = head.substring(1).trim();
      break;
      
    case '\$':
      var size = Math.parseInt(head.substring(1).trim());
      
      if (size == -1) {
        throw "size is \$-1";
      }
      
      List resulting_data = res.split('\n');
      resulting_data.removeRange(0, 1);
      res = Strings.join(resulting_data, '\n');
      data = res;
      break;
      
   default:
     throw "Error head does not contain command head[0] = ${head[0]}";
  }
  
  return data;
}

void main() {
  //print(encodeUtf8("\r\n SomeString \r\n".trim()));
  
  redisImpl r = new redisImpl();
  Utils.setVerboseState();
  r.open().then((v) {
    Utils.getLogger().debug("open = $v");
    
    //r.Set(1,"'1 1'").then( (String ret) {
    //r.Get("1").then( (String ret) {
    
    //The new unified request protocol: http://redis.io/topics/protocol 

    
 /*
 http://ideone.com/AASe4
 
 func encode(cmd string, argv ...string) []byte {
        buf := bytes.NewBufferString(fmt.Sprintf("*%d\r\n$%d\r\n%s\r\n",
                len(argv)+1, len(cmd), cmd))
        for _, v := range argv {
                buf.WriteString(fmt.Sprintf("$%d\r\n%v\r\n", len(v), v))
        }
        return buf.Bytes()
}
 
 */
//    StringBuffer cmd = new StringBuffer();
//    cmd.add("*3\r\n");
//    cmd.add("\$3\r\n");
//    cmd.add("SET\r\n");
//    cmd.add("\$5\r\n");
//    cmd.add("mykey\r\n");
//    cmd.add("\$7\r\n");
//    cmd.add("my alue\r\n");
//    String c = cmd.toString();
//    print("c = ${c}");
//    r.SendCommand(c).then((String ret) {
    r.SendCommand(encode("SET", ["myvalue", "my spaced string"])).then((String ret) {
    //r.SendCommand(encode("GET", ["myvalue"])).then((String ret) {
    //r.SendCommand(encode("LRANGE", ["mylist", "0", "3"])).then((String ret) {
      Utils.getLogger().debug("SendCommand =  $ret");
      var d = decode(ret);
      Utils.getLogger().debug("decode(ret) =  ${d}");
      List split_ret = ret.split('\r\n');
      Utils.getLogger().debug("split_ret =  ${split_ret}");
    });
  });
}

void mainx() {
  //Logger log = new LoggerImpl("main", debugEnabled: true, errorEnabled:true, infoEnabled:true, warnEnabled:true);
  redisImpl r = new redisImpl();
  //logger(); // set the default logger to verbose
  Utils.setVerboseState();
  r.open().then((v) {
    Utils.getLogger().debug("open = $v");
    
    //r.SendCommand("FLUSHALL");
    //r.FlushAll();
    //
    //r.Shutdown();
    //r.SendCommand("set blah 1").then((ret) {
    //r.SendCommand("keys *").then((String ret) {
    r.SendCommand("get d").then((String ret) {
      Utils.getLogger().debug("SendCommand =  $ret");
      List split_ret = ret.split('\r\n');
      Utils.getLogger().debug("split_ret =  $split_ret");
      Queue q = new Queue.from(split_ret);
      String num_args = q.removeFirst();
      int n = Math.parseInt(num_args[1]);
      var keys = [];
      for (int i = 0; i<n; i++) {
        String numBytes = q.removeFirst();
        String key = q.removeFirst();
        keys.add(key);
      }
      
      Utils.getLogger().debug("keys =  $keys");
      
      //redisImpl rr = new redisImpl();
      r.SendCommand("get blah").then((ret2) { 
        Utils.getLogger().debug("SendCommand2 =  $ret2"); 
        Queue qq = new Queue.from(ret2.split('\r\n'));
        Utils.getLogger().debug("qq =  $qq"); 
        qq.removeFirst();
        String val2 = qq.removeFirst();
        Utils.getLogger().debug("val2 =  $val2"); 
        
        r.connection.close();
      });
    });
    
  });
  Utils.getLogger().debug("hello world");
  
}