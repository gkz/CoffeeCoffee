# This is an experiment in having CS interpret itself. One use case would
# be educational environments, where students are learning CS and need
# to be able to pause/resume applications, etc.

Statement = (ast, frame) ->
  method = Runtime[ast.parent]
  console.log "Statement", ast.parent
  if method
    method ast.children, frame
  else
    console.log "Statement not supported:", ast.parent

pp = (obj, description) ->
  console.log "-----"
  console.log description if description?
  console.log JSON.stringify obj, null, "  "

# Frame is just a hash for now.  It's mostly used by Assign.  No notion
# of closures yet.
Frame = (params) ->
  # for now, all frames get the "builtins" hacked in, which is kind of ugly
  self =
    console: 
      log: (frame, parms) ->
        console.log Eval frame, parms[0]
  for key of params
    self[key] = params[key]
  self

Deref = (frame, obj, accessors) ->
  result = obj
  for accessor in accessors
    if accessor.parent == 'Index'
      index = Eval frame, accessor.children[0]
      console.log frame
      console.log result
      result = result[index]
    result = result[accessor.value]
  result

Function = (frame, ast, params) ->
  param_values = {}
  for child_ast in ast
    if child_ast.kind == "Param"
      param_values[child_ast.value] = Eval frame, params.shift()
    else if child_ast.parent == "Block"
      Runtime.Block child_ast.children, frame, param_values

Eval = (frame, ast) ->
  if ast.value
    if ast.value.charAt(0) == '"'
      return JSON.parse ast.value
    else if ast.value.match(/\d+/) != null
      return parseInt(ast.value)
    else
      return frame[ast.value]
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
    return Deref frame, frame[ast.parent.value], ast.children


Op = (frame, op, children) ->
  if op == '-'
    operand1 = Eval frame, children[0]
    if op == '-'
      return -1 * operand1
    else
      throw "unknown op #{op}"
  else
    operand1 = Eval frame, children[0]
    operand2 = Eval frame, children[1]
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
      console.log "RETURN", retval
      return retval
    Statement stmt, frame

Runtime =
  Block: (ast, frame, param_values = {}) ->
    frame = Frame param_values
    statements frame, ast

  Assign: (ast, frame) ->
    lhs = ast[0].value
    rhs = Eval frame, ast[1]
    frame[lhs] = rhs

  Call: (ast, frame) ->
    method = Eval frame, ast[0]
    method frame, ast[1...ast.length]

  While: (ast, frame) ->
    expr = ast[0]
    code = ast[1].children
    while true
      result = Eval frame, expr
      break if !result
      statements frame, code
      
  If: (ast, frame) ->
    expr = ast[0]
    if expr
      code = ast[1].children
      for stmt in code
        Statement stmt, frame
    else
      if ast[2]
        code = ast[2].children
        for stmt in code
          Statement stmt, frame

handle_data = (data) ->
  program = JSON.parse data
  for stmt in program
    Statement stmt


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
