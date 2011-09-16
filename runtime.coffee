# This is an experiment in having CS interpret itself. One use case would
# be educational environments, where students are learning CS and need
# to be able to pause/resume applications, etc.

# Example usage:
#  coffee nodes_to_json.coffee test/binary_search.coffee | coffee runtime.coffee
#

# IMPORTANT: This is very much a work in progress, but it does run
# simple programs like test/binary_search.coffee.

# BIG OVERVIEW: The AST comes in as a JSON tree.  We recursively apply Eval to the nodes,
# using Scope to manage our variables.
handle_data = (data) ->
  program = JSON.parse data
  scope = Scope()
  for stmt in program
    Eval scope, stmt

# Scope: returns an object to manage variable assignment
#
# Scope essentially just wraps a hash for now.  It's mostly used by Assign.  Its 
# scoping is still very primitive, e.g. it doesn't have full closures.  It uses
# its parent scope for lookups, but it's basically read-only.
Scope = (params, parent_scope, this_value) ->
  vars = {}

  set_local_value = (key, value) ->
    # Vars are wrapped inside a hash, as a cheap trick to avoid ambiguity
    # w/r/t undefined values.  This prevents us from trying to go to the parent
    # scope when the variable has been assigned in our own scope.
    vars[key] = {obj: value}

  for key, value of params
    set_local_value(key, value)
  set_local_value("this", this_value)

  self =
    # try to find the wrapped variable at the correct closure scope...still a work
    # in progress
    get_closure_wrapper: (var_name) ->
      val = vars[var_name]
      return val if val?
      return parent_scope.get_closure_wrapper var_name if parent_scope
      return
      
    set: (var_name, value, context) ->
      context ||= "=" # default, could also be +=, etc.
      
      closure_wrapper = self.get_closure_wrapper var_name
      
      if closure_wrapper
        # we have a previous reference
        update_variable_reference(closure_wrapper, "obj", value, context)
      else if context == "="
        # first reference to local variable
        return set_local_value(var_name, value)
      else
        # cannot find var, so += and friends won't work
        throw "Var #{var_name} has not been set"
      

    get: (var_name) ->
      if var_name == 'require'
        return (args...) -> require args...
        
      closure_wrapper = self.get_closure_wrapper(var_name)
      if closure_wrapper
        return closure_wrapper.obj
        
      # builtins
      val = root[var_name]
      return val if val?
      throw "Var not found #{var_name}"

update_variable_reference = (hash, key, value, context) ->
  context ||= '='
  commands = {
    '=':   -> hash[key] = value
    '+=':  -> hash[key] += value
    '*=':  -> hash[key] *= value
    '||=': -> hash[key] ||= value
  }
  throw "unknown context #{context}" unless commands[context]
  commands[context]()

Eval = (scope, ast) ->
  name = ast[0]
  method = AST[name]
  if method
    return method scope, ast[1]  
  throw "#{name} not supported yet"
  
