(function() {
  var AST, Build, DEDENT, INDENT, PUT, TAB, data, fn, fs, handle_data, pp, stdin, the_key_of, transcompile;
  var __slice = Array.prototype.slice, __indexOf = Array.prototype.indexOf || function(item) {
    for (var i = 0, l = this.length; i < l; i++) {
      if (this[i] === item) return i;
    }
    return -1;
  };
  handle_data = function(data) {
    var program;
    program = JSON.parse(data);
    return transcompile(program);
  };
  transcompile = function(program) {
    var stmt, _i, _len, _results;
    _results = [];
    for (_i = 0, _len = program.length; _i < _len; _i++) {
      stmt = program[_i];
      _results.push(Build(stmt));
    }
    return _results;
  };
  Build = function(ast) {
    var method, name, node;
    name = the_key_of(ast);
    method = AST[name];
    if (method) {
      node = ast[name];
      return method(node);
    }
    throw "" + name + " not supported yet";
  };
  TAB = '';
  PUT = function(s, f) {
    console.log(TAB, s);
    if (f) {
      INDENT();
      f();
      return DEDENT();
    }
  };
  INDENT = function() {
    return TAB += '  ';
  };
  DEDENT = function() {
    return TAB = TAB.slice(0, TAB.length - 2);
  };
  AST = {
    deref_properties: function(scope, obj, properties) {
      var accessor, key, last_property, _i, _len, _ref, _ref2;
      _ref = properties.slice(0, properties.length - 1);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        accessor = _ref[_i];
        key = Build(scope, accessor);
        obj = obj[key];
      }
      last_property = properties[properties.length - 1];
      if (((_ref2 = last_property.Access) != null ? _ref2.proto : void 0) === ".prototype") {
        obj = obj.prototype;
      }
      key = Build(scope, last_property);
      return [obj, key];
    },
    name: function(ast) {
      return ast.name.Literal.value;
    },
    Access: function(scope, ast) {
      return AST.name(ast);
    },
    Arr: function(ast) {
      return PUT("ARR", function() {
        var object, _i, _len, _ref, _results;
        _ref = ast.objects;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          object = _ref[_i];
          _results.push(Build(object));
        }
        return _results;
      });
    },
    Assign: function(ast) {
      var LHS, context, rhs, set;
      context = ast.context || '=';
      LHS = function(lhs) {
        if (lhs.Value != null) {
          return LHS(lhs.Value.base);
        } else if (lhs.Literal != null) {
          return PUT(lhs.Literal.value);
        } else {
          return PUT("ARR", function() {
            var object, _i, _len, _ref, _results;
            _ref = lhs.Arr.objects;
            _results = [];
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              object = _ref[_i];
              _results.push(LHS(object.Value.base));
            }
            return _results;
          });
        }
      };
      PUT("ASSIGN " + context, function() {
        LHS(ast.variable);
        return Build(ast.value);
      });
      return;
      context = ast.context;
      set = function(scope, ast, value) {
        var method, name;
        name = the_key_of(ast);
        method = LHS[name];
        if (method) {
          return method(scope, ast[name], value);
        }
        throw "" + name + " not supported yet on LHS";
      };
      LHS = {
        Arr: function(scope, ast, value) {
          var i, num_to_grab, object, _len, _ref, _results;
          _ref = ast.objects;
          _results = [];
          for (i = 0, _len = _ref.length; i < _len; i++) {
            object = _ref[i];
            _results.push(object.Splat != null ? (num_to_grab = value.length - ast.objects.length + 1, set(scope, object.Splat.name, value.slice(i, i + num_to_grab))) : set(scope, object, value[i]));
          }
          return _results;
        },
        Obj: function(scope, ast, value) {
          var key, name, property, val, _i, _len, _ref, _results;
          _ref = ast.properties;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            property = _ref[_i];
            _results.push(property.Assign != null ? (key = property.Assign.variable.Value.base.Literal.value, val = value[key], set(scope, property.Assign.value, val)) : (name = property.Value.base.Literal.value, scope.set(name, value[name])));
          }
          return _results;
        },
        Value: function(scope, ast, value) {
          var base_key, key, lhs, _ref;
          if (ast.properties.length === 0) {
            base_key = the_key_of(ast.base);
            if (base_key === "Arr" || base_key === "Obj") {
              return set(scope, ast.base, value);
            } else {
              lhs = ast.base.Literal.value;
              PUT("ASSIGN " + context);
              PUT(lhs);
              return PUT(value);
            }
          } else {
            lhs = Build(scope, ast.base);
            _ref = AST.deref_properties(scope, lhs, ast.properties), lhs = _ref[0], key = _ref[1];
            return update_variable_reference(lhs, key, value, context);
          }
        }
      };
      rhs = Build(scope, ast.value);
      return set(scope, ast.variable, rhs);
    },
    Block: function(ast) {
      var code, stmt, _i, _len, _results;
      code = ast.expressions;
      _results = [];
      for (_i = 0, _len = code.length; _i < _len; _i++) {
        stmt = code[_i];
        _results.push(Build(stmt));
      }
      return _results;
    },
    Call: function(ast) {
      var CURRENT_OBJECT_METHOD_NAME, arg, args, key, obj, old_method_name, properties, this_var, val, variable, _i, _len, _ref, _ref2;
      PUT("CALL", function() {
        return PUT("ARGS", function() {
          var arg, _i, _len, _ref, _results;
          _ref = ast.args;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            arg = _ref[_i];
            _results.push(Build(arg));
          }
          return _results;
        });
      });
      return;
      args = [];
      _ref = ast.args;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        arg = _ref[_i];
        if (arg.Splat != null) {
          args = args.concat(Build(scope, arg.Splat.name));
        } else {
          args.push(Build(scope, arg));
        }
      }
      if (ast.isSuper) {
        this_var = scope.get("this");
        this_var.__super__[CURRENT_OBJECT_METHOD_NAME].apply(this_var, args);
        return;
      }
      variable = ast.variable.Value;
      obj = Build(scope, variable.base);
      properties = variable.properties;
      if (ast.isNew) {
        Debugger.info("new " + obj + " with args: " + args);
        val = newify(obj, args);
        return val;
      }
      if (properties.length === 0) {
        Debugger.info("call with args: " + args);
        val = obj.apply(null, args);
      } else {
        _ref2 = AST.deref_properties(scope, obj, properties), obj = _ref2[0], key = _ref2[1];
        if (!(obj[key] != null)) {
          throw "method " + key + " does not exist for obj " + obj;
        }
        old_method_name = CURRENT_OBJECT_METHOD_NAME;
        CURRENT_OBJECT_METHOD_NAME = key;
        try {
          Debugger.info("call " + key + " with args: " + args);
          val = obj[key].apply(obj, args);
        } finally {
          CURRENT_OBJECT_METHOD_NAME = old_method_name;
        }
      }
      Debugger.info("return " + val);
      return val;
    },
    Class: function(scope, ast) {
      var block_ast, class_code, class_name, expressions, klass, parent_class, proto;
      class_name = ast.variable.Value.base.Literal.value;
      expressions = ast.body.Block.expressions;
      if (expressions.length === 0) {
        class_code = null;
        block_ast = null;
      } else if (expressions.length === 1) {
        class_code = null;
        block_ast = expressions[0];
      } else {
        class_code = expressions[0], block_ast = expressions[1];
      }
      if (class_code) {
        Build(scope, class_code);
      }
      if (block_ast) {
        proto = Build(scope, block_ast);
      } else {
        proto = function() {};
      }
      if (ast.parent) {
        parent_class = Build(scope, ast.parent);
      } else {
        parent_class = null;
      }
      klass = build_class(proto, parent_class);
      klass.toString = function() {
        return "[class " + class_name + "]";
      };
      return scope.set(class_name, klass);
    },
    Code: function(ast) {
      var f, obj;
      PUT('CODE', function() {
        return PUT('PARAMS', function() {
          var param, _i, _len, _ref, _results;
          _ref = ast.params;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            param = _ref[_i];
            PUT(param.Param.name.Literal.value);
            _results.push(Build(ast.body));
          }
          return _results;
        });
      });
      return;
      f = function() {
        var arg, args, field, my_args, param, parms, sub_scope, val, _i, _j, _len, _len2, _ref, _ref2;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        for (_i = 0, _len = args.length; _i < _len; _i++) {
          arg = args[_i];
          my_args = arg;
        }
        parms = {};
        _ref = ast.params;
        for (_j = 0, _len2 = _ref.length; _j < _len2; _j++) {
          param = _ref[_j];
          param = param.Param;
          if (param.splat) {
            val = args;
          } else {
            val = args.shift();
          }
          if (val === void 0 && param.value) {
            val = Build(scope, param.value);
          }
          if ((_ref2 = param.name.Value) != null ? _ref2.properties : void 0) {
            field = AST.name(param.name.Value.properties[0].Access);
            Debugger.info("this." + field + " = " + val);
            this[field] = val;
          } else {
            field = AST.name(param);
            parms[field] = val;
          }
        }
        sub_scope = Scope(parms, scope, this, my_args);
        try {
          return Build(sub_scope, ast.body);
        } catch (e) {
          if (e.retval != null) {
            return e.retval.obj;
          }
          throw e;
        }
      };
      if (ast.bound) {
        obj = scope.get("this");
        return function() {
          var args;
          args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          return f.apply(obj, args);
        };
      }
      f.toString = function() {
        return "[function]";
      };
      return f;
    },
    Existence: function(scope, ast) {
      var val;
      try {
        val = Build(scope, ast.expression);
      } catch (e) {
        if (e.__meta == null) {
          throw e;
        }
        return false;
      }
      return val != null;
    },
    For: function(scope, ast) {
      var key_val, key_var, obj, range, step_val, step_var, val, val_val, val_var, _i, _len, _results, _results2;
      if (ast.index) {
        obj = Build(scope, ast.source);
        key_var = ast.index.Literal.value;
        val_var = ast.name && AST.name(ast);
        _results = [];
        for (key_val in obj) {
          val_val = obj[key_val];
          Debugger.set_line_number(ast);
          Debugger.info("loop on " + key_var);
          scope.set(key_var, key_val);
          if (val_var != null) {
            scope.set(val_var, val_val);
          }
          try {
            val = Build(scope, ast.body);
          } catch (e) {
            if (e.__meta_break) {
              break;
            }
            if (e.__meta_continue) {
              continue;
            }
            throw e;
          }
          _results.push(val);
        }
        return _results;
      } else {
        range = Build(scope, ast.source);
        step_var = AST.name(ast);
        _results2 = [];
        for (_i = 0, _len = range.length; _i < _len; _i++) {
          step_val = range[_i];
          Debugger.set_line_number(ast);
          Debugger.info("loop on " + step_var);
          scope.set(step_var, step_val);
          try {
            val = Build(scope, ast.body);
          } catch (e) {
            if (e.__meta_break) {
              break;
            }
            if (e.__meta_continue) {
              continue;
            }
            throw e;
          }
          _results2.push(val);
        }
        return _results2;
      }
    },
    If: function(ast) {
      PUT("IF", function() {
        PUT("COND", function() {
          return Build(ast.condition);
        });
        return PUT("THEN", function() {
          return Build(ast.body);
        });
      });
      return;
      if (Build(scope, ast.condition)) {
        return Build(scope, ast.body);
      } else if (ast.elseBody) {
        return Build(scope, ast.elseBody);
      }
    },
    In: function(scope, ast) {
      var array, object, val;
      object = Build(scope, ast.object);
      array = Build(scope, ast.array);
      val = __indexOf.call(array, object) >= 0;
      if (ast.negated) {
        val = !val;
      }
      return val;
    },
    Index: function(scope, ast) {
      return Build(scope, ast.index);
    },
    Literal: function(ast) {
      var literal, value;
      value = ast.value;
      literal = function() {
        var float, match, regex;
        if (value === 'false') {
          return false;
        }
        if (value === 'true') {
          return true;
        }
        if (value === 'null') {
          return null;
        }
        if (value === 'undefined') {
          return;
        }
        if (value === 'break') {
          throw {
            __meta_break: true
          };
        }
        if (value === 'continue') {
          throw {
            __meta_continue: true
          };
        }
        if (value.charAt(0) === '"') {
          return JSON.parse(value);
        }
        if (value.charAt(0) === "'") {
          return JSON.parse('"' + value.substring(1, value.length - 1) + '"');
        }
        if (value.match(/\d+/) !== null) {
          float = parseFloat(value);
          return PUT("NUMBER " + float);
        }
        if (value.charAt(0) === '/') {
          regex = /\/(.*)\/(.*)/;
          match = regex.exec(value);
          return RegExp(match[1], match[2]);
        }
        return PUT("EVAL " + value);
      };
      return literal();
    },
    Obj: function(scope, ast) {
      var LHS, obj, property, value, _i, _len, _ref;
      obj = {};
      _ref = ast.properties;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        property = _ref[_i];
        ast = property.Assign;
        LHS = {
          set: function(ast, value) {
            var method, name;
            name = the_key_of(ast);
            method = LHS[name];
            if (method) {
              return method(ast[name], value);
            }
            throw "" + name + " not supported yet on Obj LHS";
          },
          Literal: function(ast, value) {
            var lhs;
            lhs = ast.value;
            obj[lhs] = value;
            return Debugger.info("Obj: " + lhs + ": " + value);
          },
          Value: function(ast, value) {
            return LHS.set(ast.base, value);
          }
        };
        value = Build(scope, ast.value);
        LHS.set(ast.variable, value);
      }
      return obj;
    },
    Op: function(ast) {
      var class_function, class_name, is_chainable, op, operand1;
      is_chainable = function(op) {
        return op === '<' || op === '>' || op === '>=' || op === '<=' || op === '===' || op === '!==';
      };
      op = ast.operator;
      if (op === '++' || op === '--') {
        return AST.Assign(scope, {
          context: op,
          variable: ast.first,
          value: ast.first
        });
      }
      if (op === "?") {
        try {
          return Build(scope, ast.first);
        } catch (e) {
          if (e.__meta && e.__type === 'reference') {
            return Build(scope, ast.second);
          }
        }
      }
      if (op === 'new') {
        class_name = ast.first.Value.base.Literal.value;
        class_function = scope.get(class_name);
        return newify(class_function, []);
      }
      if (op === '&&') {
        return Build(scope, ast.first) && Build(scope, ast.second);
      }
      if (ast.second) {
        if (is_chainable(op) && the_key_of(ast.first) === "Op" && is_chainable(ast.first.Op.operator)) {
          if (!operand1) {
            return false;
          }
          operand1 = Build(scope, ast.first.Op.second);
        }
        PUT("BINARY_OP " + op, function() {
          Build(ast.first);
          return Build(ast.second);
        });
        return;
      } else {
        PUT("UNARY_OP " + op, function() {
          return Build(ast.first);
        });
        return;
      }
      throw "unknown op " + op;
    },
    Parens: function(ast) {
      var body;
      body = ast.body;
      if (body.Block != null) {
        body = body.Block;
      }
      if (body.expressions) {
        return Build(body.expressions[0]);
      } else {
        return Build(body);
      }
    },
    Range: function(scope, ast) {
      var from_val, to_val, _i, _j, _results, _results2;
      from_val = Build(scope, ast.from);
      to_val = Build(scope, ast.to);
      if (ast.exclusive) {
        return (function() {
          _results = [];
          for (var _i = from_val; from_val <= to_val ? _i < to_val : _i > to_val; from_val <= to_val ? _i++ : _i--){ _results.push(_i); }
          return _results;
        }).apply(this, arguments);
      } else {
        return (function() {
          _results2 = [];
          for (var _j = from_val; from_val <= to_val ? _j <= to_val : _j >= to_val; from_val <= to_val ? _j++ : _j--){ _results2.push(_j); }
          return _results2;
        }).apply(this, arguments);
      }
    },
    Return: function(ast) {
      return PUT("RETURN", function() {
        return Build(ast.expression);
      });
    },
    Slice: function(scope, ast) {
      var from_val, range, to_val;
      range = ast.range.Range;
      from_val = Build(scope, range.from);
      to_val = Build(scope, range.to);
      if (!range.exclusive) {
        to_val += 1;
      }
      return {
        from_val: from_val,
        to_val: to_val
      };
    },
    Switch: function(scope, ast) {
      var case_ast, match_value, subject, _i, _len, _ref;
      subject = Build(scope, ast.subject);
      _ref = ast.cases;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        case_ast = _ref[_i];
        match_value = Build(scope, case_ast.cond);
        if (subject === match_value) {
          return Build(scope, case_ast.block);
        }
      }
      if (ast.otherwise) {
        return Build(scope, ast.otherwise);
      }
      return null;
    },
    Throw: function(scope, ast) {
      var e;
      e = Build(scope, ast.expression);
      throw {
        __meta: e
      };
    },
    Try: function(scope, ast) {
      var catch_var;
      try {
        return Build(scope, ast.attempt);
      } catch (e) {
        if (e.__meta == null) {
          throw e;
        }
        catch_var = ast.error.Literal.value;
        scope.set(catch_var, e.__meta);
        return Build(scope, ast.recovery);
      } finally {
        if (ast.ensure) {
          Build(scope, ast.ensure);
        }
      }
    },
    Value: function(ast) {
      var key, last_property, obj, prior, priors, properties, property, slice, _i, _len, _ref, _ref2;
      if (ast.properties.length === 0) {
        Build(ast.base);
      } else {
        properties = ast.properties;
        last_property = properties[properties.length - 1];
        priors = properties.slice(0, properties.length - 1);
        prior = function() {
          return AST.Value({
            base: ast.base,
            properties: priors
          });
        };
        if (last_property.Access != null) {
          PUT("ACCESS", function() {
            prior();
            return PUT(last_property.Access.name.Literal.value);
          });
        } else if (last_property.Index != null) {
          PUT("INDEX", function() {
            prior();
            return Build(last_property.Index.index);
          });
        } else {
          throw "yo";
        }
        return;
      }
      _ref = ast.properties;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        property = _ref[_i];
        if (((_ref2 = property.Access) != null ? _ref2.soak : void 0) && !(typeof obj !== "undefined" && obj !== null)) {
          break;
        }
        key = the_key_of(property);
        if (key === 'Slice') {
          slice = Build(scope, property);
          obj = obj.slice(slice.from_val, slice.to_val);
        } else if (key === 'Access') {
          key = Build(scope, property);
          obj = obj[key];
          Debugger.info("deref " + key + " -> " + obj);
        } else if (key === "Index") {
          key = Build(scope, property);
          obj = obj[key];
          Debugger.info("deref [" + key + "] -> " + obj);
        } else {
          throw "unexpected key " + key;
        }
      }
      return obj;
    },
    While: function(ast) {
      var cond, val, _results;
      PUT("WHILE", function() {
        PUT("COND", function() {
          return PUT("cond");
        });
        return PUT("DO", function() {
          return Build(ast.body);
        });
      });
      return;
      _results = [];
      while (true) {
        Debugger.info("while <condition>...");
        cond = Build(scope, ast.condition);
        if (cond) {
          Debugger.info("(while cond true)");
        } else {
          Debugger.info("(while cond false)");
          break;
        }
        try {
          val = Build(scope, ast.body);
        } catch (e) {
          if (e.__meta_break) {
            break;
          }
          if (e.__meta_continue) {
            continue;
          }
          throw e;
        }
        _results.push(val);
      }
      return _results;
    }
  };
  the_key_of = function(ast) {
    var key;
    for (key in ast) {
      return key;
    }
  };
  pp = function(obj, description) {
    var util;
    util = require('util');
    util.debug("-----");
    if (description != null) {
      util.debug(description);
    }
    return util.debug(JSON.stringify(obj, null, "  "));
  };
  if (typeof window !== "undefined" && window !== null) {
    window.transcompile = transcompile;
    window.Debugger = Debugger;
  } else {
    fs = require('fs');
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
