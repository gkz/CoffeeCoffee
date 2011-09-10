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

Frame = ->
  # gross
  self =
    console: (frame, parms) ->
      console.log Eval frame, parms[0]

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
      return ast.children[0]
    if ast.parent.kind == "Op"
      return Op frame, ast.parent.value, ast.children


Op = (frame, op, children) ->
  operand1 = Eval frame, children[0]
  operand2 = Eval frame, children[1]
  if op == '*'
    return operand1 * operand2

Value = (ast) ->
  return ast.value if ast.value?
  return ast.parent.value

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
    method_name = Value(ast[0])
    method = frame[method_name]
    throw "unknown method #{method_name}" unless method?
    if method instanceof Function
      method frame, ast[1...ast.length]
      return
    Statement(method)


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
