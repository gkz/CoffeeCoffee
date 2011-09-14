# IMPORTANT: This is very much a work in progress, but it does run
# simple programs like test/binary_search.coffee.

# This is an experiment in having CS interpret itself. One use case would
# be educational environments, where students are learning CS and need
# to be able to pause/resume applications, etc.


# Example usage:
#  coffee -n hello_world.coffee | coffee nodes_to_json.coffee | coffee runtime.coffee
#

util = require 'util'

pp = (obj, description) ->
  util.debug "-----"
  util.debug description if description?
  util.debug JSON.stringify obj, null, "  "

# Frame is just wraps a hash for now.  It's mostly used by Assign.  Its 
# scoping is still very primitive, e.g. it doesn't have full closures.
Frame = (params, parent_frame) ->
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
      # parent frame
      if parent_frame
        val = parent_frame.get var_name
        return val if val?
      # builtins
      val = root[var_name]
      return val if val?
      throw "Var not found #{var_name}"
    vars: vars

  
Access = (frame, obj, properties) ->
  for accessor in properties
    key = Eval frame, accessor
    return obj[key]
  obj

Eval = (frame, ast) ->
  # pp ast, "Eval"
  # pp frame, "Frame"
  name = ast[0]
  method = Runtime[name]
  if method
    return method frame, ast[1]  
  if ast.base
    return Access frame, Eval(frame, ast.base), ast.properties

  pp ast, "unknown"
  pp ast[0], "ast[0]"
  console.log "*******"
  throw "cannot parse Value"

Op = (frame, ast) ->
  op = ast.operator
  if ast.second
    operand1 = Eval frame, ast.first
    operand2 = Eval frame, ast.second
    if op == '*'
      return operand1 * operand2
    if op == '/'
      return operand1 / operand2
    if op == '+'
      return operand1 + operand2
    if op == '-'
      return operand1 - operand2
    if op == '==='
      return operand1 is operand2
    if op == '>>'
      return operand1 >> operand2
    if op == '&&'
      return operand1 && operand2
    if op == '||'
      return operand1 || operand2
    if op == '<'
      return operand1 < operand2
    if op == '>'
      return operand1 > operand2
  else
    operand1 = Eval frame, ast.first
    if op == "-"
      return -1 * operand1
    if op == '!'
      return !operand1
  throw "unknown op #{op}"
  

statements = (frame, code) ->
  for stmt in code
    if stmt[0] == "Return"
      retval = Eval frame, stmt[1].expression
      throw retval: retval
    val = Eval frame, stmt
  val
    
Args = (frame, args) ->
  args.map (arg) ->
    Eval frame, arg

Function = (frame, ast, args...) ->
  parms = {}
  for param in ast.params
    parms[param.name.value] = args.shift()
  frame = Frame(parms, frame)
  Block frame, ast.body
  
Block = (frame, body) ->
  try
    return statements frame, body.expressions
  catch e
    if e.retval?
      return e.retval
    throw e

# This should be really just be part of Eval.
Runtime =
  Assign: (frame, ast) ->
    lhs = ast.variable.base.value
    rhs = Eval frame, ast.value
    frame.set lhs, rhs, ast.context

  # This is fairly clumsy now and only handles
  # foo.bar.baz(yo1, yo2); it does not handle
  # foo[bar].baz(yo), for example.
  Call: (frame, ast) ->
    variable = ast.variable
    root = variable.base.value
    properties = variable.properties
    method = frame.get root
    for accessor in properties
      root = method
      method = method[accessor.name.value]
    args = Args frame, ast.args
    # pp args, "CALL"
    method.apply root, args
    
  While: (frame, ast) ->
    while Eval frame, ast.condition
      statements frame, ast.body.expressions
      
  If: (frame, ast) ->
    if Eval frame, ast.condition
      statements frame, ast.body.expressions
    else if ast.elseBody
      statements frame, ast.elseBody.expressions
      
  For: (frame, ast) ->
    range = Eval frame, ast.source
    step_var = ast.name.value
    for step_val in range
      frame.set step_var, step_val
      statements frame, ast.body.expressions
      
  Access: (frame, ast) ->
    return ast.name.value

  Parens: (frame, ast) ->
    body = ast.body
    if body.expressions
      return Eval frame, body.expressions[0]
    else
      return Eval frame, body

  Op: (frame, ast) ->
    return Op frame, ast

  Code: (frame, ast) ->
    return (args...) -> Function frame, ast, args...

  Value: (frame, ast) ->
    return Eval frame, ast

  Index: (frame, ast) ->
    return Eval frame, ast.index

  Arr: (frame, ast) ->
    objects = ast.objects
    return objects.map (obj) -> Eval frame, obj

  Range: (frame, ast) ->
    from_val = Eval frame, ast.from
    to_val = Eval frame, ast.to
    return [from_val..to_val]

  Literal: (frame, ast) ->
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
      return frame.get(value)

handle_data = (data) ->
  program = JSON.parse data
  frame = Frame()
  for stmt in program
    Eval frame, stmt

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
