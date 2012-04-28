
//
class Terminal {

  final cmdLineContainer;
  final outputContainer;
  final cmdLineInput; 
  DivElement output;
  Map CMDS;
  Terminal(this.cmdLineContainer,this.outputContainer, this.cmdLineInput) {
    DivElement cmdLine = document.query(cmdLineContainer);
    InputElement input; 
    output = document.query(outputContainer);
    
    CMDS = {
			'get': getCommand,
			'set': setCommand,
			'getset': getSetCommand,
			'help': helpCommand,
			'auth': authCommand,
			'info': infoCommand,
			'clear': clearCommand,
			'uri': uriCommand
    };
    
    var history = [];
    var histpos = 0;
    
    window.on.click.add((var event) {
      cmdLine.focus();
    }, false);
    
    // Always force text cursor to end of input line.
    cmdLine.on.click.add((var event) {
      
    }, false);
    
    cmdLine.on.keyDown.add((KeyboardEvent event) {
      input = document.query(cmdLineInput);
      var histtemp = "";
      // historyHandler
      if (event.keyCode == 38 || event.keyCode == 40) {
        event.preventDefault();
        // up or down
        if (histpos < history.length) {
          history[histpos] = input.value;
        } else {
          histtemp = input.value;
        }
      }
      
      if (event.keyCode == 38) { // up
        histpos--;
        if (histpos < 0) {
          histpos = 0;
        }
      } else if (event.keyCode == 40) { // down
        histpos++;
        if (histpos >= history.length) {
          histpos = history.length - 1;
        }
      }
      
      if (event.keyCode == 38 || event.keyCode == 40) {
        // up or down
        input.value = history[histpos] ? history[histpos]  : histtemp; 
      }
    }, false);
    
    cmdLine.on.keyDown.add((KeyboardEvent event) { 
    
      // processNewCommand
      if (event.keyCode == 9) {
        event.preventDefault();
      } else if (event.keyCode == 13) { // enter
        
        input = document.query(cmdLineInput);
        
        if (input.value is String && !input.value.isEmpty()) {
          history.add(input.value);
          histpos = history.length;
        }
        
        // move the line to output and remove id's
        DivElement line = input.parent.parent.clone(true);
        line.attributes.remove('id');
        line.classes.add('line');
        var c = line.query(cmdLineInput);
        c.attributes.remove('id');
        c.autofocus = false;
        c.readOnly = true;
        output.elements.add(line);
        String cmdline = input.value;
        input.value = ""; // clear input
        
        // Parse out command, args, and trim off whitespace
        var args;
        var cmd="";
        if (cmdline is String) {
          cmdline.trim();
          args = cmdline.split(' ');
          cmd = args[0].toLowerCase();
          args.removeRange(0, 1);
        }
        
        if (CMDS[cmd] is Function) {
          CMDS[cmd](cmd,args);
        } else {
          output.insertAdjacentHTML('beforeEnd', '${cmd}: command not found');
        }
           
        window.scrollTo(0, window.innerHeight); 
      }
    }, false);
  }
	// Redis Commands
  createJSONAndSendRequest(String cmd, args) {
    Map a = new Map();
    a['cmd'] = cmd;
    a['args'] = args;
    var o = JSON.stringify(a);
    var request = sendRequest("POST", "/exec", o, processResponse, processResponse);
    return request;
  }
  
	getCommand(var cmd, var args) {
	  if (args.length != 1) {
      var text = "<div><span>ERR wrong number of arguments for 'get' command</span></div>";
      outputText(text);
    } else {
      var o = createJSONAndSendRequest('get',args);
    }
	}
	setCommand(var cmd, var args) {
	  if (args.length != 2) {
	    var text = "<div><span>ERR wrong number of arguments for 'set' command</span></div>";
	    outputText(text);
	  } else {
	   var o = createJSONAndSendRequest('set',args); 
	  }
	}
	
	outputText(String text) {
	  output.insertAdjacentElement('beforeEnd', new Element.html(text));
	}
	
	getSetCommand(var cmd, var args) {
	  if (args.length != 2) {
      var text = "<div><span>ERR wrong number of arguments for 'getset' command</span></div>";
      outputText(text);
    } else {
      var req = createJSONAndSendRequest('getset',args); 
   
    }
	}
	authCommand(var cmd, var args) {
	  if (args.length != 1) {
      var text = "<div><span>ERR wrong number of arguments for 'auth' command</span></div>";
      outputText(text);
    } else {
      var req = createJSONAndSendRequest('auth',args); 
    }
	}
	infoCommand(var cmd, var args) {
	  if (args.length != 0) {
      var text = "<div><span>ERR wrong number of arguments for 'info' command</span></div>";
      outputText(text);
    } else {
      var req = createJSONAndSendRequest('info',args); 
    }
	}
	
	uriCommand(var cmd, var args) {
	  var request = sendRequest("POST", "http://localhost:8082/exec", "", processResponse, processResponse);
	  
	}
	
	clearCommand(var cmd, var args) {
	  output.innerHTML = '';
	}

	helpCommand(var cmd, var args) {
		StringBuffer sb = new StringBuffer();
		sb.add('<div class="ls-files">');
		CMDS.getKeys().forEach((k) {
			sb.add('${k}<br/>');
		});
		sb.add('</div>');
		outputText(sb.toString());
	}
	
	XMLHttpRequest sendRequest(String method, String url, var data, var onSuccess, var onError) {
    XMLHttpRequest request = new XMLHttpRequest();
    request.on.readyStateChange.add((Event event) {
      if (request.readyState != 4) return;
      if (request.status == 200) {
        print(request.responseText);
        onSuccess(JSON.parse(request.responseText));
      } else {
        onError();
      }
    });
    
    request.open(method, url, true);
    request.setRequestHeader('Content-Type', 'application/json;charset=UTF=8');
    request.send(data);
    return request;
  }
	
	processResponse(data) {
	  outputText("<span>"+data['result']+"</span>");
	}
}
