# Create CS code from our intermediate language.  This code is mostly used to validate
# that the transformation to the intermediate language is not lossy.


# Example usage:
#  coffee nodes_to_json.coffee test/cubes.coffee | node builder.js - | node round_trip.js - 

Compiler =
  'ACCESS': (arg, block) ->
    value_code = Compile block
    access = Shift block
    (rt, cb) ->
      rt.call value_code, (val) ->
        cb val[access]

  'ARGS': (arg, block) ->
    arg_codes = []
    while block.len() > 0
      arg_codes.push Compile block
    (rt, cb) ->
      args = []
      f = (arg_code, cb) ->
        rt.call arg_code, (my_arg) ->
          args.push my_arg
          cb(true)
      last = ->
        cb args
      iterate_callbacks f, last, arg_codes
    
  'ARR': (arg, block) ->
    arr_exprs = []
    while block.len() > 0
      arr_exprs.push Compile block
    (rt, cb) ->
      arr = []
      f = (elem_expr, cb) ->
        rt.call elem_expr, (val) ->
          arr.push val
          cb(true)
      last = ->
        cb arr
      iterate_callbacks f, last, arr_exprs
    
  'ASSIGN': (arg, block) ->
    [name, subarg, subblock] = GetBlock block
    value_code = Compile block
    context = arg
    
    build_assign = (name, arg, block) ->
      if name == 'EVAL'
        var_name = arg
        (val, rt, cb) ->
          rt.scope().set var_name, val, context
          cb()
          
      else if name == 'INDEX'
        var_code = Compile block
        index_code = Compile block
        (val, rt, cb) ->
          rt.call var_code, (my_var) ->
            rt.call index_code, (index) ->
              my_var[index] = val 
              cb()

      else if name == 'ARR'
        assigners = []
        while block.len() > 0
          [name, arg, subblock] = GetBlock block
          assigners.push build_assign(name, arg, subblock)
        (val, rt, cb) ->
          i = 0
          f = (assigner, cb) ->
            assigner val[i], rt, ->
              i += 1
              cb true
          last = ->
            cb()
          iterate_callbacks f, last, assigners 
    
    assign = build_assign(name, subarg, subblock)
    
    (rt, cb) ->
      rt.call value_code, (val) ->
        assign val, rt, ->
          cb null

  'CALL': (arg, block) ->
    [name, subarg, subblock] = GetBlock block
    if name == 'ACCESS'
      my_obj = Compile subblock
      accessor = Shift subblock
      args = Compile block
      (rt, cb) ->
        rt.call my_obj, (obj) ->
          rt.call args, (my_args) ->
            f = obj[accessor]
            if f.__coffeecoffee__
              f.apply obj, rt, cb, my_args
            else
              cb f.call obj, my_args...
    else
      my_var = Compiler[name](subarg, subblock)
      args = Compile block
      (rt, cb) ->
        rt.call my_var, (f) ->
          rt.call args, (my_args) ->
            if f.__coffeecoffee__
              f rt, cb, my_args
            else
              cb f my_args...

  'CODE': (arg, block) ->
    # Note that CS functions can only be called from
    # CS now.
    [name, subarg, params_block] = GetBlock block
    params = []
    while params_block.len() > 0
      [ignore, ignore, param_block] = GetBlock params_block
      params.push Shift param_block
    
    set_parms = (scope, my_args) ->
      i = 0
      for param in params
        scope.set param, my_args[i]
        i += 1
    
    body = Compile block
    (rt, cb) ->
      f = (rt, cb, my_args) ->
        scope = rt.scope()
        set_parms(scope, my_args)
        rt.call body, (val) ->
          rt.control_flow = null
          cb val
      f.__coffeecoffee__ = true
      cb f
    
  'COND': (arg, block) ->
    f = Compile block
    (rt, cb) ->
      rt.call f, (val) ->
        cb val

  'DO': (arg, block) ->
    stmts = []
    while block.len() > 0
      stmts.push Compile(block)
    (rt, cb) ->
      val = null
      f = (stmt, cb) ->
        rt.call stmt, (value) ->
          val = value
          if rt.control_flow
            cb(false)
          else
            cb(true)
      last = ->
        cb val
      iterate_callbacks(f, last, stmts)
    
  'EVAL': (arg, block) ->
    (rt, cb) ->
      val = rt.scope().get(arg)
      cb val

  'FOR_IN': (arg, block) ->
    step_var = Shift block
    range_code = Compile block
    block_code = Compile block
    f = (rt, cb) ->
      rt.call range_code, (range) ->
        values = []
        f = (range_val, cb) ->
          rt.scope().set step_var, range_val
          rt.call block_code, (val) ->
            values.push val
            cb true
        last = ->
          cb values
        iterate_callbacks f, last, range
        
  'IF': (arg, block) ->
    cond_code = Compile block
    if_code = Compile block
    if block.len() > 0
      else_code = Compile block
    else
      else_code = null
    
    (rt, cb) ->
      rt.call cond_code, (cond) ->
        if cond
          rt.call if_code, (val) ->
            cb val
        else
          if else_code
            rt.call else_code, (val) ->
              cb val
          else
            cb null

  'INDEX': (arg, block) ->
    value_code = Compile block
    index_code = Compile block
    (rt, cb) ->
      rt.call value_code, (val) ->
        rt.call index_code, (index) ->
          cb val[index]
      
  'KEY_VALUE': (arg, block) ->
    name = Shift block
    value_code = Compile block
    (rt, obj, cb) ->
      rt.call value_code, (val) ->
        obj[name] = val
      cb null
    
  'NUMBER': (arg, block) ->
    n = parseFloat(arg)
    (rt, cb) ->
      cb n

  'OBJ': (arg, block) ->
    keys = []
    while block.len() > 0
      keys.push Compile block
    (rt, cb) ->
      obj = {}
      
      f = (key, cb) ->
        rt.call_extra key, obj, (val) ->
          cb(true)
      last = ->
        cb obj

      iterate_callbacks(f, last, keys)
      
  'OP_BINARY': (arg, block) ->
    op = arg
    f = binary_ops[op]
    operand1 = Compile block
    operand2 = Compile block

    if op == '&&'
      (rt, cb) ->
        rt.call operand1, (op1) ->
          if op1
            rt.call operand2, (op2) ->
              cb op2
          else
            cb false
    else
      (rt, cb) ->
        rt.call operand1, (op1) ->
          rt.call operand2, (op2) ->
            cb f op1, op2

  'OP_UNARY': (arg, block) ->
    op = arg
    f = unary_ops[op]
    operand1 = Compile block

    (rt, cb) ->
      rt.call operand1, (op1) ->
        cb f op1

  'PARENS': (arg, block) ->
    Compile block

  'RANGE_EXCLUSIVE': (arg, block) ->
    low_code = Compile block
    high_code = Compile block
    (rt, cb) ->
      rt.call low_code, (low) ->
        rt.call high_code, (high) ->
          cb [low...high]

  'RETURN': (arg, block) ->
    value_code = Compile block
    (rt, cb) ->
      rt.call value_code, (val) ->
        rt.control_flow = 'return'
        cb val

  'STRING': (arg, block) ->
    value = arg
    if value.charAt(0) == '"'
      s = JSON.parse value
    if value.charAt(0) == "'"
      s = JSON.parse '"' + value.substring(1, value.length-1) + '"'
    (rt, cb) ->
      cb s
        
  'WHILE': (arg, block) ->
    cond_code = Compile block
    block_code = Compile block
    f = (rt, cb) ->
      rt.call cond_code, (cond) ->
        if cond
          rt.call block_code, (val) ->
            if rt.control_flow == 'return'
              cb val
            else
              f rt, cb
        else
          cb null

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
      code self, extra, (val) ->
        f = -> cb(val)
        setTimeout(f, 0)

    scope: -> scope
    
    call: (code, cb) ->
      code self, (val) ->
        f = -> cb(val)
        setTimeout(f, 0)
      
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
        if ok
          next(i+1)
        else
          last()
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
