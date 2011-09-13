# IMPORTANT: This is temporarily broken, as I've modified the incoming format of the AST.


# This is an experiment in having CS interpret itself. One use case would
# be educational environments, where students are learning CS and need
# to be able to pause/resume applications, etc.

Statement = (frame, ast) ->
  name = ast[0]
  method = Runtime[name]
  if method
    method frame, ast[1]
  else
    console.log "Statement not supported:", name

pp = (obj, description) ->
  console.log "-----"
  console.log description if description?
  console.log JSON.stringify obj, null, "  "

# Frame is just wraps a hash for now.  It's mostly used by Assign.  No notion
# of closures yet.
Frame = (params) ->
  # for now, all frames get the "builtins" hacked in, which is kind of ugly
  vars =
    console: 
      log: console.log
  for key of params
    vars[key] = params[key]
  self =
    set: (var_name, value, context) ->
      if context == "+="
        vars[var_name] += value
      else
        vars[var_name] = value
    get: (var_name) ->
      vars[var_name]
    vars: vars

Deref = (frame, variable) ->
  root = variable.base.value
  properties = variable.properties
  result = frame.get root
  for accessor in properties
    result = result[accessor.name.value]
  result

Eval = (frame, ast) ->
  if ast.body
      return (args...) -> Function frame, ast, args...
  if ast.operator
      return Op frame, ast
  if ast.base?.value
    value = ast.base.value
    if value.charAt(0) == '"'
      return JSON.parse value
    else if value.match(/\d+/) != null
      return parseInt(value)
    else
      return frame.get value

Op = (frame, ast) ->
  op = ast.operator
  if op == '-'
    operand1 = Eval frame, ast.first
    if op == '-'
      return -1 * operand1
    else
      throw "unknown op #{op}"
  else
    operand1 = Eval frame, ast.first
    operand2 = Eval frame, ast.second
    if op == '*'
      return operand1 * operand2
    if op == '+'
      return operand1 + operand2
    if op == '==='
      return operand1 is operand2
    if op == '>>'
      return operand1 >> operand2
    if op == '<'
      return operand1 < operand2
    throw "unknown op #{op}"

statements = (frame, code) ->
  for stmt in code
    # if stmt.parent == "Return"
    #   retval = Eval frame, stmt.children[0]
    #   throw retval: retval
    Statement frame, stmt
    
Args = (frame, args) ->
  args.map (arg) ->
    Eval frame, arg

Function = (frame, ast, args...) ->
  parms = {}
  for param in ast.params
    parms[param.name.value] = args.shift()
  frame = Frame(parms)
  try
    return statements frame, ast.body.expressions
  catch e
    if e.retval?
      return e.retval
    throw e

Runtime =
  Assign: (frame, ast) ->
    lhs = ast.variable.base.value
    rhs = Eval frame, ast.value
    frame.set lhs, rhs, ast.context

  Call: (frame, ast) ->
    method = Deref frame, ast.variable
    args = Args frame, ast.args
    method args...

handle_data = (data) ->
  program = JSON.parse data
  frame = Frame()
  for stmt in program
    Statement frame, stmt


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