AST =
  Access: (scope, ast) ->
    return ast.name.value

  Arr: (scope, ast) ->
    objects = ast.objects
    return objects.map (obj) -> Eval scope, obj

  Assign: (scope, ast) ->
    context = ast.context
    
    set = (scope, ast, value) ->
      name = ast[0]
      method = LHS[name]
      if method
        return method scope, ast[1], value
      throw "#{name} not supported yet on LHS"

    # There is a bit of similarity within LHS vs. AST for handling
    # the left-hand-side of assignments, but the semantic differences
    # can get kind of subtle, so avoiding coupling is higher priority
    # than avoiding duplication.
    LHS = 
      Arr: (scope, ast, value) ->
        for object, i in ast.objects
          set scope, object, value[i]
        
      Value: (scope, ast, value) ->
        if ast.properties.length == 0
          if ast.base[0] == "Arr"
            set scope, ast.base, value
          else
            lhs = ast.base[1].value[1]  
            scope.set lhs, value, context
        else
          lhs = Eval scope, ast.base
          properties = ast.properties
          for accessor in properties.slice(0, properties.length - 1)
            key = Eval scope, accessor
            lhs = lhs[key]
          final_accessor = Eval scope, properties[properties.length - 1]
          update_variable_reference lhs, final_accessor, value, context

    rhs = Eval scope, ast.value
    set scope, ast.variable, rhs

  Block: (scope, ast) ->
    code = ast.expressions
    for stmt in code
      val = Eval scope, stmt
    val
    
  # This is fairly clumsy now and only handles
  # foo.bar.baz(yo1, yo2); it may not handle
  # foo[bar].baz(yo), for example.
  Call: (scope, ast) ->
    variable = ast.variable[1]
    obj = Eval scope, variable.base
    properties = variable.properties
    method = obj
    for accessor in properties
      obj = method
      key = Eval scope, accessor
      method = method[key]
    args = ast.args.map (arg) ->
        Eval scope, arg
    method.apply obj, args
  
  Class: (scope, ast) ->
    # traverse variable, Value, base, Literal, value, 1
    class_name = ast.variable[1].base[1].value[1]
    factory = (args...) ->
      # traverse, body, Block
      expressions = ast.body[1].expressions
      if expressions.length == 1
        ctor_ast = null
        block_ast = expressions[0]
      else
        [ctor_ast, block_ast] = expressions
      obj = Eval scope, block_ast
      if ctor_ast
        ctor = Eval scope, ctor_ast
        ctor.apply obj, args
      obj
    scope.set class_name, factory
    
  Code: (scope, ast) ->
    return (args...) ->
      parms = {}
      for param in ast.params
        parms[param.name.value] = args.shift()
      sub_scope = Scope(parms, scope, this)
      try
        return Eval sub_scope, ast.body
      catch e
        if e.retval?
          return e.retval
        throw e

  For: (scope, ast) ->
    range = Eval scope, ast.source
    step_var = ast.name.value
    for step_val in range
      scope.set step_var, step_val
      Eval scope, ast.body
      
  If: (scope, ast) ->
    if Eval scope, ast.condition
      Eval scope, ast.body
    else if ast.elseBody
      Eval scope, ast.elseBody
      
  Index: (scope, ast) ->
    return Eval scope, ast.index

  Literal: (scope, ast) ->
    value = ast.value[1]
    if value
      return false if value == 'false'
      return true if value == 'true'
      return null if value == 'null'
      if value.charAt(0) == '"'
        return JSON.parse value
      if value.charAt(0) == "'"
        return value.substring(1, value.length-1)
      if value.match(/\d+/) != null
        return parseFloat(value)
      return scope.get(value)

  Obj: (scope, ast) ->
    obj = {}
    for property in ast.properties
      throw "unexpected" if property[0] != 'Assign'
      ast = property[1]

      LHS = 
        set: (ast, value) ->
          name = ast[0]
          method = LHS[name]
          if method
            return method ast[1], value
          throw "#{name} not supported yet on Obj LHS"

        Literal: (ast, value) ->
          lhs = ast.value[1]
          obj[lhs] = value

        Value: (ast, value) ->    
          LHS.set ast.base, value
          
      value = Eval scope, ast.value
      LHS.set ast.variable, value
    obj

  Op: (scope, ast) ->
    op = ast.operator
    
    if op == '&&'
      return Eval(scope, ast.first) && Eval(scope, ast.second)
      
    if ast.second
      operand1 = Eval scope, ast.first
      operand2 = Eval scope, ast.second
      ops = {
        '*':   -> operand1 * operand2
        '/':   -> operand1 / operand2
        '+':   -> operand1 + operand2
        '-':   -> operand1 - operand2
        '===': -> operand1 is operand2
        '!==': -> operand1 isnt operand2
        '>>':  -> operand1 >> operand2
        '||':  -> operand1 || operand2
        '<':   -> operand1 < operand2
        '>':   -> operand1 > operand2
        '%':   -> operand1 % operand2
      }
      if ops[op]
        return ops[op]()
    else
      operand1 = Eval scope, ast.first
      if op == "-"
        return -1 * operand1
      if op == '!'
        return !operand1
    throw "unknown op #{op}"

  Parens: (scope, ast) ->
    body = ast.body
    if body[0] == 'Block'
      body = body[1]
    if body.expressions
      return Eval scope, body.expressions[0]
    else
      return Eval scope, body

  Range: (scope, ast) ->
    from_val = Eval scope, ast.from
    to_val = Eval scope, ast.to
    if ast.exclusive
      [from_val...to_val]
    else
      [from_val..to_val]

  Return: (scope, ast) ->
    retval = Eval scope, ast.expression
    throw retval: retval

  Value: (scope, ast) ->
    obj = Eval scope, ast.base
    for accessor in ast.properties
      key = Eval scope, accessor
      obj = obj[key]
    return obj

  While: (scope, ast) ->
    while Eval scope, ast.condition
      Eval scope, ast.body
      
util = require 'util'

pp = (obj, description) ->
  util.debug "-----"
  util.debug description if description?
  util.debug JSON.stringify obj, null, "  "

fs = require 'fs'
fn = process.argv[2]
if fn
  data = fs.readFileSync(fn).toString()
  handle_data(data)
else
  data = ''
  stdin = process.openStdin()
  stdin.on 'data', (buffer) ->
    data += buffer.toString() if buffer
  stdin.on 'end', ->
    handle_data(data)
