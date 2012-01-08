(function() {
  var Block, Build, Comma, Eval, Indent, Join, Shift, SubBlock, data, fn, fs, handle_data, indenter, parser, stdin;
  indenter = window.CoffeeCoffee.indenter;
  Build = {
    'ACCESS': function(arg, block) {
      var access, val;
      val = Eval(block);
      access = Shift(block);
      return "" + val + "." + access;
    },
    'ACCESS_SOAK': function(arg, block) {
      var access, val;
      val = Eval(block);
      access = Shift(block);
      return "" + val + "?." + access;
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
    'BOUND_CODE': function(arg, block) {
      var params;
      params = Eval(block);
      return Join(params + " =>", Block(block));
    },
    'BREAK': function(arg, block) {
      return 'break';
    },
    'CALL': function(arg, block) {
      var args, my_var;
      my_var = Eval(block);
      args = Eval(block);
      return "" + my_var + args;
    },
    'CASE': function(arg, block) {
      return Join("when " + (Eval(block)) + " then", Eval(block));
    },
    'CATCH': function(arg, block) {
      var stmt;
      stmt = "catch " + (Shift(block));
      return Indent(stmt, Eval(block));
    },
    'CLASS': function(arg, block) {
      var parent, prolog;
      prolog = "class " + (Shift(block));
      parent = Eval(block);
      if (parent) {
        prolog += " extends " + parent;
      }
      return Indent(prolog, Eval(block));
    },
    'CODE': function(arg, block) {
      var params;
      params = Eval(block);
      return Join(params + " ->", Block(block));
    },
    'COND': function(arg, block) {
      return Eval(block);
    },
    'CONTINUE': function(arg, block) {
      return 'continue';
    },
    'DECR_PRE': function(arg, block) {
      return "--" + (Eval(block));
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
    'FINALLY': function(arg, block) {
      return Indent("finally", Eval(block));
    },
    'FOR_IN': function(arg, block) {
      var for_stmt, range_var, step_var;
      step_var = Shift(block);
      range_var = Eval(block);
      for_stmt = "for " + step_var + " in " + range_var;
      return Indent(for_stmt, Eval(block));
    },
    'FOR_OF': function(arg, block) {
      var for_stmt, range_var, vars;
      vars = Eval(block);
      range_var = Eval(block);
      for_stmt = "for " + vars + " of " + range_var;
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
    'IN': function(arg, block) {
      return Join("" + (Eval(block)) + " of", Eval(block));
    },
    'INCR_PRE': function(arg, block) {
      return "++" + (Eval(block));
    },
    'INDEX': function(arg, block) {
      var index, val;
      val = Eval(block);
      index = Eval(block);
      return "" + val + "[" + index + "]";
    },
    'KEY': function(arg, block) {
      return Eval(block);
    },
    'KEY_VALUE': function(arg, block) {
      var name;
      name = Shift(block);
      return Join("" + name + ":", Eval(block));
    },
    'METHODS': function(arg, block) {
      var code, name;
      code = '';
      while (block.len() > 0) {
        name = Shift(block);
        code += Join("" + name + ":", Eval(block));
        code += '\n';
      }
      return code;
    },
    'NEW': function(arg, block) {
      var args, my_var;
      my_var = Eval(block);
      args = Eval(block);
      return "new " + my_var + args;
    },
    'NEW_BARE': function(arg, block) {
      var my_var;
      my_var = Shift(block);
      return "new " + my_var;
    },
    'NOT_IN': function(arg, block) {
      return Join("" + (Eval(block)) + " not of", Eval(block));
    },
    'NUMBER': function(arg, block) {
      return arg;
    },
    'OBJ': function(arg, block) {
      var s;
      s = '';
      while (block.len() > 0) {
        s += Eval(block);
        s += '\n';
      }
      return "{" + s + "}";
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
      if (op === 'in') {
        op = 'of';
      }
      operand1 = Eval(block);
      operand2 = Eval(block);
      return "" + operand1 + " " + op + " " + operand2;
    },
    'OP_UNARY': function(arg, block) {
      var op, operand;
      op = arg;
      if (op === '!') {
        op = "not";
      }
      operand = Eval(block);
      return "" + op + "(" + operand + ")";
    },
    'OTHERWISE': function(arg, block) {
      return Join("else", Eval(block));
    },
    'PARAM': function(arg, block) {
      var feature, features, param;
      param = Shift(block);
      features = SubBlock(block);
      while (features.len() > 0) {
        feature = Shift(features);
        if (feature === 'autoassign') {
          param = '@' + param;
        }
      }
      if (block.len() > 0) {
        param += " = " + (Eval(block));
      }
      return param;
    },
    'PARAMS': function(arg, block) {
      var params;
      params = [];
      while (block.len() > 0) {
        params.push(Eval(block));
      }
      return "(" + (Comma(params)) + ")";
    },
    'PARENS': function(arg, block) {
      var expr;
      expr = Block(block);
      return "(" + expr.slice(0, -1) + ")";
    },
    'PARENTS': function(arg, block) {
      if (block.len() > 0) {
        return Eval(block);
      } else {
        return null;
      }
    },
    'PROTO': function(arg, block) {
      var val;
      val = Eval(block);
      return "" + val + ".prototype";
    },
    'RANGE_EXCLUSIVE': function(arg, block) {
      var high, low;
      low = Eval(block);
      high = Eval(block);
      return "[" + low + "..." + high + "]";
    },
    'RANGE_INCLUSIVE': function(arg, block) {
      var high, low;
      low = Eval(block);
      high = Eval(block);
      return "[" + low + ".." + high + "]";
    },
    'REGEX': function(arg, block) {
      return arg;
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
    'SPLAT': function(arg, block) {
      var val;
      val = Eval(block);
      return "" + val + "...";
    },
    'STRING': function(arg, block) {
      return arg;
    },
    'SUPER': function(arg, block) {
      return Join("super", Eval(block));
    },
    'SWITCH': function(arg, block) {
      var body, prolog;
      prolog = "switch " + (Eval(block));
      body = [];
      while (block.len() > 0) {
        body.push(Eval(block));
      }
      return Indent(prolog, body.join('\n'));
    },
    'THROW': function(arg, block) {
      var val;
      val = Eval(block);
      return "throw " + val;
    },
    'TRY': function(arg, block) {
      var stmt;
      stmt = Indent("try", Eval(block));
      while (block.len() > 0) {
        stmt += '\n' + Eval(block);
      }
      return stmt;
    },
    'VALUE': function(arg, block) {
      return arg;
    },
    'VARS': function(arg, block) {
      var vars;
      vars = [];
      while (block.len() > 0) {
        vars.push(Shift(block));
      }
      return Comma(vars);
    },
    'WHILE': function(arg, block) {
      var body, cond;
      cond = "while " + (Eval(block));
      body = Eval(block);
      return Join(cond, body);
    }
  };
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
  SubBlock = function(block) {
    var line, prefix, _ref;
    _ref = indenter.small_block(block), prefix = _ref[0], line = _ref[1], block = _ref[2];
    return block;
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
  parser = function(indented_lines) {
    var data;
    data = [];
    while (indented_lines.len() > 0) {
      if (typeof window !== "undefined" && window !== null) {
        data.push(Eval(indented_lines));
      } else {
        console.log(Eval(indented_lines));
      }
    }
    return data.join('\n');
  };
  handle_data = function(s) {
    var prefix_line_array;
    prefix_line_array = indenter.big_block(s);
    return parser(prefix_line_array);
  };
  if (typeof window !== "undefined" && window !== null) {
    window.CoffeeCoffee.to_coffee = handle_data;
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
