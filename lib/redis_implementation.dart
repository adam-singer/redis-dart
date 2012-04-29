class RedisImpl implements Redis {
  
  Connection connection;
  
  RedisImpl([serverConfig]) {
    connection = new Connection(serverConfig);
  }
  
  Future<bool> open() {
    return connection.connect();
  }
  
  /*****************************************************/
//  String Save ()
//  {
//    return connection.SendCommand ("SAVE");
//  }

  // ************ Keys Commands ************
  // http://redis.io/commands#generic
  
  Future<Object> Del(List<String> keys) {
    return connection.SendCommand("DEL", [keys]);
  }
  
  Future<Object> Dump(key) {
    return connection.SendCommand("DUMP", [key]);
  }
  
  Future<Object> Exists(key) {
    return connection.SendCommand("EXISTS", [key]);
  }
  
  Future<Object> Expire(key, seconds) {
    return connection.SendCommand("EXPIRE", [key, seconds]);
  }
  
  Future<Object> Expireat(key, timestamp) {
    return connection.SendCommand("EXPIREAT", [key, timestamp]);
  }
  
  Future<Object> Keys(pattern) {
    return connection.SendCommand("KEYS", [pattern]);
  }
  
  Future<Object> Migrate(host, port, key, destination_db, timeout) {
    return connection.SendCommand("MIGRATE $host $port $key $destination_db $timeout");
  }
  
  Future<Object> Move(key, db) {
    return connection.SendCommand("MIGRATE $key $db");
  }
  
  Future<Object> ObjectCmd(subcommand, [arguments]) {
    // TODO: handle arguments
    return connection.SendCommand("OBJECT $subcommand");
  }
  
  Future<Object> Persist(key) {
    return connection.SendCommand("PERSIST $key");
  }
  
  Future<Object> Pexpire(key, milliseconds) {
    return connection.SendCommand("PEXPIRE $key $milliseconds");
  }
  
  Future<Object> Pexpireat(key, milliseconds_timestamp) {
    return connection.SendCommand("PEXPIREAT $key $milliseconds_timestamp");
  }
  
  Future<Object> Pttl(key) {
    return connection.SendCommand("PTTL $key");
  }
  
  Future<Object> RandomKey() {
    return connection.SendCommand("RANDOMKEY");
  }
  
  Future<Object> Rename(key, newkey) {
    return connection.SendCommand("RENAME $key $newkey");
  }
  
  Future<Object> Renamenx(key, newkey) {
    return connection.SendCommand("RENAMENX $key $newkey");
  }
  
  Future<Object> Restore(key, ttl, serialized_value) {
    return connection.SendCommand("RESTORE $key $ttl $serialized_value");
  }
  
  Future<Object> Sort(key) {
    // TODO: implement all the other parameters 
    return connection.SendCommand("SORT $key");
  }
  
  Future<Object> TTL(key) {
    return connection.SendCommand("TTL $key");
  }
  
  Future<Object> Type(key) {
    return connection.SendCommand("TYPE $key");
  }

  
  // ************ String commands ************
  // http://redis.io/commands#string

  Future<Object> Append(String key, String value) {
		return connection.SendCommand("APPEND", [key, value]);
	}

	Future<Object> Decr(String key) {
		return connection.SendCommand("DECR", [key]);
	}

  Future<String> Get(String key) {
    return connection.SendCommand("GET", [key]).transform((value) => value[0]);
  }
  
  Future<Object> Set(String key, Object value) {
    return connection.SendCommand("SET", [key, value.toString()]);
  }

  
  /*
  Connection Commands
   */
  Auth(password) {
    return connection.SendCommand("AUTH $password");
  }
  
  Echo(message) {
    return connection.SendCommand("$message");
  }
  
  Ping() {
    return connection.SendCommand("PING");
  }
  
  Quit() {
    return connection.SendCommand("QUIT");
  }
  
  Select(index) {
    return connection.SendCommand("$index");
  }
 
  
  /*
  Server based commands 
  */
  Future<Object> Bgrewriteaof() {
    return connection.SendCommand("BGREWRITEAOF");
  }
  
  Future<Object> BackgroundSave ()
  {
    return connection.SendCommand("BGSAVE");
  }

  Future<Object> ConfigGet(parameter)
  {
    return connection.SendCommand ("CONFIG GET $parameter");
  }
  
  Future<Object> ConfigSet(parameter, value)
  {
    return connection.SendCommand ("CONFIG SET $parameter $value");
  }
  
  Future<Object> ConfigResetstat()
  {
    return connection.SendCommand ("CONFIG RESETSTAT");
  }
  
  Future<Object> DbSize()
  {
    return connection.SendCommand ("DBSIZE");
  }
  
  Future<Object> DebugObject(key)
  {
    return connection.SendCommand ("DEBUG OBJECT $key");
  }
  
  Future<Object> DebugSegfault()
  {
    return connection.SendCommand ("DEBUG SEGFAULT");
  }

  Future<Object> FlushAll()
  {
    return connection.SendCommand ("FLUSHALL");
  }
  
  Future<Object> FlushDb()
  {
    return connection.SendCommand ("FLUSHDB");
  }
  
  Future<Object> Info()
  {
    return connection.SendCommand ("INFO");
  }
  
  Future<Object> LastSave()
  {
    return connection.SendCommand ("LASTSAVE");
  }
  
  Future<Object> Monitor()
  {
    return connection.SendCommand ("MONITOR");
  }
  
  Future<Object> Save()
  {
    return connection.SendCommand ("SAVE");
  }
  
  Future<Object> Shutdown()
  {
    return connection.SendCommand ("SHUTDOWN");
  }
  
  Future<Object> ShutdownSave()
  {
    return connection.SendCommand ("SHUTDOWN SAVE");
  }
  
  Future<Object> ShutdownNoSave()
  {
    return connection.SendCommand ("SHUTDOWN NOSAVE");
  }
  
  Future<Object> SlaveOf(host, port)
  {
    return connection.SendCommand ("SLAVEOF $host $port");
  }
  
  Future<Object> SlowLog(subcommand, [argument])
  {
    return connection.SendCommand ("SLAVEOF $subcommand $argument");
  }
  
  Future<Object> Sync()
  {
    return connection.SendCommand ("SYNC");
  }
  
  Future<Object> Time()
  {
    return connection.SendCommand ("TIME");
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
