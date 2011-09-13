# IMPORTANT: This is temporarily broken, as I've modified the incoming format of the AST.


# This is an experiment in having CS interpret itself. One use case would
# be educational environments, where students are learning CS and need
# to be able to pause/resume applications, etc.

Statement = (ast, frame) ->
  name = ast[0]
  method = Runtime[name]
  if method
    method ast[1], frame
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

Function = (frame, ast, params) ->
  param_values = {}
  for child_ast in ast
    if child_ast.kind == "Param"
      param_values[child_ast.value] = Eval frame, params.shift()
    else if child_ast.parent == "Block"
      return Runtime.Block child_ast.children, frame, param_values

Eval = (frame, ast) ->
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
  else
    if Runtime[ast.parent]
      return Runtime[ast.parent] ast.children, frame
    if ast.parent == 'Code'
      return (frame, params) -> Function frame, ast.children, params
    if ast.parent == "Arr"
      arr = []
      for child in ast.children
        arr.push Eval frame, child
      return arr
    if ast.parent ==  "Value"
      return Eval frame, ast.children[0] # strange
    if ast.parent ==  "Parens"
      return Eval frame, ast.children[0].children[0] # strange
    if ast.parent.kind == "Op"
      return Op frame, ast.parent.value, ast.children
    return Deref frame, ast


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
    if stmt.parent == "Return"
      retval = Eval frame, stmt.children[0]
      throw retval: retval
    Statement stmt, frame

Args = (frame, args) ->
  args.map (arg) ->
    Eval frame, arg


Runtime =
  Block: (ast, frame, param_values = {}) ->
    frame = Frame param_values
    try
      return statements frame, ast
    catch e
      if e.retval?
        return e.retval
      throw e

  Assign: (ast, frame) ->
    lhs = ast.variable.base.value
    rhs = Eval frame, ast.value
    frame.set lhs, rhs, ast.context

  Call: (ast, frame) ->
    method = Deref frame, ast.variable
    args = Args frame, ast.args
    method args...
    
  While: (ast, frame) ->
    expr = ast[0]
    code = ast[1].children
    while Eval frame, expr
      statements frame, code
      
  If: (ast, frame) ->
    expr = Eval frame, ast[0]
    if expr
      code = ast[1].children
      statements frame, code
    else
      if ast[2]
        code = ast[2].children
        statements frame, code

handle_data = (data) ->
  program = JSON.parse data
  frame = Frame()
  for stmt in program
    Statement stmt, frame


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
