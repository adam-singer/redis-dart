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
			'time': timeCommand,	
			'quit': quitCommand,
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
          args = args.removeRange(0, 1);
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
	getCommand(var cmd, var args) {}
	setCommand(var cmd, var args) {}
	getSetCommand(var cmd, var args) {}
	authCommand(var cmd, var args) {}
	infoCommand(var cmd, var args) {}
	timeCommand(var cmd, var args) {}
	quitCommand(var cmd, var args) {}

	helpCommand(var cmd, var args) {
		StringBuffer sb = new StringBuffer();
		sb.add('<div class="ls-files">');
		CMDS.getKeys().forEach((k) {
			sb.add('${k}<br/>');
		});
		sb.add('</div>');
		output.insertAdjacentHTML('beforeEnd', sb.toString());
	}
}
