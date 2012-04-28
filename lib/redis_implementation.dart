#library("redis");
#import("dart:io");
#import("dart:utf");
#import("../third_party/log4dart/LogLib.dart");
#source("redis.dart");
#source("utils.dart");
#source("server_config.dart");
#source("EncoderDecoder.dart");
#source("connection.dart");

class RedisImpl implements Redis {
  
  ServerConfig serverConfig;
  Connection connection;
  
  RedisImpl([this.serverConfig]) {
    if (serverConfig === null) {
      serverConfig = new ServerConfig();
     }
    
    connection = new Connection(serverConfig);
  }
  
  Future<bool> open() {
    return connection.connect();
  }
   
  void SendExpectSuccess(String cmd, [args]) {
    
  }
  
  Future<Object> SendCommand(String cmd, [args]) {
    Completer completer = new Completer();
    
    connection.sendCommand(cmd).then((s) {
      Utils.getLogger().debug("s = $s");
      completer.complete(processResponse(s));
    });
    
    return completer.future;
  }
  
  processResponse(s) {
    
    return s;
  }
  
  /*****************************************************/
//  String Save ()
//  {
//    return SendCommand ("SAVE");
//  }

  // ************ String commands ************
  // http://redis.io/commands#string

  Future<Object> Get(String key) {
    return SendCommand("GET", [key]);
  }
  
  Future<Object> Set(String key, String value) {
    return SendCommand("SET", [key, value]);
  }

  
  // ************ Keys Commands ************
  // http://redis.io/commands#generic
  
  Future<Object> Del(key) {
    var k = Strings.join(key, " ");
    return SendCommand("DEL $k");
  }
  
  Future<Object> Dump(key) {
    return SendCommand("DUMP $key");
  }
  
  Future<Object> Exists(key) {
    return SendCommand("EXISTS $key");
  }
  
  Future<Object> Expire(key, seconds) {
    return SendCommand("EXPIRE $key $seconds");
  }
  
  Future<Object> Expireat(key, timestamp) {
    return SendCommand("EXPIREAT $key $timestamp");
  }
  
  Future<Object> Keys(pattern) {
    return SendCommand("KEYS $pattern");
  }
  
  Future<Object> Migrate(host, port, key, destination_db, timeout) {
    return SendCommand("MIGRATE $host $port $key $destination_db $timeout");
  }
  
  Future<Object> Move(key, db) {
    return SendCommand("MIGRATE $key $db");
  }
  
  Future<Object> ObjectCmd(subcommand, [arguments]) {
    // TODO: handle arguments
    return SendCommand("OBJECT $subcommand");
  }
  
  Future<Object> Persist(key) {
    return SendCommand("PERSIST $key");
  }
  
  Future<Object> Pexpire(key, milliseconds) {
    return SendCommand("PEXPIRE $key $milliseconds");
  }
  
  Future<Object> Pexpireat(key, milliseconds_timestamp) {
    return SendCommand("PEXPIREAT $key $milliseconds_timestamp");
  }
  
  Future<Object> Pttl(key) {
    return SendCommand("PTTL $key");
  }
  
  Future<Object> RandomKey() {
    return SendCommand("RANDOMKEY");
  }
  
  Future<Object> Rename(key, newkey) {
    return SendCommand("RENAME $key $newkey");
  }
  
  Future<Object> Renamenx(key, newkey) {
    return SendCommand("RENAMENX $key $newkey");
  }
  
  Future<Object> Restore(key, ttl, serialized_value) {
    return SendCommand("RESTORE $key $ttl $serialized_value");
  }
  
  Future<Object> Sort(key) {
    // TODO: implement all the other parameters 
    return SendCommand("SORT $key");
  }
  
  Future<Object> TTL(key) {
    return SendCommand("TTL $key");
  }
  
  Future<Object> Type(key) {
    return SendCommand("TYPE $key");
  }
  
  /*
  Connection Commands
   */
  Auth(password) {
    return SendCommand("AUTH $password");
  }
  
  Echo(message) {
    return SendCommand("$message");
  }
  
  Ping() {
    return SendCommand("PING");
  }
  
  Quit() {
    return SendCommand("QUIT");
  }
  
  Select(index) {
    return SendCommand("$index");
  }
 
  
  /*
  Server based commands 
  */
  Future<Object> Bgrewriteaof() {
    return SendCommand ("BGREWRITEAOF");
  }
  
  Future<Object> BackgroundSave ()
  {
    return SendCommand ("BGSAVE");
  }

  Future<Object> ConfigGet(parameter)
  {
    return SendCommand ("CONFIG GET $parameter");
  }
  
  Future<Object> ConfigSet(parameter, value)
  {
    return SendCommand ("CONFIG SET $parameter $value");
  }
  
  Future<Object> ConfigResetstat()
  {
    return SendCommand ("CONFIG RESETSTAT");
  }
  
  Future<Object> DbSize()
  {
    return SendCommand ("DBSIZE");
  }
  
  Future<Object> DebugObject(key)
  {
    return SendCommand ("DEBUG OBJECT $key");
  }
  
  Future<Object> DebugSegfault()
  {
    return SendCommand ("DEBUG SEGFAULT");
  }

  Future<Object> FlushAll()
  {
    return SendCommand ("FLUSHALL");
  }
  
  Future<Object> FlushDb()
  {
    return SendCommand ("FLUSHDB");
  }
  
  Future<Object> Info()
  {
    return SendCommand ("INFO");
  }
  
  Future<Object> LastSave()
  {
    return SendCommand ("LASTSAVE");
  }
  
  Future<Object> Monitor()
  {
    return SendCommand ("MONITOR");
  }
  
  Future<Object> Save()
  {
    return SendCommand ("SAVE");
  }
  
  Future<Object> Shutdown()
  {
    return SendCommand ("SHUTDOWN");
  }
  
  Future<Object> ShutdownSave()
  {
    return SendCommand ("SHUTDOWN SAVE");
  }
  
  Future<Object> ShutdownNoSave()
  {
    return SendCommand ("SHUTDOWN NOSAVE");
  }
  
  Future<Object> SlaveOf(host, port)
  {
    return SendCommand ("SLAVEOF $host $port");
  }
  
  Future<Object> SlowLog(subcommand, [argument])
  {
    return SendCommand ("SLAVEOF $subcommand $argument");
  }
  
  Future<Object> Sync()
  {
    return SendCommand ("SYNC");
  }
  
  Future<Object> Time()
  {
    return SendCommand ("TIME");
  }
}



class sortOptions {
  String key;
  bool descending;
  bool lexographically;
  int lowerLimit;
  int upperLimit;
  String by;
  String storeInKey;
  String Get;
  
  
  String toCommand() {
    StringBuffer command = new StringBuffer();
    command.add("SORT $key");
    if (lowerLimit != 0 || upperLimit != 0) {
      command.add(" LIMIT $lowerLimit $upperLimit");
    }
    
    return command.toString();
  }
}
