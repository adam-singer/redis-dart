#import('dart:core');
#import('dart:html');
#import("dart:json");

//#import('dart:dom', prefix:"dom");
//#import('dart:htmlimpl', prefix:"htmlimpl");
#source('../../third_party/dartwatch-JsonObject/JsonObject.dart');
#source('Terminal.dart');

// #source('Commands.dart');
class TerminalRedis {

  TerminalRedis() {
  }

  void run() {
    Terminal t = new Terminal('#input-line', '#output', '#cmdline');
    
  }
}

void main() {
  new TerminalRedis().run();
}
