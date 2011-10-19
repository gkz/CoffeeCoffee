(function() {
  var Block, Build, Comma, Eval, Indent, Join, Shift, data, fn, fs, handle_data, indenter, parser, stdin;
  Eval = function(block) {
    var arg, args, line, name, prefix, _ref;
    _ref = indenter.small_block(block), prefix = _ref[0], line = _ref[1], block = _ref[2];
    if (line.length === 0) {
      return '';
    }
    args = line.split(' ');
    name = args[0];
    arg = args.slice(1, args.length).join(' ');
    if (Build[name]) {
      return Build[name](arg, block);
    } else {
      return console.log("unknown " + name);
    }
  };
  Join = function(s1, s2) {
    var lines;
    lines = s2.split('\n');
    if (lines.length === 1) {
      return s1 + ' ' + s2;
    } else {
      return Indent(s1, s2);
    }
  };
  Indent = function(s1, s2) {
    var lines, s;
    lines = s2.split('\n');
    return s1 + '\n' + ((function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = lines.length; _i < _len; _i++) {
        s = lines[_i];
        _results.push('  ' + s);
      }
      return _results;
    })()).join('\n');
  };
  Block = function(block) {
    var s;
    s = '';
    while (block.len() > 0) {
      s += Eval(block);
      s += '\n';
    }
    return s;
  };
  Shift = function(block) {
    return block.shift()[1];
  };
  Comma = function(arr) {
    return arr.join(', ');
  };
  Build = {
    'ACCESS': function(arg, block) {
      var access, val;
      val = Eval(block);
      access = Shift(block);
      return "" + val + "." + access;
    },
    'ARGS': function(arg, block) {
      var my_args;
      my_args = [];
      while (block.len() > 0) {
        my_args.push(Eval(block));
      }
      return "(" + (Comma(my_args)) + ")";
    },
    'ARR': function(arg, block) {
      var elems;
      elems = [];
      while (block.len() > 0) {
        elems.push(Eval(block));
      }
      return "[" + (Comma(elems)) + "]";
    },
    'ASSIGN': function(arg, block) {
      var my_var, op, value;
      my_var = Eval(block);
      op = arg;
      value = Eval(block);
      return Join("" + my_var + " " + op, value);
    },
    'CALL': function(arg, block) {
      var args, my_var;
      my_var = Eval(block);
      args = Eval(block);
      return "" + my_var + args;
    },
    'CLASS': function(arg, block) {
      var prolog;
      prolog = "class " + (Shift(block));
      return Indent(prolog, Eval(block));
    },
    'CODE': function(arg, block) {
      var params;
      params = Eval(block);
      return Join(params, Block(block));
    },
    'COND': function(arg, block) {
      return Eval(block);
    },
    'DO': function(arg, block) {
      return Block(block);
    },
    'EXISTENCE': function(args, block) {
      return Eval(block) + '?';
    },
    'EVAL': function(arg, block) {
      return arg;
    },
    'FOR_IN': function(arg, block) {
      var for_stmt, range_var, step_var;
      step_var = Shift(block);
      range_var = Eval(block);
      for_stmt = "for " + step_var + " in " + range_var;
      return Indent(for_stmt, Eval(block));
    },
    'IF': function(arg, block) {
      var body, cond, elseBody, stmt;
      cond = "if " + (Eval(block));
      body = Eval(block);
      stmt = Join(cond, body);
      if (block.len() > 0) {
        elseBody = Join("else", Eval(block));
        stmt = stmt + "\n" + elseBody;
      }
      return stmt;
    },
    'INDEX': function(arg, block) {
      var index, val;
      val = Eval(block);
      index = Eval(block);
      return "" + val + "[" + index + "]";
    },
    'NEW': function(arg, block) {
      var args, my_var;
      my_var = Eval(block);
      args = Eval(block);
      return "new " + my_var + args;
    },
    'NUMBER': function(arg, block) {
      return arg;
    },
    'OBJ': function(arg, block) {
      var name, s;
      s = '';
      while (block.len() > 0) {
        name = Shift(block);
        s += Join("" + name + ":", Eval(block));
        s += '\n';
      }
      return s;
    },
    'OP_BINARY': function(arg, block) {
      var op, operand1, operand2;
      op = arg;
      if (op === '===') {
        op = 'is';
      }
      if (op === '!==') {
        op = 'isnt';
      }
      operand1 = Eval(block);
      operand2 = Eval(block);
      return "" + operand1 + " " + op + " " + operand2;
    },
    'OP_UNARY': function(arg, block) {
      var op, operand;
      op = arg;
      operand = Eval(block);
      return "" + op + operand;
    },
    'PARAMS': function(arg, block) {
      var params;
      params = [];
      while (block.len() > 0) {
        params.push(block.shift()[1]);
      }
      return "(" + (Comma(params)) + ") ->";
    },
    'PARENS': function(arg, block) {
      var expr;
      expr = Eval(block);
      return "(" + expr + ")";
    },
    'RANGE_EXCLUSIVE': function(arg, block) {
      var high, low;
      low = Eval(block);
      high = Eval(block);
      return "[" + low + "..." + high + "]";
    },
    'RETURN': function(arg, block) {
      var val;
      val = Eval(block);
      return "return " + val;
    },
    'SLICE': function(arg, block) {
      var index, val;
      val = Eval(block);
      index = Eval(block);
      return "" + val + index;
    },
    'STRING': function(arg, block) {
      return arg;
    },
    'VALUE': function(arg, block) {
      return arg;
    },
    'WHILE': function(arg, block) {
      var body, cond;
      cond = "while " + (Eval(block));
      body = Eval(block);
      return Join(cond, body);
    }
  };
  parser = function(indented_lines) {
    var _results;
    _results = [];
    while (indented_lines.len() > 0) {
      _results.push(console.log(Eval(indented_lines)));
    }
    return _results;
  };
  handle_data = function(s) {
    var prefix_line_array;
    prefix_line_array = indenter.big_block(s);
    return parser(prefix_line_array);
  };
  if (typeof window !== "undefined" && window !== null) {
    window.transcompile = transcompile;
    window.Debugger = Debugger;
  } else {
    fs = require('fs');
    indenter = require('./indenter');
    fn = process.argv.splice(2, 1)[0];
    if (fn === '-') {
      data = '';
      stdin = process.openStdin();
      stdin.on('data', function(buffer) {
        if (buffer) {
          return data += buffer.toString();
        }
      });
      stdin.on('end', function() {
        return handle_data(data);
      });
    } else {
      data = fs.readFileSync(fn).toString();
      handle_data(data);
    }
  }
}).call(this);
