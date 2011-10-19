# Create an intermediate language that is easy to parse and step-debug.

# Example usage:
#  coffee nodes_to_json.coffee test/binary_search.coffee | coffee builder.coffee -
#

TAB = ''

PUT = (s, f) ->
  code = TAB + s
  if f
    INDENT()
    code += f()
    DEDENT()
  code

INDENT = -> TAB += '  '
DEDENT = -> TAB = TAB[0...TAB.length - 2]

Eval = (block) ->
  [prefix, line, block] = indenter.small_block(block)
  return '' if line.length == 0
  args = line.split(' ')
  name = args[0]
  if Build[name]
    Build[name](args, block)
  else
    console.log "unknown #{name}"

Join = (s1, s2) ->
  lines = s2.split '\n'
  if lines.length == 1
    s1 + ' ' + s2
  else
    s1 + '\n' + ('  ' + s for s in lines).join('\n')

Block = (block) ->
  s = ''
  while block.len() > 0
    s += Eval block
    s += '\n'
  s

Shift = (block) ->
  block.shift()[1]

Comma = (arr) ->
  arr.join ', '

Build =
  'ACCESS': (args, block) ->
    val = Eval block
    access = Shift block
    "#{val}.#{access}"

  'ARGS': (args, block) ->
    my_args = []
    while block.len() > 0
      my_args.push Eval block
    "(#{Comma my_args})"
  
  'ARR': (args, block) ->
    elems = []
    while block.len() > 0
      elems.push Eval block
    "[#{Comma elems}]"
  
  'ASSIGN': (args, block) ->
    my_var = Eval block
    value = Eval block
    PUT "#{my_var} = #{value}"

  'CALL': (args, block) ->
    my_var = Eval block
    args = Eval block
    "#{my_var}#{args}"
    
  'CODE': (args, block) ->
    params = Eval block
    Join(params, Block block)
    
  'COND': (args, block) ->
    Eval block
    
  'DO': (args, block) ->
    Block block

  'EVAL': (args, block) ->
    return args[1]
    
  'IF': (args, block) ->
    cond = "if #{Eval block}"
    body = Eval block
    stmt = Join cond, body
    if block.len() > 0
      elseBody = Join "else", Eval block
      stmt = stmt + "\n" + elseBody
    stmt

  'INDEX': (args, block) ->
    val = Eval block
    index = Eval block
    "#{val}[#{index}]"

  'NUMBER': (args, block) ->
    args[1]

  'OP_BINARY': (args, block) ->
    op = args[1]
    op = 'is' if op == '==='
    operand1 = Eval block
    operand2 = Eval block
    "#{operand1} #{op} #{operand2}"

  'OP_UNARY': (args, block) ->
    op = args[1]
    operand = Eval block
    "#{op}#{operand}"
    
  'PARAMS': (args, block) ->
    params = []
    while block.len() > 0
      params.push block.shift()[1]
    "(#{Comma params}) ->"
  
  'PARENS': (args, block) ->
    expr = Eval block
    "(#{expr})"

  'RETURN': (args, block) ->
    val = Eval block
    "return #{val}"

  'WHILE': (args, block) ->
    cond = "while #{Eval block}"
    body = Eval block
    Join cond, body

parser = (indented_lines) ->
  while indented_lines.len() > 0
    console.log Eval(indented_lines)

handle_data = (s) ->
  prefix_line_array = indenter.big_block(s)
  parser(prefix_line_array)  

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
