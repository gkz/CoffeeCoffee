# Create CS code from our intermediate language.  This code is mostly used to validate
# that the transformation to the intermediate language is not lossy.


# Example usage:
#  coffee nodes_to_json.coffee test/cubes.coffee | node builder.js - | node round_trip.js - 

Compiler =
  'ACCESS': (arg, block) ->
    value_code = Compile block
    access = Shift block
    (rt) ->
      rt.call value_code, (val) ->
        rt.value val[access]

  'ARGS': (arg, block) ->
    arg_codes = []
    while block.len() > 0
      arg_codes.push Compile block
    (rt) ->
      args = []
      f = (arg_code, cb) ->
        rt.call arg_code, (my_arg) ->
          args.push my_arg
          cb(true)
      last = ->
        rt.value args
      iterate_callbacks f, last, arg_codes
    
  'ARR': (arg, block) ->
    arr_exprs = []
    while block.len() > 0
      arr_exprs.push Compile block
    (rt) ->
      arr = []
      f = (elem_expr, cb) ->
        rt.call elem_expr, (val) ->
          arr.push val
          cb(true)
      last = ->
        rt.value arr
      iterate_callbacks f, last, arr_exprs
    
  'ASSIGN': (arg, block) ->
    [name, subarg, subblock] = GetBlock block
    var_name = subarg
    value_code = Compile block
    (rt) ->
      rt.call value_code, (val) ->
        rt.scope.set var_name, val, arg
        rt.value null

  'CALL': (arg, block) ->
    my_var = Compile block
    args = Compile block
    (rt) ->
      rt.call my_var, (val) ->
        rt.call args, (my_args) ->
          if val.__coffeecoffee__
            val rt, my_args...
          else
            rt.value val my_args...

  'CODE': (arg, block) ->
    # Note that CS functions can only be called from
    # CS now.
    params = Compile block
    body = Compile block
    (rt) ->
      f = (rt, my_args...) ->
        rt.call body, (val) ->
          rt.value val
      f.__coffeecoffee__ = true
      rt.value f
    
  'COND': (arg, block) ->
    f = Compile block
    (rt) ->
      rt.call f, (val) ->
        rt.value val

  'DO': (arg, block) ->
    stmts = []
    while block.len() > 0
      stmts.push Compile(block)
    (rt) ->
      val = null
      f = (stmt, cb) ->
        rt.call stmt, (value) ->
          val = value
          cb(true)
      last = ->
        rt.value val
      iterate_callbacks(f, last, stmts)
    
  'EVAL': (arg, block) ->
    (rt) ->
      val = rt.scope.get(arg)
      rt.value val
      
  'KEY_VALUE': (arg, block) ->
    name = Shift block
    value_code = Compile block
    (rt) ->
      obj = rt.extra
      rt.call value_code, (val) ->
        obj[name] = val
      rt.value null
    
  'NUMBER': (arg, block) ->
    n = parseFloat(arg)
    (rt) ->
      rt.value n

  'OBJ': (arg, block) ->
    keys = []
    while block.len() > 0
      keys.push Compile block
    (rt) ->
      obj = {}
      
      f = (key, cb) ->
        rt.call_extra key, obj, (val) ->
          cb(true)
      last = ->
        rt.value obj

      iterate_callbacks(f, last, keys)
      
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
  
  'PARAMS': (args, block) ->
    null

  'STRING': (arg, block) ->
    value = arg
    if value.charAt(0) == '"'
      s = JSON.parse value
    if value.charAt(0) == "'"
      s = JSON.parse '"' + value.substring(1, value.length-1) + '"'
    (rt) ->
      rt.value s
        
  'WHILE': (arg, block) ->
    cond_code = Compile block
    block_code = Compile block
    f = (rt) ->
      rt.call cond_code, (cond) ->
        if cond
          rt.call block_code, ->
            f(rt)
        else
          rt.value null

GetBlock = (block) ->
  [prefix, line, block] = indenter.small_block(block)
  return null if line.length == 0
  args = line.split(' ')
  name = args[0]
  arg = args[1...args.length].join ' ' # gross, need regex
  [name, arg, block]

