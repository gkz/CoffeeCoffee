# IMPORTANT: This is very much a work in progress, but it does run
# simple programs like test/binary_search.coffee.

# This is an experiment in having CS interpret itself. One use case would
# be educational environments, where students are learning CS and need
# to be able to pause/resume applications, etc.

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
    vars[key] = params[key]
  self =
    set: (var_name, value, context) ->
      if context == "+="
        vars[var_name] += value
      else
        vars[var_name] = value
    get: (var_name) ->
      val = vars[var_name]
      return val if val?
      # parent frame
      if parent_frame
        val = parent_frame.get var_name
        return val if val?
      # builtins
      val = root[var_name]
      return val if val?
      throw "Var not found #{var_name}"
    vars: vars

Deref = (frame, variable) ->
  root = variable.base.value
  properties = variable.properties
  result = frame.get root
  for accessor in properties
    result = result[accessor.name.value]
  result
  
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
  if ast[0] == 'Access'
    return ast[1].name.value
  if ast[0] == 'Parens'
    return Eval frame, ast[1].body.expressions[0]
  if ast[0] == 'Op'
    return Op frame, ast[1]
  if ast[0] == "Call"
    return Runtime.Call frame, ast[1]
  if ast[0] == 'Code'
    return (args...) -> Function frame, ast[1], args...
  if ast[0] == 'Value'
    return Eval frame, ast[1]
  if ast[0] == 'Index'
    return Eval frame, ast[1].index
  if ast[0] == "Arr"
    objects = ast[1].objects
    return objects.map (obj) -> Eval frame, obj
  if ast[0] == "Range"
    from_val = Eval frame, ast[1].from
    to_val = Eval frame, ast[1].to
    return [from_val..to_val]
  if ast[0] == "Literal"
    ast = ast[1]
    value = ast.value[1]
    if value
      return false if value == 'false'
      return true if value == 'true'
      if value.charAt(0) == '"'
        return JSON.parse value
      if value.charAt(0) == "'"
        return value.substring(1, value.length-2)
      if value.match(/\d+/) != null
        return parseFloat(value)
      return frame.get(value)
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

  Call: (frame, ast) ->
    # pp ast, "Call"
    method = Deref frame, ast.variable
    args = Args frame, ast.args
    # pp args, "CALL"
    method args...
    
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

handle_data = (data) ->
  program = JSON.parse data
  frame = Frame()
  for stmt in program
    Eval frame, stmt


# Example usage:
#  coffee -n hello_world.coffee | coffee nodes_to_json.coffee | coffee runtime.coffee
#
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
