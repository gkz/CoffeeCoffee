# This is an experiment in having CS host itself. One use case would
# be educational environments, where students are learning CS and need
# to be able to pause/resume applications, etc.

Statement = (ast, frame) ->
  method = Runtime[ast.parent]
  # console.log "Statement", ast.parent
  if method
    method ast.children, frame
  else
    console.log "Statement not supported:", ast.parent

pp = (obj, description) ->
  console.log "-----"
  console.log description
  console.log JSON.stringify obj, null, "  "

# Frame is just a hash for now.  It's mostly used by Assign.  No notion
# of closures yet.
Frame = ->
  # for now, all frames get the "builtins" hacked in, which is kind of ugly
  self =
    console: 
      log: (frame, parms) ->
        console.log Eval frame, parms[0]

Deref = (obj, accessors) ->
  result = obj
  for accessor in accessors
    result = result[accessor.value]
  result

Eval = (frame, ast) ->
  if ast.value
    if ast.value.charAt(0) == '"'
      return JSON.parse ast.value
    else if ast.value.match(/\d+/) != null
      return parseInt(ast.value)
    else
      return frame[ast.value]
  else
    if ast.parent == 'Code'
      return (frame, params) -> Statement ast.children[0], frame
    if ast.parent.kind == "Op"
      return Op frame, ast.parent.value, ast.children
    return Deref frame[ast.parent.value], ast.children


Op = (frame, op, children) ->
  operand1 = Eval frame, children[0]
  operand2 = Eval frame, children[1]
  if op == '*'
    return operand1 * operand2

Runtime =
  Block: (ast) ->
    frame = Frame()
    for stmt in ast
      Statement stmt, frame

  Assign: (ast, frame) ->
    lhs = ast[0].value
    rhs = Eval frame, ast[1]
    frame[lhs] = rhs

  Call: (ast, frame) ->
    method = Eval frame, ast[0]
    method frame, ast[1...ast.length]


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
