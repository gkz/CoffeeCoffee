(function() {
  var AST, CURRENT_OBJECT_METHOD_NAME, Debugger, Eval, Scope, build_class, coffeecoffee, data, fn, fs, handle_data, internal_throw, newify, pp, stdin, the_key_of, update_variable_reference;
  var __slice = Array.prototype.slice, __indexOf = Array.prototype.indexOf || function(item) {
    for (var i = 0, l = this.length; i < l; i++) {
      if (this[i] === item) return i;
    }
    return -1;
  };
  handle_data = function(data) {
    var program;
    program = JSON.parse(data);
    return coffeecoffee(program);
  };
  coffeecoffee = function(program) {
    var scope, stmt, _i, _len, _results;
    scope = Scope();
    _results = [];
    for (_i = 0, _len = program.length; _i < _len; _i++) {
      stmt = program[_i];
      _results.push(Eval(scope, stmt));
    }
    return _results;
  };
  Eval = function(scope, ast) {
    var method, name, node;
    name = the_key_of(ast);
    method = AST[name];
    if (method) {
      node = ast[name];
      Debugger.set_line_number(node);
      Debugger.info(name);
      return method(scope, node);
    }
    throw "" + name + " not supported yet";
  };
  CURRENT_OBJECT_METHOD_NAME = null;
  AST = {
    deref_properties: function(scope, obj, properties) {
      var accessor, key, last_property, _i, _len, _ref, _ref2;
      _ref = properties.slice(0, properties.length - 1);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        accessor = _ref[_i];
        key = Eval(scope, accessor);
        obj = obj[key];
      }
      last_property = properties[properties.length - 1];
      if (((_ref2 = last_property.Access) != null ? _ref2.proto : void 0) === ".prototype") {
        obj = obj.prototype;
      }
      key = Eval(scope, last_property);
      return [obj, key];
    },
    name: function(ast) {
      return ast.name.Literal.value;
    },
    Access: function(scope, ast) {
      return AST.name(ast);
    },
    Arr: function(scope, ast) {
      var objects;
      objects = ast.objects;
      return objects.map(function(obj) {
        return Eval(scope, obj);
      });
    },
    Assign: function(scope, ast) {
      var LHS, context, rhs, set;
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
              return scope.set(lhs, value, context);
            }
          } else {
            lhs = Eval(scope, ast.base);
            _ref = AST.deref_properties(scope, lhs, ast.properties), lhs = _ref[0], key = _ref[1];
            return update_variable_reference(lhs, key, value, context);
          }
        }
      };
      rhs = Eval(scope, ast.value);
      return set(scope, ast.variable, rhs);
    },
    Block: function(scope, ast) {
      var code, stmt, val, _i, _len;
      code = ast.expressions;
      for (_i = 0, _len = code.length; _i < _len; _i++) {
        stmt = code[_i];
        val = Eval(scope, stmt);
      }
      return val;
    },
    Call: function(scope, ast) {
      var arg, args, key, obj, old_method_name, properties, this_var, val, variable, _i, _len, _ref, _ref2;
      args = [];
      _ref = ast.args;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        arg = _ref[_i];
        if (arg.Splat != null) {
          args = args.concat(Eval(scope, arg.Splat.name));
        } else {
          args.push(Eval(scope, arg));
        }
      }
      if (ast.isSuper) {
        this_var = scope.get("this");
        this_var.__super__[CURRENT_OBJECT_METHOD_NAME].apply(this_var, args);
        return;
      }
      variable = ast.variable.Value;
      obj = Eval(scope, variable.base);
      properties = variable.properties;
      if (ast.isNew) {
        val = newify(obj, args);
        Debugger.info("new " + obj + " with args: " + args);
        return val;
      }
      if (properties.length === 0) {
        return val = obj.apply(null, args);
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
        return val;
      }
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
        Eval(scope, class_code);
      }
      if (block_ast) {
        proto = Eval(scope, block_ast);
      } else {
        proto = function() {};
      }
      if (ast.parent) {
        parent_class = Eval(scope, ast.parent);
      } else {
        parent_class = null;
      }
      klass = build_class(proto, parent_class);
      klass.toString = function() {
        return "[class " + class_name + "]";
      };
      return scope.set(class_name, klass);
    },
    Code: function(scope, ast) {
      var f, obj;
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
            val = Eval(scope, param.value);
          }
          if ((_ref2 = param.name.Value) != null ? _ref2.properties : void 0) {
            field = AST.name(param.name.Value.properties[0].Access);
            this[field] = val;
          } else {
            field = AST.name(param);
            parms[field] = val;
          }
        }
        sub_scope = Scope(parms, scope, this, my_args);
        try {
          return Eval(sub_scope, ast.body);
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
        val = Eval(scope, ast.expression);
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
        obj = Eval(scope, ast.source);
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
            val = Eval(scope, ast.body);
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
        range = Eval(scope, ast.source);
        step_var = AST.name(ast);
        _results2 = [];
        for (_i = 0, _len = range.length; _i < _len; _i++) {
          step_val = range[_i];
          Debugger.set_line_number(ast);
          Debugger.info("loop on " + step_var);
          scope.set(step_var, step_val);
          try {
            val = Eval(scope, ast.body);
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
    If: function(scope, ast) {
      if (Eval(scope, ast.condition)) {
        return Eval(scope, ast.body);
      } else if (ast.elseBody) {
        return Eval(scope, ast.elseBody);
      }
    },
    In: function(scope, ast) {
      var array, object, val;
      object = Eval(scope, ast.object);
      array = Eval(scope, ast.array);
      val = __indexOf.call(array, object) >= 0;
      if (ast.negated) {
        val = !val;
      }
      return val;
    },
    Index: function(scope, ast) {
      return Eval(scope, ast.index);
    },
    Literal: function(scope, ast) {
      var match, regex, value;
      value = ast.value;
      if (value) {
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
          return parseFloat(value);
        }
        if (value.charAt(0) === '/') {
          regex = /\/(.*)\/(.*)/;
          match = regex.exec(value);
          return RegExp(match[1], match[2]);
        }
        return scope.get(value);
      }
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
            return obj[lhs] = value;
          },
          Value: function(ast, value) {
            return LHS.set(ast.base, value);
          }
        };
        value = Eval(scope, ast.value);
        LHS.set(ast.variable, value);
      }
      return obj;
    },
    Op: function(scope, ast) {
      var class_function, class_name, is_chainable, op, operand1, operand2, ops, val;
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
          return Eval(scope, ast.first);
        } catch (e) {
          if (e.__meta && e.__type === 'reference') {
            return Eval(scope, ast.second);
          }
        }
      }
      if (op === 'new') {
        class_name = ast.first.Value.base.Literal.value;
        class_function = scope.get(class_name);
        return newify(class_function, []);
      }
      if (op === '&&') {
        return Eval(scope, ast.first) && Eval(scope, ast.second);
      }
      if (ast.second) {
        operand1 = Eval(scope, ast.first);
        if (is_chainable(op) && the_key_of(ast.first) === "Op" && is_chainable(ast.first.Op.operator)) {
          if (!operand1) {
            return false;
          }
          operand1 = Eval(scope, ast.first.Op.second);
        }
        operand2 = Eval(scope, ast.second);
        ops = {
          '*': function() {
            return operand1 * operand2;
          },
          '/': function() {
            return operand1 / operand2;
          },
          '+': function() {
            return operand1 + operand2;
          },
          '-': function() {
            return operand1 - operand2;
          },
          '|': function() {
            return operand1 | operand2;
          },
          '&': function() {
            return operand1 & operand2;
          },
          '^': function() {
            return operand1 ^ operand2;
          },
          '===': function() {
            return operand1 === operand2;
          },
          '!==': function() {
            return operand1 !== operand2;
          },
          '>>': function() {
            return operand1 >> operand2;
          },
          '>>>': function() {
            return operand1 >>> operand2;
          },
          '<<': function() {
            return operand1 << operand2;
          },
          '||': function() {
            return operand1 || operand2;
          },
          '<': function() {
            return operand1 < operand2;
          },
          '<=': function() {
            return operand1 <= operand2;
          },
          '>': function() {
            return operand1 > operand2;
          },
          '>=': function() {
            return operand1 >= operand2;
          },
          '%': function() {
            return operand1 % operand2;
          },
          'in': function() {
            return operand1 in operand2;
          },
          'instanceof': function() {
            return operand1 instanceof operand2;
          }
        };
        if (ops[op]) {
          val = ops[op]();
          Debugger.info("Op: " + operand1 + " " + op + " " + operand2 + " -> " + val);
          return val;
        }
      } else {
        operand1 = Eval(scope, ast.first);
        ops = {
          '-': function() {
            return -1 * operand1;
          },
          '!': function() {
            return !operand1;
          },
          '~': function() {
            return ~operand1;
          },
          'typeof': function() {
            return typeof operand1;
          }
        };
        if (ops[op]) {
          return ops[op]();
        }
      }
      throw "unknown op " + op;
    },
    Parens: function(scope, ast) {
      var body;
      body = ast.body;
      if (body.Block != null) {
        body = body.Block;
      }
      if (body.expressions) {
        return Eval(scope, body.expressions[0]);
      } else {
        return Eval(scope, body);
      }
    },
    Range: function(scope, ast) {
      var from_val, to_val, _i, _j, _results, _results2;
      from_val = Eval(scope, ast.from);
      to_val = Eval(scope, ast.to);
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
    Return: function(scope, ast) {
      var retval;
      retval = {
        obj: Eval(scope, ast.expression)
      };
      throw {
        retval: retval
      };
    },
    Slice: function(scope, ast) {
      var from_val, range, to_val;
      range = ast.range.Range;
      from_val = Eval(scope, range.from);
      to_val = Eval(scope, range.to);
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
      subject = Eval(scope, ast.subject);
      _ref = ast.cases;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        case_ast = _ref[_i];
        match_value = Eval(scope, case_ast.cond);
        if (subject === match_value) {
          return Eval(scope, case_ast.block);
        }
      }
      if (ast.otherwise) {
        return Eval(scope, ast.otherwise);
      }
      return null;
    },
    Throw: function(scope, ast) {
      var e;
      e = Eval(scope, ast.expression);
      throw {
        __meta: e
      };
    },
    Try: function(scope, ast) {
      var catch_var;
      try {
        return Eval(scope, ast.attempt);
      } catch (e) {
        if (e.__meta == null) {
          throw e;
        }
        catch_var = ast.error.Literal.value;
        scope.set(catch_var, e.__meta);
        return Eval(scope, ast.recovery);
      } finally {
        if (ast.ensure) {
          Eval(scope, ast.ensure);
        }
      }
    },
    Value: function(scope, ast) {
      var key, obj, property, slice, _i, _len, _ref, _ref2;
      obj = Eval(scope, ast.base);
      _ref = ast.properties;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        property = _ref[_i];
        if (((_ref2 = property.Access) != null ? _ref2.soak : void 0) && !(obj != null)) {
          break;
        }
        key = the_key_of(property);
        if (key === 'Slice') {
          slice = Eval(scope, property);
          obj = obj.slice(slice.from_val, slice.to_val);
        } else if (key === 'Access') {
          key = Eval(scope, property);
          obj = obj[key];
          Debugger.info("deref " + key + " -> " + obj);
        } else if (key === "Index") {
          key = Eval(scope, property);
          obj = obj[key];
          Debugger.info("deref [" + key + "] -> " + obj);
        } else {
          throw "unexpected key " + key;
        }
      }
      return obj;
    },
    While: function(scope, ast) {
      var cond, val, _results;
      _results = [];
      while (true) {
        Debugger.info("while <condition>...");
        cond = Eval(scope, ast.condition);
        if (!cond) {
          break;
        }
        Debugger.info("(cond true)");
        try {
          val = Eval(scope, ast.body);
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
          if (context !== '=') {
            Debugger.info("" + var_name + " = " + closure_wrapper.obj + "...");
          }
          assigned_val = update_variable_reference(closure_wrapper, "obj", value, context);
          Debugger.info("" + var_name + " " + context + " " + value + " -> " + assigned_val);
          return assigned_val;
        } else if (context === "=") {
          Debugger.info("" + var_name + " = " + value + " (original set)");
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
          Debugger.info("deref " + var_name + " -> " + value);
          return value;
        }
        Debugger.info("deref " + var_name + " (builtin)");
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
  internal_throw = function(type, e) {
    throw {
      __meta: e,
      __type: type
    };
  };
  build_class = function(proto, superclass) {
    var X, extendify, key;
    extendify = function(child, parent) {
      var ctor, key;
      ctor = function() {
        this.constructor = child;
        return null;
      };
      for (key in parent) {
        if (Object.prototype.hasOwnProperty.call(parent, key)) {
          child[key] = parent[key];
        }
      }
      ctor.prototype = parent.prototype;
      child.prototype = new ctor;
      child.__super__ = parent.prototype;
      return child;
    };
    X = function() {
      this.__super__ = X.__super__;
      if (Object.prototype.hasOwnProperty.call(proto, "constructor")) {
        return proto.constructor.apply(this, arguments);
      } else if (superclass) {
        return X.__super__.constructor.apply(this, arguments);
      } else {
        return;
      }
    };
    if (superclass) {
      extendify(X, superclass);
    }
    for (key in proto) {
      X.prototype[key] = proto[key];
    }
    return X;
  };
  newify = function(func, args) {
    var child, ctor, result;
    ctor = function() {};
    ctor.prototype = func.prototype;
    child = new ctor;
    result = func.apply(child, args);
    if (typeof result === "object") {
      return result;
    } else {
      return child;
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
  Debugger = {
    info: function(s) {},
    set_line_number: function(ast) {
      if (ast.firstLineNumber) {
        return Debugger.highlight_line(ast.firstLineNumber);
      }
    },
    highlight_line: function(line_number) {}
  };
  if (typeof window !== "undefined" && window !== null) {
    window.coffeecoffee = coffeecoffee;
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
