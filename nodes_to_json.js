(function() {
  var CoffeeScript, data, fn, fs, handle_data, stdin, wrap, wrap_obj;
  if (typeof window === "undefined" || window === null) {
    CoffeeScript = require("coffee-script");
  }
  wrap = function(expressions) {
    return expressions = expressions.map(function(expression) {
      return wrap_obj(expression);
    });
  };
  wrap_obj = function(expression) {
    var key, keys, list_key, list_keys, my_cases, name, obj, when_statement, _i, _j, _k, _len, _len2, _len3, _ref;
    expression.children = void 0;
    keys = ['array', 'attempt', 'base', 'body', 'condition', 'elseBody', 'error', 'ensure', 'expression', 'first', 'from', 'index', 'name', 'object', 'otherwise', 'parent', 'range', 'recovery', 'second', 'source', 'subject', 'to', 'value', 'variable'];
    for (_i = 0, _len = keys.length; _i < _len; _i++) {
      key = keys[_i];
      if (expression[key]) {
        expression[key] = wrap_obj(expression[key]);
      }
    }
    list_keys = ['args', 'expressions', 'objects', 'params', 'properties'];
    for (_j = 0, _len2 = list_keys.length; _j < _len2; _j++) {
      list_key = list_keys[_j];
      if (expression[list_key]) {
        expression[list_key] = wrap(expression[list_key]);
      }
    }
    if (expression.cases) {
      my_cases = [];
      _ref = expression.cases;
      for (_k = 0, _len3 = _ref.length; _k < _len3; _k++) {
        when_statement = _ref[_k];
        my_cases.push({
          cond: wrap_obj(when_statement[0]),
          block: wrap_obj(when_statement[1])
        });
      }
      expression.cases = my_cases;
    }
    name = expression.constructor.name;
    if (name === 'Obj') {
      expression.objects = void 0;
    }
    if (name && name !== 'Array' && name !== "String" && name !== "Object") {
      obj = {};
      obj[name] = expression;
      return obj;
    } else {
      return expression;
    }
  };
  handle_data = function(data) {
    var expressions;
    expressions = CoffeeScript.nodes(data).expressions;
    return console.log(JSON.stringify(wrap(expressions), null, "  "));
  };
  if (typeof window !== "undefined" && window !== null) {
    window.CoffeeCoffee.nodes_to_json = function(code) {
      var expressions;
      expressions = window.CoffeeScript.nodes(code).expressions;
      return wrap(expressions);
    };
    window.CoffeeCoffee.ast_to_json = function(ast) {
      if (ast.expressions != null) {
        return wrap(ast.expressions);
      } else {
        return [wrap_obj(ast)];
      }
    };
  } else {
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
  }
}).call(this);
