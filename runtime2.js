(function() {
  var Compile, Compiler, RunTime, binary_ops, data, fn, fs, handle_data, indenter, parser, stdin, unary_ops;
  Compiler = {
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
    var self;
    return self = {
      call: function(code, cb) {
        return code({
          value: function(val) {
            return cb(val);
          },
          call: self.call
        });
      }
    };
  };
  parser = function(indented_lines) {
    var code, runtime, _results;
    runtime = RunTime();
    _results = [];
    while (indented_lines.len() > 0) {
      code = Compile(indented_lines);
      _results.push(code ? runtime.call(code, function(val) {
        return console.log(val);
      }) : void 0);
    }
    return _results;
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
