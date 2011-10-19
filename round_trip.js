(function() {
  var Block, Build, Comma, DEDENT, Eval, INDENT, Join, PUT, Shift, TAB, data, fn, fs, handle_data, indenter, parser, stdin;
  TAB = '';
  PUT = function(s, f) {
    var code;
    code = TAB + s;
    if (f) {
      INDENT();
      code += f();
      DEDENT();
    }
    return code;
  };
  INDENT = function() {
    return TAB += '  ';
  };
  DEDENT = function() {
    return TAB = TAB.slice(0, TAB.length - 2);
  };
  Eval = function(block) {
    var args, line, name, prefix, _ref;
    _ref = indenter.small_block(block), prefix = _ref[0], line = _ref[1], block = _ref[2];
    if (line.length === 0) {
      return '';
    }
    args = line.split(' ');
    name = args[0];
    if (Build[name]) {
      return Build[name](args, block);
    } else {
      return console.log("unknown " + name);
    }
  };
  Join = function(s1, s2) {
    var lines, s;
    lines = s2.split('\n');
    if (lines.length === 1) {
      return s1 + ' ' + s2;
    } else {
      return s1 + '\n' + ((function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = lines.length; _i < _len; _i++) {
          s = lines[_i];
          _results.push('  ' + s);
        }
        return _results;
      })()).join('\n');
    }
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
    'ACCESS': function(args, block) {
      var access, val;
      val = Eval(block);
      access = Shift(block);
      return "" + val + "." + access;
    },
    'ARGS': function(args, block) {
      var my_args;
      my_args = [];
      while (block.len() > 0) {
        my_args.push(Eval(block));
      }
      return "(" + (Comma(my_args)) + ")";
    },
    'ARR': function(args, block) {
      var elems;
      elems = [];
      while (block.len() > 0) {
        elems.push(Eval(block));
      }
      return "[" + (Comma(elems)) + "]";
    },
    'ASSIGN': function(args, block) {
      var my_var, value;
      my_var = Eval(block);
      value = Eval(block);
      return PUT("" + my_var + " = " + value);
    },
    'CALL': function(args, block) {
      var my_var;
      my_var = Eval(block);
      args = Eval(block);
      return "" + my_var + args;
    },
    'CODE': function(args, block) {
      var params;
      params = Eval(block);
      return Join(params, Block(block));
    },
    'COND': function(args, block) {
      return Eval(block);
    },
    'DO': function(args, block) {
      return Block(block);
    },
    'EVAL': function(args, block) {
      return args[1];
    },
    'IF': function(args, block) {
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
    'INDEX': function(args, block) {
      var index, val;
      val = Eval(block);
      index = Eval(block);
      return "" + val + "[" + index + "]";
    },
    'NUMBER': function(args, block) {
      return args[1];
    },
    'OP_BINARY': function(args, block) {
      var op, operand1, operand2;
      op = args[1];
      if (op === '===') {
        op = 'is';
      }
      operand1 = Eval(block);
      operand2 = Eval(block);
      return "" + operand1 + " " + op + " " + operand2;
    },
    'OP_UNARY': function(args, block) {
      var op, operand;
      op = args[1];
      operand = Eval(block);
      return "" + op + operand;
    },
    'PARAMS': function(args, block) {
      var params;
      params = [];
      while (block.len() > 0) {
        params.push(block.shift()[1]);
      }
      return "(" + (Comma(params)) + ") ->";
    },
    'PARENS': function(args, block) {
      var expr;
      expr = Eval(block);
      return "(" + expr + ")";
    },
    'RETURN': function(args, block) {
      var val;
      val = Eval(block);
      return "return " + val;
    },
    'WHILE': function(args, block) {
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
