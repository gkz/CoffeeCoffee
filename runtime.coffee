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

# Scope is just wraps a hash for now.  It's mostly used by Assign.  Its 
# scoping is still very primitive, e.g. it doesn't have full closures.
Scope = (params, parent_scope) ->
  vars = {}
  for key of params
    vars[key] = {obj: params[key]}
  self =
    set: (var_name, value, context) ->
      if context == "+="
        vars[var_name].obj += value
      else
        vars[var_name] = {obj: value}
    get: (var_name) ->
      val = vars[var_name]
      return val.obj if val?
      # parent scope
      if parent_scope
        val = parent_scope.get var_name
        return val if val?
      # builtins
      val = root[var_name]
      return val if val?
      throw "Var not found #{var_name}"
    vars: vars

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
    lhs = ast.variable.base.value
    rhs = Eval scope, ast.value
    scope.set lhs, rhs, ast.context

  Block: (scope, ast) ->
    code = ast.expressions
    for stmt in code
      if stmt[0] == "Return"
        retval = Eval scope, stmt[1].expression
        throw retval: retval
      val = Eval scope, stmt
    val
    
  # This is fairly clumsy now and only handles
  # foo.bar.baz(yo1, yo2); it does not handle
  # foo[bar].baz(yo), for example.
  Call: (scope, ast) ->
    variable = ast.variable
    root = variable.base.value
    properties = variable.properties
    method = scope.get root
    for accessor in properties
      root = method
      method = method[accessor.name.value]
    args = ast.args.map (arg) ->
        Eval scope, arg
    method.apply root, args
    
  Code: (scope, ast) ->
    return (args...) ->
      parms = {}
      for param in ast.params
        parms[param.name.value] = args.shift()
      sub_scope = Scope(parms, scope)
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
      if value.charAt(0) == '"'
        return JSON.parse value
      if value.charAt(0) == "'"
        return value.substring(1, value.length-1)
      if value.match(/\d+/) != null
        return parseFloat(value)
      return scope.get(value)

  Op: (scope, ast) ->
    op = ast.operator
    if ast.second
      operand1 = Eval scope, ast.first
      operand2 = Eval scope, ast.second
      ops = {
        '*':   -> operand1 * operand2
        '/':   -> operand1 / operand2
        '+':   -> operand1 + operand2
        '-':   -> operand1 - operand2
        '===': -> operand1 is operand2
        '>>':  -> operand1 >> operand2
        '&&':  -> operand1 && operand2
        '||':  -> operand1 || operand2
        '<':   -> operand1 < operand2
        '>':   -> operand1 > operand2
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
    return [from_val..to_val]

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