Compile = (block) ->
  [prefix, line, block] = indenter.small_block(block)
  return null if line.length == 0
  args = line.split(' ')
  name = args[0]
  arg = args[1...args.length].join ' ' # gross, need regex
  if Compiler[name]
    obj = Compiler[name](arg, block)
  else
    console.log "unknown #{name}"

Shift = (block) ->
  block.shift()[1]

RunTime = ->
  scope = Scope()
  self =
    call_extra: (code, extra, cb) ->
      code
        value: (val) ->
          f = -> cb(val)
          setTimeout(f, 0)
          # cb(val)
        call: self.call
        call_extra: self.call_extra
        scope: scope
        step: self.step
        extra: extra
        
    call: (code, cb) ->
      self.call_extra(code, null, cb)
      
    step: (f) ->
      setTimeout f, 200

parser = (indented_lines) ->
  runtime = RunTime()
  stmts = []
  while indented_lines.len() > 0
    code = Compile indented_lines
    stmts.push code if code
  
  f = (stmt, cb) ->
    runtime.call stmt, (val) ->
      # console.log val
      runtime.step ->
        cb(true)
  last = ->
    console.log "EXITING PROGRAM!"
  iterate_callbacks f, last, stmts

handle_data = (s) ->
  prefix_line_array = indenter.big_block(s)
  parser(prefix_line_array)  


iterate_callbacks = (f, last, arr) ->
  next = (i) ->
    if i < arr.length
      f arr[i], (ok) -> 
        next(i+1) if ok
    else
      last()
  next(0)
  
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

# Scope: returns an object to manage variable assignment
#
# Scope essentially just wraps a hash and parent scope for now.  It's mostly used by Assign.
# Scoping is still very primitive, e.g. it doesn't have full closures.  It uses
# its parent scope for lookups, but it's not rigorous about detecting hoisted
# variables.  It should work for most simple cases, though.
Scope = (params, parent_scope, this_value, args) ->
  vars = {}

  set_local_value = (key, value) ->
    # Vars are wrapped inside a hash, as a cheap trick to avoid ambiguity
    # w/r/t undefined values.  This prevents us from trying to go to the parent
    # scope when the variable has been assigned in our own scope.
    vars[key] = {obj: value}

  for key, value of params
    set_local_value(key, value)
  set_local_value("this", this_value)
  set_local_value("arguments", args)

  self =
    # try to find the wrapped variable at the correct closure scope...still a work
    # in progress
    get_closure_wrapper: (var_name) ->
      val = vars[var_name]
      return val if val?
      return parent_scope.get_closure_wrapper var_name if parent_scope
      return

    set: (var_name, value, context) ->
      context ||= "=" # default, could also be +=, etc.

      closure_wrapper = self.get_closure_wrapper var_name

      if closure_wrapper
        # we have a previous reference
        assigned_val = update_variable_reference(closure_wrapper, "obj", value, context)
        assigned_val
      else if context == "="
        # first reference to local variable
        set_local_value(var_name, value)
        value
      else
        # cannot find var, so += and friends won't work
        throw "Var #{var_name} has not been set"


    get: (var_name) ->
      if var_name == 'require'
        return (args...) -> require args...

      closure_wrapper = self.get_closure_wrapper(var_name)
      if closure_wrapper
        value = closure_wrapper.obj
        return value

      # builtins
      if root?
        val = root[var_name]
      else
        val = window[var_name]
      internal_throw "reference", "ReferenceError: #{var_name} is not defined" unless val?
      val
      
update_variable_reference = (hash, key, value, context) ->
  context ||= '='
  if key.from_val? && key.to_val?
    throw "slice assignment not allowed" if context != '='
    [].splice.apply(hash, [key.from_val, key.to_val - key.from_val].concat(value))
    return value
  commands = {
    '=':   -> hash[key] = value
    '+=':  -> hash[key] += value
    '*=':  -> hash[key] *= value
    '-=':  -> hash[key] -= value
    '||=': -> hash[key] ||= value
    '++':  -> ++hash[key]
    '--':  -> --hash[key]
  }
  throw "unknown context #{context}" unless commands[context]
  commands[context]()

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
