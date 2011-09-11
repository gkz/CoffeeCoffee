(function() {
  var Deref, Eval, Frame, Function, Op, Runtime, Statement, data, fn, fs, handle_data, pp, statements, stdin;
  Statement = function(ast, frame) {
    var method;
    method = Runtime[ast.parent];
    console.log("Statement", ast.parent);
    if (method) {
      return method(ast.children, frame);
    } else {
      return console.log("Statement not supported:", ast.parent);
    }
  };
  pp = function(obj, description) {
    console.log("-----");
    if (description != null) {
      console.log(description);
    }
    return console.log(JSON.stringify(obj, null, "  "));
  };
  Frame = function(params) {
    var key, self;
    self = {
      console: {
        log: function(frame, parms) {
          var arr, parm, _i, _len;
          arr = [];
          for (_i = 0, _len = parms.length; _i < _len; _i++) {
            parm = parms[_i];
            arr.push(Eval(frame, parm));
          }
          return console.log('YO', arr.join(' '));
        }
      }
    };
    for (key in params) {
      self[key] = params[key];
    }
    return self;
  };
  Deref = function(frame, obj, accessors) {
    var accessor, index, result, _i, _len;
    result = obj;
    for (_i = 0, _len = accessors.length; _i < _len; _i++) {
      accessor = accessors[_i];
      if (accessor.parent === 'Index') {
        index = Eval(frame, accessor.children[0]);
        console.log("*******");
        console.log(frame);
        console.log(result);
        console.log("*******");
        result = result[index];
      } else {
        result = result[accessor.value];
      }
    }
    return result;
  };
  Function = function(frame, ast, params) {
    var child_ast, param_values, _i, _len, _results;
    param_values = {};
    _results = [];
    for (_i = 0, _len = ast.length; _i < _len; _i++) {
      child_ast = ast[_i];
      if (child_ast.kind === "Param") {
        param_values[child_ast.value] = Eval(frame, params.shift());
      } else if (child_ast.parent === "Block") {
        return Runtime.Block(child_ast.children, frame, param_values);
      }
    }
    return _results;
  };
  Eval = function(frame, ast) {
    var arr, child, _i, _len, _ref;
    if (ast.value) {
      if (ast.value.charAt(0) === '"') {
        return JSON.parse(ast.value);
      } else if (ast.value.match(/\d+/) !== null) {
        return parseInt(ast.value);
      } else {
        return frame[ast.value];
      }
    } else {
      if (Runtime[ast.parent]) {
        return Runtime[ast.parent](ast.children, frame);
      }
      if (ast.parent === 'Code') {
        return function(frame, params) {
          return Function(frame, ast.children, params);
        };
      }
      if (ast.parent === "Arr") {
        arr = [];
        _ref = ast.children;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          child = _ref[_i];
          arr.push(Eval(frame, child));
        }
        return arr;
      }
      if (ast.parent === "Value") {
        return Eval(frame, ast.children[0]);
      }
      if (ast.parent === "Parens") {
        return Eval(frame, ast.children[0].children[0]);
      }
      if (ast.parent.kind === "Op") {
        return Op(frame, ast.parent.value, ast.children);
      }
      return Deref(frame, frame[ast.parent.value], ast.children);
    }
  };
  Op = function(frame, op, children) {
    var operand1, operand2;
    if (op === '-') {
      operand1 = Eval(frame, children[0]);
      if (op === '-') {
        return -1 * operand1;
      } else {
        throw "unknown op " + op;
      }
    } else {
      operand1 = Eval(frame, children[0]);
      operand2 = Eval(frame, children[1]);
      if (op === '*') {
        return operand1 * operand2;
      }
      if (op === '+') {
        return operand1 + operand2;
      }
      if (op === '===') {
        console.log(frame);
        console.log('Trequals', operand1, operand2);
        return operand1 === operand2;
      }
      if (op === '>>') {
        return operand1 >> operand2;
      }
      if (op === '<') {
        return operand1 < operand2;
      }
      throw "unknown op " + op;
    }
  };
  statements = function(frame, code) {
    var retval, stmt, _i, _len, _results;
    _results = [];
    for (_i = 0, _len = code.length; _i < _len; _i++) {
      stmt = code[_i];
      if (stmt.parent === "Return") {
        retval = Eval(frame, stmt.children[0]);
        throw {
          retval: retval
        };
        return retval;
      }
      _results.push(Statement(stmt, frame));
    }
    return _results;
  };
  Runtime = {
    Block: function(ast, frame, param_values) {
      if (param_values == null) {
        param_values = {};
      }
      frame = Frame(param_values);
      try {
        return statements(frame, ast);
      } catch (e) {
        if (e.retval) {
          console.log("RETURN", e.retval);
          return e.retval;
        }
        throw e;
      }
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
    },
    While: function(ast, frame) {
      var code, expr, _results;
      expr = ast[0];
      code = ast[1].children;
      _results = [];
      while (Eval(frame, expr)) {
        _results.push(statements(frame, code));
      }
      return _results;
    },
    If: function(ast, frame) {
      var code, expr;
      expr = Eval(frame, ast[0]);
      if (expr) {
        code = ast[1].children;
        return statements(frame, code);
      } else {
        if (ast[2]) {
          code = ast[2].children;
          return statements(frame, code);
        }
      }
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
