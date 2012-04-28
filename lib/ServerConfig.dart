#library("ServerConfig");

class ServerConfig{
  String host;
  int port;
  int db;
  String password;
  ServerConfig([this.host='127.0.0.1', this.port=6379, this.db=0, this.password=""]);
}