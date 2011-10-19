# Create an intermediate language that is easy to parse and step-debug.

# Example usage:
#  coffee nodes_to_json.coffee test/binary_search.coffee | coffee builder.coffee -
#

Eval = (block) ->
  [prefix, line, block] = indenter.small_block(block)
  return '' if line.length == 0
  args = line.split(' ')
  name = args[0]
  arg = args[1...args.length].join ' ' # gross, need regex
  if Build[name]
    Build[name](arg, block)
  else
    console.log "unknown #{name}"

Join = (s1, s2) ->
  lines = s2.split '\n'
  if lines.length == 1
    s1 + ' ' + s2
  else
    Indent s1, s2
    
Indent = (s1, s2) ->
  lines = s2.split '\n'
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
  'ACCESS': (arg, block) ->
    val = Eval block
    access = Shift block
    "#{val}.#{access}"

  'ARGS': (arg, block) ->
    my_args = []
    while block.len() > 0
      my_args.push Eval block
    "(#{Comma my_args})"
  
  'ARR': (arg, block) ->
    elems = []
    while block.len() > 0
      elems.push Eval block
    "[#{Comma elems}]"
  
  'ASSIGN': (arg, block) ->
    my_var = Eval block
    op = arg
    value = Eval block
    Join "#{my_var} #{op}", value

  'CALL': (arg, block) ->
    my_var = Eval block
    args = Eval block
    "#{my_var}#{args}"

  'CLASS': (arg, block) ->
    prolog = "class #{Shift block}"
    Indent prolog, Eval block
    
  'CODE': (arg, block) ->
    params = Eval block
    Join params, Block block
    
  'COND': (arg, block) ->
    Eval block
    
  'DO': (arg, block) ->
    Block block
    
  'EXISTENCE': (args, block) ->
    Eval(block) + '?'

  'EVAL': (arg, block) ->
    return arg

  'FOR_IN': (arg, block) ->
    step_var = Shift block
    range_var = Eval block
    for_stmt = "for #{step_var} in #{range_var}"
    Indent for_stmt, Eval block
    
  'IF': (arg, block) ->
    cond = "if #{Eval block}"
    body = Eval block
    stmt = Join cond, body
    if block.len() > 0
      elseBody = Join "else", Eval block
      stmt = stmt + "\n" + elseBody
    stmt

  'INDEX': (arg, block) ->
    val = Eval block
    index = Eval block
    "#{val}[#{index}]"

  'NEW': (arg, block) ->
    my_var = Eval block
    args = Eval block
    "new #{my_var}#{args}"

  'NUMBER': (arg, block) ->
    arg

  'OBJ': (arg, block) ->
    s = ''
    while block.len() > 0
      name = Shift block
      s += Join "#{name}:", Eval block
      s += '\n'
    s

  'OP_BINARY': (arg, block) ->
    op = arg
    op = 'is' if op == '==='
    op = 'isnt' if op == '!=='
    operand1 = Eval block
    operand2 = Eval block
    "#{operand1} #{op} #{operand2}"

  'OP_UNARY': (arg, block) ->
    op = arg
    operand = Eval block
    "#{op}#{operand}"
    
  'PARAMS': (arg, block) ->
    params = []
    while block.len() > 0
      params.push block.shift()[1]
    "(#{Comma params}) ->"
  
  'PARENS': (arg, block) ->
    expr = Eval block
    "(#{expr})"
    
  'RANGE_EXCLUSIVE': (arg, block) ->
    low = Eval block
    high = Eval block
    "[#{low}...#{high}]"

  'RETURN': (arg, block) ->
    val = Eval block
    "return #{val}"

  'SLICE': (arg, block) ->
    val = Eval block
    index = Eval block
    "#{val}#{index}"

  'STRING': (arg, block) ->
    arg

  'VALUE': (arg, block) ->
    arg

  'WHILE': (arg, block) ->
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
