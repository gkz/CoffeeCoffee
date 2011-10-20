(function() {
  var Compile, Compiler, GetBlock, RunTime, Scope, binary_ops, data, fn, fs, handle_data, indenter, parser, stdin, unary_ops, update_variable_reference;
  var __slice = Array.prototype.slice;
  Compiler = {
    'ASSIGN': function(arg, block) {
      var name, subarg, subblock, value_code, var_name, _ref;
      _ref = GetBlock(block), name = _ref[0], subarg = _ref[1], subblock = _ref[2];
      var_name = subarg;
      value_code = Compile(block);
      return function(rt) {
        return rt.call(value_code, function(val) {
          rt.scope.set(var_name, val);
          return rt.value(null);
        });
      };
    },
    'EVAL': function(arg, block) {
      return function(rt) {
        var val;
        val = rt.scope.get(arg);
        return rt.value(val);
      };
    },
    'NUMBER': function(arg, block) {
      return function(rt) {
        return rt.value(parseFloat(arg));
      };
    },
    'OP_BINARY': function(arg, block) {
      var f, op, operand1, operand2;
      op = arg;
      f = binary_ops[op];
      operand1 = Compile(block);
      operand2 = Compile(block);
      return function(rt) {
        return rt.call(operand1, function(op1) {
          return rt.call(operand2, function(op2) {
            return rt.value(f(op1, op2));
          });
        });
      };
    },
    'OP_UNARY': function(arg, block) {
      var f, op, operand1;
      op = arg;
      f = unary_ops[op];
      operand1 = Compile(block);
      return function(rt) {
        return rt.call(operand1, function(op1) {
          return rt.value(f(op1));
        });
      };
    }
  };
  GetBlock = function(block) {
    var arg, args, line, name, prefix, _ref;
    _ref = indenter.small_block(block), prefix = _ref[0], line = _ref[1], block = _ref[2];
    if (line.length === 0) {
      return null;
    }
    args = line.split(' ');
    name = args[0];
    arg = args.slice(1, args.length).join(' ');
    return [name, arg, block];
  };
  Compile = function(block) {
    var arg, args, line, name, prefix, _ref;
    _ref = indenter.small_block(block), prefix = _ref[0], line = _ref[1], block = _ref[2];
    if (line.length === 0) {
      return null;
    }
    args = line.split(' ');
    name = args[0];
    arg = args.slice(1, args.length).join(' ');
    if (Compiler[name]) {
      return Compiler[name](arg, block);
    } else {
      return console.log("unknown " + name);
    }
  };
  RunTime = function() {
    var scope, self;
    scope = Scope();
    scope.set("x", 42);
    return self = {
      call: function(code, cb) {
        return code({
          value: function(val) {
            var f;
            f = function() {
              return cb(val);
            };
            return setTimeout(f, 200);
          },
          call: self.call,
          scope: scope
        });
      }
    };
  };
  parser = function(indented_lines) {
    var f, runtime;
    runtime = RunTime();
    f = function() {
      var code;
      if (indented_lines.len() > 0) {
        code = Compile(indented_lines);
        if (code) {
          return runtime.call(code, function(val) {
            console.log(val);
            return f();
          });
        }
      }
    };
    return f();
  };
  handle_data = function(s) {
    var prefix_line_array;
    prefix_line_array = indenter.big_block(s);
    return parser(prefix_line_array);
  };
  binary_ops = {
    '*': function(op1, op2) {
      return op1 * op2;
    },
    '/': function(op1, op2) {
      return op1 / op2;
    },
    '+': function(op1, op2) {
      return op1 + op2;
    },
    '-': function(op1, op2) {
      return op1 - op2;
    },
    '|': function(op1, op2) {
      return op1 | op2;
    },
    '&': function(op1, op2) {
      return op1 & op2;
    },
    '^': function(op1, op2) {
      return op1 ^ op2;
    },
    '===': function(op1, op2) {
      return op1 === op2;
    },
    '!==': function(op1, op2) {
      return op1 !== op2;
    },
    '>>': function(op1, op2) {
      return op1 >> op2;
    },
    '>>>': function(op1, op2) {
      return op1 >>> op2;
    },
    '<<': function(op1, op2) {
      return op1 << op2;
    },
    '||': function(op1, op2) {
      return op1 || op2;
    },
    '<': function(op1, op2) {
      return op1 < op2;
    },
    '<=': function(op1, op2) {
      return op1 <= op2;
    },
    '>': function(op1, op2) {
      return op1 > op2;
    },
    '>=': function(op1, op2) {
      return op1 >= op2;
    },
    '%': function(op1, op2) {
      return op1 % op2;
    },
    'in': function(op1, op2) {
      return op1 in op2;
    },
    'instanceof': function(op1, op2) {
      return op1 instanceof op2;
    }
  };
  unary_ops = {
    '-': function(op) {
      return -1 * op;
    },
    '!': function(op) {
      return !op;
    },
    '~': function(op) {
      return ~op;
    },
    'typeof': function(op) {
      return typeof op;
    }
  };
  Scope = function(params, parent_scope, this_value, args) {
    var key, self, set_local_value, value, vars;
    vars = {};
    set_local_value = function(key, value) {
      return vars[key] = {
        obj: value
      };
    };
    for (key in params) {
      value = params[key];
      set_local_value(key, value);
    }
    set_local_value("this", this_value);
    set_local_value("arguments", args);
    return self = {
      get_closure_wrapper: function(var_name) {
        var val;
        val = vars[var_name];
        if (val != null) {
          return val;
        }
        if (parent_scope) {
          return parent_scope.get_closure_wrapper(var_name);
        }
      },
      set: function(var_name, value, context) {
        var assigned_val, closure_wrapper;
        context || (context = "=");
        closure_wrapper = self.get_closure_wrapper(var_name);
        if (closure_wrapper) {
          assigned_val = update_variable_reference(closure_wrapper, "obj", value, context);
          return assigned_val;
        } else if (context === "=") {
          set_local_value(var_name, value);
          return value;
        } else {
          throw "Var " + var_name + " has not been set";
        }
      },
      get: function(var_name) {
        var closure_wrapper, val;
        if (var_name === 'require') {
          return function() {
            var args;
            args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
            return require.apply(null, args);
          };
        }
        closure_wrapper = self.get_closure_wrapper(var_name);
        if (closure_wrapper) {
          value = closure_wrapper.obj;
          return value;
        }
        if (typeof root !== "undefined" && root !== null) {
          val = root[var_name];
        } else {
          val = window[var_name];
        }
        if (val == null) {
          internal_throw("reference", "ReferenceError: " + var_name + " is not defined");
        }
        return val;
      }
    };
  };
  update_variable_reference = function(hash, key, value, context) {
    var commands;
    context || (context = '=');
    if ((key.from_val != null) && (key.to_val != null)) {
      if (context !== '=') {
        throw "slice assignment not allowed";
      }
      [].splice.apply(hash, [key.from_val, key.to_val - key.from_val].concat(value));
      return value;
    }
    commands = {
      '=': function() {
        return hash[key] = value;
      },
      '+=': function() {
        return hash[key] += value;
      },
      '*=': function() {
        return hash[key] *= value;
      },
      '-=': function() {
        return hash[key] -= value;
      },
      '||=': function() {
        return hash[key] || (hash[key] = value);
      },
      '++': function() {
        return ++hash[key];
      },
      '--': function() {
        return --hash[key];
      }
    };
    if (!commands[context]) {
      throw "unknown context " + context;
    }
    return commands[context]();
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
