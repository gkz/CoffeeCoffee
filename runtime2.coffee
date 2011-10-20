# Create CS code from our intermediate language.  This code is mostly used to validate
# that the transformation to the intermediate language is not lossy.


# Example usage:
#  coffee nodes_to_json.coffee test/cubes.coffee | node builder.js - | node round_trip.js - 

Compiler =
  'ASSIGN': (arg, block) ->
    [name, subarg, subblock] = GetBlock block
    var_name = subarg
    value_code = Compile block
    (rt) ->
      rt.call value_code, (val) ->
        rt.scope.set var_name, val, arg
        rt.value null

  'EVAL': (arg, block) ->
    (rt) ->
      val = rt.scope.get(arg)
      rt.value val
      
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
    Compiler[name](arg, block)
  else
    console.log "unknown #{name}"

RunTime = ->
  scope = Scope()
  scope.set("x", 42)
  self =
    call: (code, cb) ->
      code
        value: (val) ->
          cb(val)
        call: self.call
        scope: scope
        step: self.step
    step: (f) ->
      setTimeout f, 1000

parser = (indented_lines) ->
  runtime = RunTime()
  f = ->
    if indented_lines.len() > 0
      code = Compile(indented_lines)
      if code
        runtime.call code, (val) ->
          console.log val
          runtime.step f
  f()

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
