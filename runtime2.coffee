# Create CS code from our intermediate language.  This code is mostly used to validate
# that the transformation to the intermediate language is not lossy.


# Example usage:
#  coffee nodes_to_json.coffee test/cubes.coffee | node builder.js - | node round_trip.js - 

Compiler =
  'NUMBER': (arg, block) ->
    (rt) ->
      rt.value parseFloat(arg)
      
  'OP_BINARY': (arg, block) ->
    op = arg
    f = binary_ops[op]
    operand1 = Compile block
    operand2 = Compile block

    (rt) ->
      rt.call operand1, (op1) ->
        rt.call operand2, (op2) ->
          rt.value f op1, op2

  'OP_UNARY': (arg, block) ->
    op = arg
    f = unary_ops[op]
    operand1 = Compile block

    (rt) ->
      rt.call operand1, (op1) ->
        rt.value f op1

Compile = (block) ->
  [prefix, line, block] = indenter.small_block(block)
  return null if line.length == 0
  args = line.split(' ')
  name = args[0]
  arg = args[1...args.length].join ' ' # gross, need regex
  if Compiler[name]
    Compiler[name](arg, block)
  else
    console.log "unknown #{name}"

RunTime = ->
  self =
    call: (code, cb) ->
      code
        value: (val) ->
          cb(val)
        call: self.call

parser = (indented_lines) ->
  runtime = RunTime()
  while indented_lines.len() > 0
    code = Compile(indented_lines)
    if code
      runtime.call code, (val) ->
        console.log val

handle_data = (s) ->
  prefix_line_array = indenter.big_block(s)
  parser(prefix_line_array)  

binary_ops = {
  '*':   (op1, op2) -> op1 * op2
  '/':   (op1, op2) -> op1 / op2
  '+':   (op1, op2) -> op1 + op2
  '-':   (op1, op2) -> op1 - op2
  '|':   (op1, op2) -> op1 | op2
  '&':   (op1, op2) -> op1 & op2
  '^':   (op1, op2) -> op1 ^ op2
  '===': (op1, op2) -> op1 is op2
  '!==': (op1, op2) -> op1 isnt op2
  '>>':  (op1, op2) -> op1 >> op2
  '>>>': (op1, op2) -> op1 >>> op2
  '<<':  (op1, op2) -> op1 << op2
  '||':  (op1, op2) -> op1 || op2
  '<':   (op1, op2) -> op1 < op2
  '<=':  (op1, op2) -> op1 <= op2
  '>':   (op1, op2) -> op1 > op2
  '>=':  (op1, op2) -> op1 >= op2
  '%':   (op1, op2) -> op1 % op2
  'in':  (op1, op2) -> op1 of op2
  'instanceof': (op1, op2) -> op1 instanceof op2
}


unary_ops = {
  '-': (op) -> -1 * op
  '!': (op) -> !op
  '~': (op) -> ~op
  'typeof': (op) -> typeof op
}

if window?
  window.transcompile = transcompile
  window.Debugger = Debugger
else
  # assume we're running node side for now
  fs = require 'fs'
  indenter = require './indenter'
  [fn] = process.argv.splice 2, 1
  if fn == '-'
    data = ''
    stdin = process.openStdin()
    stdin.on 'data', (buffer) ->
      data += buffer.toString() if buffer
    stdin.on 'end', ->
      handle_data(data)
  else
    data = fs.readFileSync(fn).toString()
    handle_data(data)
