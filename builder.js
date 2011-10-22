(function() {
  var AST, Build, DEDENT, INDENT, PUT, TAB, data, fn, fs, handle_data, pp, stdin, the_key_of, transcompile;
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
    console.log(ast);
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
      var context;
      context = ast.context || '=';
      PUT("ASSIGN " + context, function() {
        Build(ast.variable);
        return Build(ast.value);
      });
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
      var stmt;
      if (ast.isSuper) {
        return PUT("SUPER", function() {
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
      } else {
        stmt = ast.isNew ? "NEW" : "CALL";
        return PUT(stmt, function() {
          Build(ast.variable);
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
      }
    },
    Class: function(ast) {
      var class_name;
      class_name = ast.variable.Value.base.Literal.value;
      PUT("CLASS", function() {
        var expression, expressions, method, methods, _i, _j, _len, _len2, _ref;
        PUT(class_name);
        PUT("PARENTS", function() {
          if (ast.parent) {
            return Build(ast.parent);
          }
        });
        methods = [];
        expressions = ast.body.Block.expressions;
        for (_i = 0, _len = expressions.length; _i < _len; _i++) {
          expression = expressions[_i];
          if (expression.Value) {
            _ref = expression.Value.base.Obj.properties;
            for (_j = 0, _len2 = _ref.length; _j < _len2; _j++) {
              method = _ref[_j];
              methods.push(method);
            }
          }
        }
        return PUT("METHODS", function() {
          var method, _k, _len3, _results;
          _results = [];
          for (_k = 0, _len3 = methods.length; _k < _len3; _k++) {
            method = methods[_k];
            PUT(method.Assign.variable.Value.base.Literal.value);
            _results.push(Build(method.Assign.value));
          }
          return _results;
        });
      });
    },
    Code: function(ast) {
      var name;
      name = ast.bound ? 'BOUND_CODE' : 'CODE';
      return PUT(name, function() {
        PUT('PARAMS', function() {
          var param, _i, _len, _ref, _results;
          _ref = ast.params;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            param = _ref[_i];
            param = param.Param;
            if (param.name.Literal) {
              name = param.name.Literal.value;
            } else {
              name = "@" + param.name.Value.properties[0].Access.name.Literal.value;
            }
            if (param.splat) {
              name += "...";
            }
            _results.push(PUT("PARAM", function() {
              PUT(name);
              if (param.value) {
                return Build(param.value);
              }
            }));
          }
          return _results;
        });
        return PUT("DO", function() {
          return Build(ast.body);
        });
      });
    },
    Existence: function(ast) {
      return PUT("EXISTENCE", function() {
        return Build(ast.expression);
      });
    },
    For: function(ast) {
      if (ast.index) {
        return PUT("FOR_OF", function() {
          PUT("VARS", function() {
            PUT(ast.index.Literal.value);
            if (ast.name) {
              return PUT(ast.name.Literal.value);
            }
          });
          Build(ast.source);
          return PUT("DO", function() {
            return Build(ast.body);
          });
        });
      } else {
        return PUT("FOR_IN", function() {
          PUT(ast.name.Literal.value);
          Build(ast.source);
          return PUT("DO", function() {
            return Build(ast.body);
          });
        });
      }
    },
    If: function(ast) {
      PUT("IF", function() {
        PUT("COND", function() {
          return Build(ast.condition);
        });
        PUT("DO", function() {
          return Build(ast.body);
        });
        if (ast.elseBody) {
          return PUT("DO", function() {
            return Build(ast.elseBody);
          });
        }
      });
    },
    In: function(ast) {
      var name;
      name = ast.negated ? "NOT_IN" : "IN";
      return PUT(name, function() {
        Build(ast.object);
        return Build(ast.array);
      });
    },
    Literal: function(ast) {
      var literal, value;
      value = ast.value;
      literal = function() {
        var c, float;
        if (value === 'false' || value === 'true' || value === 'undefined' || value === 'undefined') {
          return PUT("VALUE " + value);
        }
        if (value === 'break') {
          return PUT("BREAK");
        }
        if (value === 'continue') {
          return PUT("CONTINUE");
        }
        c = value.charAt(0);
        if (c === "'" || c === '"') {
          return PUT("STRING " + value);
        }
        if (value.match(/\d+/) !== null) {
          float = parseFloat(value);
          return PUT("NUMBER " + float);
        }
        if (value.charAt(0) === '/') {
          return PUT("REGEX " + value);
        }
        return PUT("EVAL " + value);
      };
      return literal();
    },
    Obj: function(ast) {
      return PUT("OBJ", function() {
        var name, property, _i, _len, _ref, _results;
        _ref = ast.properties;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          property = _ref[_i];
          _results.push(property.Assign ? (name = property.Assign.variable.Value.base.Literal.value, PUT("KEY_VALUE", function() {
            PUT(name);
            return Build(property.Assign.value);
          })) : PUT("KEY", function() {
            return Build(property);
          }));
        }
        return _results;
      });
    },
    Op: function(ast) {
      var class_name, is_chainable, op;
      is_chainable = function(op) {
        return op === '<' || op === '>' || op === '>=' || op === '<=' || op === '===' || op === '!==';
      };
      op = ast.operator;
      if (op === '++') {
        if (ast.flip) {
          PUT("INCR_POST", function() {
            return Build(ast.first);
          });
        } else {
          PUT("INCR_PRE", function() {
            return Build(ast.first);
          });
        }
        return;
      }
      if (op === '--') {
        if (ast.flip) {
          PUT("DECR_POST", function() {
            return Build(ast.first);
          });
        } else {
          PUT("DECR_PRE", function() {
            return Build(ast.first);
          });
        }
        return;
      }
      if (op === 'new') {
        class_name = ast.first.Value.base.Literal.value;
        PUT("NEW_BARE", function() {
          return PUT(class_name);
        });
        return;
      }
      if (ast.second) {
        if (is_chainable(op) && the_key_of(ast.first) === "Op" && is_chainable(ast.first.Op.operator)) {
          PUT("OP_BINARY &&", function() {
            Build(ast.first);
            return PUT("OP_BINARY " + op, function() {
              Build(ast.first.Op.second);
              return Build(ast.second);
            });
          });
          return;
        }
        PUT("OP_BINARY " + op, function() {
          Build(ast.first);
          return Build(ast.second);
        });
        return;
      } else {
        PUT("OP_UNARY " + op, function() {
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
        return PUT("PARENS", function() {
          return Build(body.expressions[0]);
        });
      } else {
        return Build(body);
      }
    },
    Range: function(ast) {
      var stmt;
      if (ast.exclusive) {
        stmt = "RANGE_EXCLUSIVE";
      } else {
        stmt = "RANGE_INCLUSIVE";
      }
      return PUT(stmt, function() {
        if (ast.from) {
          Build(ast.from);
        } else {
          PUT("LITERAL 0");
        }
        if (ast.to) {
          return Build(ast.to);
        }
      });
    },
    Return: function(ast) {
      return PUT("RETURN", function() {
        return Build(ast.expression);
      });
    },
    Splat: function(ast) {
      return PUT("SPLAT", function() {
        return Build(ast.name);
      });
    },
    Switch: function(ast) {
      return PUT("SWITCH", function() {
        var case_ast, _i, _len, _ref;
        Build(ast.subject);
        _ref = ast.cases;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          case_ast = _ref[_i];
          PUT("CASE", function() {
            Build(case_ast.cond);
            return Build(case_ast.block);
          });
        }
        if (ast.otherwise) {
          return PUT("OTHERWISE", function() {
            return Build(ast.otherwise);
          });
        }
      });
    },
    Throw: function(ast) {
      return PUT("THROW", function() {
        return Build(ast.expression);
      });
    },
    Try: function(ast) {
      return PUT("TRY", function() {
        PUT("DO", function() {
          return Build(ast.attempt);
        });
        PUT("CATCH", function() {
          var catch_var;
          catch_var = ast.error.Literal.value;
          PUT(catch_var);
          return Build(ast.recovery);
        });
        if (ast.ensure) {
          return PUT("FINALLY", function() {
            return Build(ast.ensure);
          });
        }
      });
    },
    Value: function(ast) {
      var last_property, name, prior, priors, properties;
      if (ast.properties.length === 0) {
        return Build(ast.base);
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
          name = last_property.Access.soak ? "ACCESS_SOAK" : "ACCESS";
          PUT(name, function() {
            if (last_property.Access.proto) {
              PUT("PROTO", function() {
                return prior();
              });
            } else {
              prior();
            }
            return PUT(last_property.Access.name.Literal.value);
          });
        } else if (last_property.Index != null) {
          PUT("INDEX", function() {
            prior();
            return Build(last_property.Index.index);
          });
        } else if (last_property.Slice != null) {
          PUT("SLICE", function() {
            prior();
            return Build(last_property.Slice.range);
          });
        } else {
          throw "yo";
        }
      }
    },
    While: function(ast) {
      return PUT("WHILE", function() {
        PUT("COND", function() {
          return Build(ast.condition);
        });
        return PUT("DO", function() {
          return Build(ast.body);
        });
      });
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
