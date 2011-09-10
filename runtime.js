(function() {
  var Deref, Eval, Frame, Op, Runtime, Statement, data, fn, fs, handle_data, pp, stdin;
  Statement = function(ast, frame) {
    var method;
    method = Runtime[ast.parent];
    if (method) {
      return method(ast.children, frame);
    } else {
      return console.log("Statement not supported:", ast.parent);
    }
  };
  pp = function(obj, description) {
    console.log("-----");
    console.log(description);
    return console.log(JSON.stringify(obj, null, "  "));
  };
  Frame = function() {
    var self;
    return self = {
      console: {
        log: function(frame, parms) {
          return console.log(Eval(frame, parms[0]));
        }
      }
    };
  };
  Deref = function(obj, accessors) {
    var accessor, result, _i, _len;
    result = obj;
    for (_i = 0, _len = accessors.length; _i < _len; _i++) {
      accessor = accessors[_i];
      result = result[accessor.value];
    }
    return result;
  };
  Eval = function(frame, ast) {
    if (ast.value) {
      if (ast.value.charAt(0) === '"') {
        return JSON.parse(ast.value);
      } else if (ast.value.match(/\d+/) !== null) {
        return parseInt(ast.value);
      } else {
        return frame[ast.value];
      }
    } else {
      if (ast.parent === 'Code') {
        return function(frame, params) {
          return Statement(ast.children[0], frame);
        };
      }
      if (ast.parent.kind === "Op") {
        return Op(frame, ast.parent.value, ast.children);
      }
      return Deref(frame[ast.parent.value], ast.children);
    }
  };
  Op = function(frame, op, children) {
    var operand1, operand2;
    operand1 = Eval(frame, children[0]);
    operand2 = Eval(frame, children[1]);
    if (op === '*') {
      return operand1 * operand2;
    }
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
      rhs = Eval(frame, ast[1]);
      return frame[lhs] = rhs;
    },
    Call: function(ast, frame) {
      var method;
      method = Eval(frame, ast[0]);
      return method(frame, ast.slice(1, ast.length));
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
