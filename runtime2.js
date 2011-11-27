(function() {
  var Compile, Compiler, GetBlock, RunTime, Scope, Shift, binary_ops, build_class, data, fn, fs, handle_data, indenter, iterate_callbacks, newify, parser, stdin, unary_ops, update_variable_reference;
  var __slice = Array.prototype.slice;
  Compiler = {
    'ACCESS': function(arg, block) {
      var access, value_code;
      value_code = Compile(block);
      access = Shift(block);
      return function(rt, cb) {
        return rt.call(value_code, function(val) {
          return cb(val[access]);
        });
      };
    },
    'ARGS': function(arg, block) {
      var arg_codes;
      arg_codes = [];
      while (block.len() > 0) {
        arg_codes.push(Compile(block));
      }
      return function(rt, cb) {
        var args, f, last;
        args = [];
        f = function(arg_code, cb) {
          return rt.call(arg_code, function(my_arg) {
            args.push(my_arg);
            return cb(true);
          });
        };
        last = function() {
          return cb(args);
        };
        return iterate_callbacks(f, last, arg_codes);
      };
    },
    'ARR': function(arg, block) {
      var arr_exprs;
      arr_exprs = [];
      while (block.len() > 0) {
        arr_exprs.push(Compile(block));
      }
      return function(rt, cb) {
        var arr, f, last;
        arr = [];
        f = function(elem_expr, cb) {
          return rt.call(elem_expr, function(val) {
            arr.push(val);
            return cb(true);
          });
        };
        last = function() {
          return cb(arr);
        };
        return iterate_callbacks(f, last, arr_exprs);
      };
    },
    'ASSIGN': function(arg, block) {
      var assign, build_assign, context, name, subarg, subblock, value_code, _ref;
      _ref = GetBlock(block), name = _ref[0], subarg = _ref[1], subblock = _ref[2];
      value_code = Compile(block);
      context = arg;
      build_assign = function(name, arg, block) {
        var assigners, index_code, var_code, var_name, _ref2;
        if (name === 'EVAL') {
          var_name = arg;
          return function(val, rt, cb) {
            rt.scope().set(var_name, val, context);
            return cb();
          };
        } else if (name === 'INDEX') {
          var_code = Compile(block);
          index_code = Compile(block);
          return function(val, rt, cb) {
            return rt.call(var_code, function(my_var) {
              return rt.call(index_code, function(index) {
                my_var[index] = val;
                return cb();
              });
            });
          };
        } else if (name === 'ARR') {
          assigners = [];
          while (block.len() > 0) {
            _ref2 = GetBlock(block), name = _ref2[0], arg = _ref2[1], subblock = _ref2[2];
            assigners.push(build_assign(name, arg, subblock));
          }
          return function(val, rt, cb) {
            var f, i, last;
            i = 0;
            f = function(assigner, cb) {
              return assigner(val[i], rt, function() {
                i += 1;
                return cb(true);
              });
            };
            last = function() {
              return cb();
            };
            return iterate_callbacks(f, last, assigners);
          };
        }
      };
      assign = build_assign(name, subarg, subblock);
      return function(rt, cb) {
        return rt.call(value_code, function(val) {
          return assign(val, rt, function() {
            return cb(null);
          });
        });
      };
    },
    'CALL': function(arg, block) {
      var accessor, args, my_obj, my_var, name, subarg, subblock, _ref;
      _ref = GetBlock(block), name = _ref[0], subarg = _ref[1], subblock = _ref[2];
      if (name === 'ACCESS') {
        my_obj = Compile(subblock);
        accessor = Shift(subblock);
        args = Compile(block);
        return function(rt, cb) {
          return rt.call(my_obj, function(obj) {
            return rt.call(args, function(my_args) {
              var f;
              f = obj[accessor];
              if (f.__coffeecoffee__) {
                return f.call(obj, rt, cb, my_args);
              } else {
                return cb(f.call.apply(f, [obj].concat(__slice.call(my_args))));
              }
            });
          });
        };
      } else {
        my_var = Compiler[name](subarg, subblock);
        args = Compile(block);
        return function(rt, cb) {
          return rt.call(my_var, function(f) {
            return rt.call(args, function(my_args) {
              if (f.__coffeecoffee__) {
                return f(rt, cb, my_args);
              } else {
                return cb(f.apply(null, my_args));
              }
            });
          });
        };
      }
    },
    'CLASS': function(arg, block) {
      var class_name, code, methods, name, subarg, subblock, _ref;
      class_name = Shift(block);
      GetBlock(block);
      _ref = GetBlock(block), name = _ref[0], subarg = _ref[1], subblock = _ref[2];
      methods = [];
      while (subblock.len() > 0) {
        name = Shift(subblock);
        code = Compile(subblock);
        methods.push({
          name: name,
          code: code
        });
      }
      return function(rt, cb) {
        var f, last, proto;
        proto = {};
        f = function(method, cb) {
          return rt.call(method.code, function(f) {
            proto[method.name] = f;
            return cb(true);
          });
        };
        last = function() {
          var klass;
          klass = build_class(proto);
          rt.scope().set(class_name, klass);
          return cb(true);
        };
        return iterate_callbacks(f, last, methods);
      };
    },
    'CODE': function(arg, block) {
      var body, get_parms, ignore, name, param_block, params, params_block, subarg, _ref, _ref2;
      _ref = GetBlock(block), name = _ref[0], subarg = _ref[1], params_block = _ref[2];
      params = [];
      while (params_block.len() > 0) {
        _ref2 = GetBlock(params_block), ignore = _ref2[0], ignore = _ref2[1], param_block = _ref2[2];
        params.push(Shift(param_block));
      }
      get_parms = function(my_args) {
        var i, param, parms, _len;
        parms = {};
        for (i = 0, _len = params.length; i < _len; i++) {
          param = params[i];
          parms[param] = my_args[i];
        }
        return parms;
      };
      body = Compile(block);
      return function(rt, cb) {
        var f, lexical_outer_scope;
        lexical_outer_scope = rt.scope();
        f = function(rt, cb, my_args) {
          var sub_scope;
          sub_scope = Scope(get_parms(my_args), lexical_outer_scope, this, my_args);
          rt.push_scope(sub_scope);
          return rt.call(body, function(val) {
            rt.control_flow = null;
            rt.pop_scope();
            return cb(val);
          });
        };
        f.__coffeecoffee__ = true;
        return cb(f);
      };
    },
    'COND': function(arg, block) {
      var f;
      f = Compile(block);
      return function(rt, cb) {
        return rt.call(f, function(val) {
          return cb(val);
        });
      };
    },
    'DO': function(arg, block) {
      var stmts;
      stmts = [];
      while (block.len() > 0) {
        stmts.push(Compile(block));
      }
      return function(rt, cb) {
        var f, last, val;
        val = null;
        f = function(stmt, cb) {
          return rt.call(stmt, function(value) {
            val = value;
            if (rt.control_flow) {
              return cb(false);
            } else {
              return cb(true);
            }
          });
        };
        last = function() {
          return cb(val);
        };
        return iterate_callbacks(f, last, stmts);
      };
    },
    'EXISTENCE': function(arg, block) {
      var val_code;
      val_code = Compile(block);
      return function(rt, cb) {
        rt.scope().relax(true);
        return rt.call(val_code, function(val) {
          rt.scope().relax(false);
          return cb(val);
        });
      };
    },
    'EVAL': function(arg, block) {
      return function(rt, cb) {
        var val;
        val = rt.scope().get(arg);
        return cb(val);
      };
    },
    'FOR_IN': function(arg, block) {
      var block_code, f, range_code, step_var;
      step_var = Shift(block);
      range_code = Compile(block);
      block_code = Compile(block);
      return f = function(rt, cb) {
        return rt.call(range_code, function(range) {
          var last, values;
          values = [];
          f = function(range_val, cb) {
            rt.scope().set(step_var, range_val);
            return rt.call(block_code, function(val) {
              values.push(val);
              return cb(true);
            });
          };
          last = function() {
            return cb(values);
          };
          return iterate_callbacks(f, last, range);
        });
      };
    },
    'IF': function(arg, block) {
      var cond_code, else_code, if_code;
      cond_code = Compile(block);
      if_code = Compile(block);
      if (block.len() > 0) {
        else_code = Compile(block);
      } else {
        else_code = null;
      }
      return function(rt, cb) {
        return rt.call(cond_code, function(cond) {
          if (cond) {
            return rt.call(if_code, function(val) {
              return cb(val);
            });
          } else {
            if (else_code) {
              return rt.call(else_code, function(val) {
                return cb(val);
              });
            } else {
              return cb(null);
            }
          }
        });
      };
    },
    'INDEX': function(arg, block) {
      var index_code, value_code;
      value_code = Compile(block);
      index_code = Compile(block);
      return function(rt, cb) {
        return rt.call(value_code, function(val) {
          return rt.call(index_code, function(index) {
            return cb(val[index]);
          });
        });
      };
    },
    'KEY_VALUE': function(arg, block) {
      var name, value_code;
      name = Shift(block);
      value_code = Compile(block);
      return function(rt, obj, cb) {
        rt.call(value_code, function(val) {
          return obj[name] = val;
        });
        return cb(null);
      };
    },
    'NEW': function(arg, block) {
      var args, my_var;
      my_var = Compile(block);
      args = Compile(block);
      return function(rt, cb) {
        return rt.call(my_var, function(f) {
          return rt.call(args, function(my_args) {
            return newify(f, rt, cb, my_args);
          });
        });
      };
    },
    'NUMBER': function(arg, block) {
      var n;
      n = parseFloat(arg);
      return function(rt, cb) {
        return cb(n);
      };
    },
    'OBJ': function(arg, block) {
      var keys;
      keys = [];
      while (block.len() > 0) {
        keys.push(Compile(block));
      }
      return function(rt, cb) {
        var f, last, obj;
        obj = {};
        f = function(key, cb) {
          return rt.call_extra(key, obj, function(val) {
            return cb(true);
          });
        };
        last = function() {
          return cb(obj);
        };
        return iterate_callbacks(f, last, keys);
      };
    },
    'OP_BINARY': function(arg, block) {
      var f, op, operand1, operand2;
      op = arg;
      f = binary_ops[op];
      operand1 = Compile(block);
      operand2 = Compile(block);
      if (op === '&&') {
        return function(rt, cb) {
          return rt.call(operand1, function(op1) {
            if (op1) {
              return rt.call(operand2, function(op2) {
                return cb(op2);
              });
            } else {
              return cb(false);
            }
          });
        };
      } else {
        return function(rt, cb) {
          return rt.call(operand1, function(op1) {
            return rt.call(operand2, function(op2) {
              return cb(f(op1, op2));
            });
          });
        };
      }
    },
    'OP_UNARY': function(arg, block) {
      var f, op, operand1;
      op = arg;
      f = unary_ops[op];
      operand1 = Compile(block);
      return function(rt, cb) {
        return rt.call(operand1, function(op1) {
          return cb(f(op1));
        });
      };
    },
    'PARENS': function(arg, block) {
      return Compile(block);
    },
    'RANGE_INCLUSIVE': function(arg, block) {
      var high_code, low_code;
      low_code = Compile(block);
      high_code = Compile(block);
      return function(rt, cb) {
        return rt.call(low_code, function(low) {
          return rt.call(high_code, function(high) {
            var _i, _results;
            return cb((function() {
              _results = [];
              for (var _i = low; low <= high ? _i <= high : _i >= high; low <= high ? _i++ : _i--){ _results.push(_i); }
              return _results;
            }).apply(this));
          });
        });
      };
    },
    'RANGE_EXCLUSIVE': function(arg, block) {
      var high_code, low_code;
      low_code = Compile(block);
      high_code = Compile(block);
      return function(rt, cb) {
        return rt.call(low_code, function(low) {
          return rt.call(high_code, function(high) {
            var _i, _results;
            return cb((function() {
              _results = [];
              for (var _i = low; low <= high ? _i < high : _i > high; low <= high ? _i++ : _i--){ _results.push(_i); }
              return _results;
            }).apply(this));
          });
        });
      };
    },
    'RETURN': function(arg, block) {
      var value_code;
      value_code = Compile(block);
      return function(rt, cb) {
        return rt.call(value_code, function(val) {
          rt.control_flow = 'return';
          return cb(val);
        });
      };
    },
    'SLICE': function(arg, block) {
      var high_code, low_code, name, slice, subblock, value_code, _ref;
      value_code = Compile(block);
      _ref = GetBlock(block), name = _ref[0], arg = _ref[1], subblock = _ref[2];
      if (name === 'RANGE_EXCLUSIVE') {
        slice = function(x, low, high) {
          return x.slice(low, high);
        };
      } else {
        slice = function(x, low, high) {
          return x.slice(low, (high + 1) || 9e9);
        };
      }
      low_code = Compile(subblock);
      high_code = Compile(subblock);
      return function(rt, cb) {
        return rt.call(value_code, function(value) {
          return rt.call(low_code, function(low) {
            return rt.call(high_code, function(high) {
              return cb(slice(value, low, high));
            });
          });
        });
      };
    },
    'STRING': function(arg, block) {
      var s, value;
      value = arg;
      if (value.charAt(0) === '"') {
        s = JSON.parse(value);
      }
      if (value.charAt(0) === "'") {
        s = JSON.parse('"' + value.substring(1, value.length - 1) + '"');
      }
      return function(rt, cb) {
        return cb(s);
      };
    },
    'VALUE': function(arg, block) {
      var map, val;
      map = {
        "true": true,
        "false": false,
        "null": null,
        undefined: void 0
      };
      val = map[arg];
      return function(rt, cb) {
        return cb(val);
      };
    },
    'WHILE': function(arg, block) {
      var block_code, cond_code, f;
      cond_code = Compile(block);
      block_code = Compile(block);
      return f = function(rt, cb) {
        return rt.call(cond_code, function(cond) {
          if (cond) {
            return rt.call(block_code, function(val) {
              if (rt.control_flow === 'return') {
                return cb(val);
              } else {
                return f(rt, cb);
              }
            });
          } else {
            return cb(null);
          }
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
    var arg, args, line, name, obj, prefix, _ref;
    _ref = indenter.small_block(block), prefix = _ref[0], line = _ref[1], block = _ref[2];
    if (line.length === 0) {
      return null;
    }
    args = line.split(' ');
    name = args[0];
    arg = args.slice(1, args.length).join(' ');
    if (Compiler[name]) {
      return obj = Compiler[name](arg, block);
    } else {
      return console.log("unknown compile target: " + name);
    }
  };
  Shift = function(block) {
    return block.shift()[1];
  };
  RunTime = function() {
    var scopes, self;
    scopes = [Scope()];
    return self = {
      call_extra: function(code, extra, cb) {
        return code(self, extra, function(val) {
          var f;
          f = function() {
            return cb(val);
          };
          return setTimeout(f, 0);
        });
      },
      scope: function() {
        return scopes[0];
      },
      push_scope: function(scope) {
        return scopes.unshift(scope);
      },
      pop_scope: function() {
        return scopes.shift();
      },
      call: function(code, cb) {
        return code(self, function(val) {
          var f;
          f = function() {
            return cb(val);
          };
          return setTimeout(f, 0);
        });
      },
      step: function(f) {
        return setTimeout(f, 200);
      }
    };
  };
  parser = function(indented_lines) {
    var code, f, last, runtime, stmts;
    runtime = RunTime();
    stmts = [];
    while (indented_lines.len() > 0) {
      code = Compile(indented_lines);
      if (code) {
        stmts.push(code);
      }
    }
    f = function(stmt, cb) {
      return runtime.call(stmt, function(val) {
        return runtime.step(function() {
          return cb(true);
        });
      });
    };
    last = function() {
      return console.log("EXITING PROGRAM!");
    };
    return iterate_callbacks(f, last, stmts);
  };
  handle_data = function(s) {
    var prefix_line_array;
    prefix_line_array = indenter.big_block(s);
    return parser(prefix_line_array);
  };
  iterate_callbacks = function(f, last, arr) {
    var next;
    next = function(i) {
      if (i < arr.length) {
        return f(arr[i], function(ok) {
          if (ok) {
            return next(i + 1);
          } else {
            return last();
          }
        });
      } else {
        return last();
      }
    };
    return next(0);
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
    var forgiving, key, self, set_local_value, value, vars;
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
    forgiving = false;
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
      relax: function(latitude) {
        return forgiving = latitude;
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
        if (!(val != null) && !forgiving) {
          console.log(var_name, vars);
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
      var cb;
      this.__super__ = X.__super__;
      if (Object.prototype.hasOwnProperty.call(proto, "constructor")) {
        return proto.constructor.apply(this, arguments);
      } else if (superclass) {
        return X.__super__.constructor.apply(this, arguments);
      } else {
        cb = arguments[1];
        return cb(void 0);
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
  newify = function(func, rt, cb, args) {
    var callback, child, ctor;
    ctor = function() {};
    ctor.prototype = func.prototype;
    child = new ctor;
    callback = function(result) {
      if (typeof result === "object") {
        return cb(result);
      } else {
        return cb(child);
      }
    };
    return func.call(child, rt, callback, args);
  };
  if (typeof window !== "undefined" && window !== null) {} else {
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
