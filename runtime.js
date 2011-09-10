(function() {
  var Eval, Frame, Op, Runtime, Statement, Value, data, fn, fs, handle_data, pp, stdin;
  Statement = function(ast, frame) {
    var method;
    method = Runtime[ast.parent];
    if (method) {
      return method(ast.children, frame);
    } else {
      return console.log("Statement not supported:", ast.parent);
    }
  };
  pp = function(obj) {
    console.log("-----");
    return console.log(JSON.stringify(obj, null, "  "));
  };
  Frame = function() {
    var self;
    return self = {
      console: function(frame, parms) {
        console.log("Logging stuff");
        return console.log(Eval(frame, parms[0]));
      }
    };
  };
  Eval = function(frame, ast) {
    if (ast.kind === "Value") {
      console.log("Value", ast.value);
      return JSON.parse(ast.value);
    }
    if (ast.value) {
      if (ast.value.charAt(0) === '"') {
        return JSON.parse(ast.value);
      } else {
        return frame[ast.value];
      }
    } else {
      if (ast.parent.kind === "Op") {
        return Op(frame, ast.parent.value, ast.children);
      }
    }
  };
  Op = function(frame, op, children) {
    var operand1, operand2;
    operand1 = Eval(frame, children[0]);
    operand2 = Eval(frame, children[1]);
    console.log('ops', operand1, operand2);
    if (op === '*') {
      return operand1 * operand2;
    }
  };
  Value = function(ast) {
    if (ast.value != null) {
      return ast.value;
    }
    return ast.parent.value;
  };
  Runtime = {
    Block: function(ast) {
      var frame, stmt, _i, _len, _results;
      frame = Frame();
      _results = [];
      for (_i = 0, _len = ast.length; _i < _len; _i++) {
        stmt = ast[_i];
        _results.push(Statement(stmt, frame));
      }
      return _results;
    },
    Assign: function(ast, frame) {
      var lhs, rhs;
      lhs = ast[0].value;
      rhs = ast[1];
      return frame[lhs] = rhs;
    },
    Call: function(ast, frame) {
      var method, method_block, method_name;
      method_name = Value(ast[0]);
      method = frame[method_name];
      if (method == null) {
        throw "unknown method " + method_name;
      }
      if (method instanceof Function) {
        method(frame, ast.slice(1, ast.length));
        return;
      }
      if (method.parent !== "Code") {
        throw "uncallable " + method_name;
      }
      method_block = method.children[0];
      return Statement(method_block);
    }
  };
  handle_data = function(data) {
    var program, stmt, _i, _len, _results;
    program = JSON.parse(data);
    _results = [];
    for (_i = 0, _len = program.length; _i < _len; _i++) {
      stmt = program[_i];
      _results.push(Statement(stmt));
    }
    return _results;
  };
  fs = require('fs');
  fn = process.argv[2];
  if (fn) {
    data = fs.readFileSync(fn).toString();
    handle_data(data);
  } else {
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
  }
}).call(this);
