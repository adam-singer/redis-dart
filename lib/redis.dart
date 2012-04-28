interface Redis default RedisImpl {

	// ************ Keys Commands ************
	// http://redis.io/commands#generic

  Future<Object> Del(key);
  
  Future<Object> Dump(key);
  
  Future<Object> Exists(key);
  
  Future<Object> Expire(key, seconds);
  
  Future<Object> Expireat(key, timestamp);
  
  Future<Object> Keys(pattern);
  
  Future<Object> Migrate(host, port, key, destination_db, timeout);
  
  Future<Object> Move(key, db);
  
  Future<Object> ObjectCmd(subcommand, [arguments]);
  
  Future<Object> Persist(key);
  
  Future<Object> Pexpire(key, milliseconds);
  
  Future<Object> Pexpireat(key, milliseconds_timestamp);
  
  Future<Object> Pttl(key);
  
  Future<Object> RandomKey();
  
  Future<Object> Rename(key, newkey);
  
  Future<Object> Renamenx(key, newkey);
  
  Future<Object> Restore(key, ttl, serialized_value);
  
  Future<Object> Sort(key);
  
  Future<Object> TTL(key);
  
  Future<Object> Type(key);


  // ************ String commands ************
  // http://redis.io/commands#string

	/**
	 * Append a value to a key
	 * http://redis.io/commands/append
	 */
  Future<Object> Append(String key, String value);

	/**
	 * Decrement the integer value of a key by one
	 * http://redis.io/commands/decr
	 */
	Future<Object> Decr(String key);

	/**
	 * Get the value of a key
	 * http://redis.io/commands/get
	 */
  Future<Object> Get(String key);

	/**
	 * Set the string value of a key
	 * http://redis.io/commands/set
	 */
	Future<Object> Set(String key, String value);

  
	// ************ Connections Commands ************
	// http://redis.io/commands#connection

  Auth(password);
  
  Echo(message);
  
  Ping();
  
  Quit();
  
  Select(num index);

  
	// ************ Server Commands ************
	// http://redis.io/commands#server

  Future<Object> Bgrewriteaof();
  
  Future<Object> BackgroundSave();

  Future<Object> ConfigGet(parameter);
  
  Future<Object> ConfigSet(parameter, value);
  
  Future<Object> ConfigResetstat();
  
  Future<Object> DbSize();
  
  Future<Object> DebugObject(key);
  
  Future<Object> DebugSegfault();

  Future<Object> FlushAll();
  
  Future<Object> FlushDb();
  
  Future<Object> Info();
  
  Future<Object> LastSave();
  
  Future<Object> Monitor();
  
  Future<Object> Save();
  
  Future<Object> Shutdown();
  
  Future<Object> ShutdownSave();
  
  Future<Object> ShutdownNoSave();
  
  Future<Object> SlaveOf(host, port);
  
  Future<Object> SlowLog(subcommand, [argument]);
  
  Future<Object> Sync();
  
  Future<Object> Time();
}
