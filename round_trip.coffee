# Create CS code from our intermediate language.  This code is mostly used to validate
# that the transformation to the intermediate language is not lossy.


# Example usage:
#  coffee nodes_to_json.coffee test/cubes.coffee | node builder.js - | node round_trip.js - 

Build =
  'ACCESS': (arg, block) ->
    val = Eval block
    access = Shift block
    "#{val}.#{access}"

  'ACCESS_SOAK': (arg, block) ->
    val = Eval block
    access = Shift block
    "#{val}?.#{access}"

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

  'BOUND_CODE': (arg, block) ->
    params = Eval block
    Join params + " =>", Block block

  'BREAK': (arg, block) ->
    'break'

  'CALL': (arg, block) ->
    my_var = Eval block
    args = Eval block
    "#{my_var}#{args}"

  'CASE': (arg, block) ->
    Join "when #{Eval block} then", Eval block

  'CATCH': (arg, block) ->
    stmt = "catch #{Shift block}"
    Indent stmt, Eval block

  'CLASS': (arg, block) ->
    prolog = "class #{Shift block}"
    parent = Eval block
    if parent
      prolog += " extends #{parent}"
    Indent prolog, Eval block
    
  'CODE': (arg, block) ->
    params = Eval block
    Join params + " ->", Block block
    
  'COND': (arg, block) ->
    Eval block
    
  'CONTINUE': (arg, block) ->
    'continue'

  'DECR_PRE': (arg, block) ->
    "--#{Eval block}"
    
  'DO': (arg, block) ->
    Block block
    
  'EXISTENCE': (args, block) ->
    Eval(block) + '?'

  'EVAL': (arg, block) ->
    return arg

  'FINALLY': (arg, block) ->
    Indent "finally", Eval block
    
  'FOR_IN': (arg, block) ->
    step_var = Shift block
    range_var = Eval block
    for_stmt = "for #{step_var} in #{range_var}"
    Indent for_stmt, Eval block
    
  'FOR_OF': (arg, block) ->
    vars = Eval block
    range_var = Eval block
    for_stmt = "for #{vars} of #{range_var}"
    Indent for_stmt, Eval block
    
  'IF': (arg, block) ->
    cond = "if #{Eval block}"
    body = Eval block
    stmt = Join cond, body
    if block.len() > 0
      elseBody = Join "else", Eval block
      stmt = stmt + "\n" + elseBody
    stmt

  'IN': (arg, block) ->
    Join "#{Eval block} of", Eval block

  'INCR_PRE': (arg, block) ->
    "++#{Eval block}"

  'INDEX': (arg, block) ->
    val = Eval block
    index = Eval block
    "#{val}[#{index}]"

  'KEY': (arg, block) ->
    Eval block

  'KEY_VALUE': (arg, block) ->
    name = Shift block
    Join "#{name}:", Eval block

  'METHODS': (arg, block) ->
    code = ''
    while block.len() > 0
      name = Shift block
      code += Join "#{name}:", Eval block
      code += '\n'
    code

  'NEW': (arg, block) ->
    my_var = Eval block
    args = Eval block
    "new #{my_var}#{args}"
    
  'NEW_BARE': (arg, block) ->
    my_var = Shift block
    "new #{my_var}"    

  'NOT_IN': (arg, block) ->
    Join "#{Eval block} not of", Eval block

  'NUMBER': (arg, block) ->
    arg

  'OBJ': (arg, block) ->
    s = ''
    while block.len() > 0
      s += Eval block
      s += '\n'
    "{#{s}}"

  'OP_BINARY': (arg, block) ->
    op = arg
    op = 'is' if op == '==='
    op = 'isnt' if op == '!=='
    op = 'of' if op == 'in'
    operand1 = Eval block
    operand2 = Eval block
    "#{operand1} #{op} #{operand2}"

  'OP_UNARY': (arg, block) ->
    op = arg
    op = "not" if op == '!'
    operand = Eval block
    "#{op}(#{operand})"
    
  'OTHERWISE': (arg, block) ->
    Join "else", Eval block
    
  'PARAM': (arg, block) ->
    param = Shift block
    features = SubBlock block
    while features.len() > 0
      feature = Shift features
      if feature == 'autoassign'
        param = '@' + param
    if block.len() > 0
      param += " = #{Eval block}"
    param
    
  'PARAMS': (arg, block) ->
    params = []
    while block.len() > 0
      params.push Eval block
    "(#{Comma params})"
  
  'PARENS': (arg, block) ->
    expr = Eval block
    "(#{expr})"
    
  'PARENTS': (arg, block) ->
    if block.len() > 0
      Eval block
    else
      null
    
  'PROTO': (arg, block) ->
    val = Eval block
    "#{val}.prototype"
    
  'RANGE_EXCLUSIVE': (arg, block) ->
    low = Eval block
    high = Eval block
    "[#{low}...#{high}]"

  'RANGE_INCLUSIVE': (arg, block) ->
    low = Eval block
    high = Eval block
    "[#{low}..#{high}]"

  'REGEX': (arg, block) ->
    arg
    
  'RETURN': (arg, block) ->
    val = Eval block
    "return #{val}"

  'SLICE': (arg, block) ->
    val = Eval block
    index = Eval block
    "#{val}#{index}"

  'SPLAT': (arg, block) ->
    val = Eval block
    "#{val}..."

  'STRING': (arg, block) ->
    arg
  
  'SUPER': (arg, block) ->
    Join "super", Eval block

  'SWITCH': (arg, block) ->
    prolog = "switch #{Eval block}"
    body = []
    while block.len() > 0
      body.push Eval block
    Indent prolog, body.join '\n'

  'THROW': (arg, block) ->
    val = Eval block
    "throw #{val}"
  
  'TRY': (arg, block) ->
    stmt = Indent "try", Eval block
    while block.len() > 0
      stmt += '\n' + Eval block
    stmt
       
  'VALUE': (arg, block) ->
    arg
    
  'VARS': (arg, block) ->
    vars = []
    while block.len() > 0
      vars.push Shift block
    Comma vars

  'WHILE': (arg, block) ->
    cond = "while #{Eval block}"
    body = Eval block
    Join cond, body

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

SubBlock = (block) ->
  [prefix, line, block] = indenter.small_block(block)
  block

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
