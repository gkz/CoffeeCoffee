# This is an experiment in having CS interpret itself. One use case would
# be educational environments, where students are learning CS and need
# to be able to pause/resume applications, etc.

# Example usage:
#  coffee nodes_to_json.coffee test/binary_search.coffee | coffee runtime.coffee
#

# IMPORTANT: This is very much a work in progress, but it does run
# simple programs like test/binary_search.coffee.

# BIG OVERVIEW: The AST comes in as a JSON tree.  We recursively apply Eval to the nodes,
# using Scope to manage our variables.
handle_data = (data) ->
  program = JSON.parse data
  scope = Scope()
  for stmt in program
    Eval scope, stmt

Eval = (scope, ast) ->
  name = ast[0]
  method = AST[name]
  if method
    return method scope, ast[1]  
  throw "#{name} not supported yet"
  
AST =
  create_new_object: (scope, class_name) ->
    class_function = scope.get(class_name)
    obj = new class_function()
    obj
  
  deref: (obj, scope, property) ->
    if property[0] == 'Slice'
      # traverse Slice/Range
      slice = Eval scope, property
      obj.slice(slice.from_val, slice.to_val)
    else
      key = Eval scope, property
      obj[key]

  deref_properties: (scope, obj, properties) ->
    for accessor in properties.slice(0, properties.length - 1)
      key = Eval scope, accessor
      obj = obj[key]
    key = Eval scope, properties[properties.length - 1]
    [obj, key]

  name: (ast) ->
    # traverse name, Literal, value, 1
    return ast.name[1].value[1]

  value: (scope, value) ->
    return false if value == 'false'
    return true if value == 'true'
    return null if value == 'null'
    return undefined if value == 'undefined'
    if value.charAt(0) == '"'
      return JSON.parse value
    if value.charAt(0) == "'"
      return value.substring(1, value.length-1)
    if value.match(/\d+/) != null
      return parseFloat(value)
    return scope.get(value)

  Access: (scope, ast) ->
    AST.name ast
    
  Arr: (scope, ast) ->
    objects = ast.objects
    return objects.map (obj) -> Eval scope, obj

  Assign: (scope, ast) ->
    context = ast.context
    
    set = (scope, ast, value) ->
      name = ast[0]
      method = LHS[name]
      if method
        return method scope, ast[1], value
      throw "#{name} not supported yet on LHS"

    # There is a bit of similarity within LHS vs. AST for handling
    # the left-hand-side of assignments, but the semantic differences
    # can get kind of subtle, so avoiding coupling is higher priority
    # than avoiding duplication.
    LHS = 
      Arr: (scope, ast, value) ->
        for object, i in ast.objects
          set scope, object, value[i]
        
      Value: (scope, ast, value) ->
        if ast.properties.length == 0
          if ast.base[0] == "Arr"
            set scope, ast.base, value
          else
            lhs = ast.base[1].value[1]  
            scope.set lhs, value, context
        else
          lhs = Eval scope, ast.base
          [lhs, key] = AST.deref_properties scope, lhs, ast.properties
          update_variable_reference lhs, key, value, context

    rhs = Eval scope, ast.value
    set scope, ast.variable, rhs

  Block: (scope, ast) ->
    code = ast.expressions
    for stmt in code
      val = Eval scope, stmt
    val
    
  Call: (scope, ast) ->
    args = []
    for arg in ast.args
      if arg[0] == 'Splat'
        args = args.concat Eval scope, arg[1].name
      else
        args.push Eval scope, arg

    variable = ast.variable[1]
    obj = Eval scope, variable.base
    properties = variable.properties

    if ast.isNew
      # need to handle properties better
      val = new obj()
      return val

    if properties.length == 0
      val = obj args...
    else  
      [obj, key] = AST.deref_properties scope, obj, properties
      val = obj[key].apply obj, args

    if ast.isNew && val.constructor
      val.constructor args...
    val
  
  Class: (scope, ast) ->
    # traverse variable, Value, base, Literal, value, 1
    class_name = ast.variable[1].base[1].value[1]

    # traverse, body, Block
    expressions = ast.body[1].expressions
    if expressions.length == 1
      class_code = null
      block_ast = expressions[0]
    else
      [class_code, block_ast] = expressions
    if class_code
      Eval scope, class_code

    proto = Eval scope, block_ast
    factory = (args...) ->
      null
    factory.prototype = proto
    scope.set class_name, factory
    
  Code: (scope, ast) ->
    return (args...) ->
      parms = {}
      for param in ast.params
        throw "Error" unless param[0] == 'Param'
        param = param[1]
        if param.splat
          val = args
        else
          val = args.shift()
        if val == undefined && param.value
          val = Eval scope, param.value
        if param.name[1].properties
          # traverse name, Value, properties, 0, Access
          field = AST.name param.name[1].properties[0][1]
          this[field] = val
        else
          field = AST.name param
          parms[field] = val
      sub_scope = Scope(parms, scope, this)
      try
        return Eval sub_scope, ast.body
      catch e
        if e.retval?
          return e.retval.obj
        throw e

  Existence: (scope, ast) ->
    try
      val = Eval scope, ast.expression
    catch e
      throw e unless e.__meta?
      return false
    val?

  For: (scope, ast) ->
    if ast.index
      obj = Eval scope, ast.source
      # traverse index, Literal, value, 1
      key_var = ast.index[1].value[1]
      val_var = ast.name && AST.name ast
      for key_val, val_val of obj
        scope.set key_var, key_val
        if val_var?
          scope.set val_var, val_val
        Eval scope, ast.body
    else
      range = Eval scope, ast.source
      step_var = AST.name ast
      for step_val in range
        scope.set step_var, step_val
        Eval scope, ast.body
      
  If: (scope, ast) ->
    if Eval scope, ast.condition
      Eval scope, ast.body
    else if ast.elseBody
      Eval scope, ast.elseBody
      
  Index: (scope, ast) ->
    return Eval scope, ast.index

  Literal: (scope, ast) ->
    val = ast.value[1]
    if val
      AST.value scope, val
      
  Obj: (scope, ast) ->
    obj = {}
    for property in ast.properties
      throw "unexpected" if property[0] != 'Assign'
      ast = property[1]

      LHS = 
        set: (ast, value) ->
          name = ast[0]
          method = LHS[name]
          if method
            return method ast[1], value
          throw "#{name} not supported yet on Obj LHS"

        Literal: (ast, value) ->
          lhs = ast.value[1]
          obj[lhs] = value

        Value: (ast, value) ->    
          LHS.set ast.base, value
          
      value = Eval scope, ast.value
      LHS.set ast.variable, value
    obj

  Op: (scope, ast) ->
    op = ast.operator
    
    if op == "?"
      try
        return Eval scope, ast.first
      catch e
        if e.__meta && e.__type == 'reference'
          return Eval scope, ast.second
      
    if op == 'new'
      # traverse first, Value, base, Literal, value
      class_name = ast.first[1].base[1].value[1]
      return AST.create_new_object scope, class_name
    
    if op == '&&'
      return Eval(scope, ast.first) && Eval(scope, ast.second)
      
    if ast.second
      operand1 = Eval scope, ast.first
      operand2 = Eval scope, ast.second
      ops = {
        '*':   -> operand1 * operand2
        '/':   -> operand1 / operand2
        '+':   -> operand1 + operand2
        '-':   -> operand1 - operand2
        '===': -> operand1 is operand2
        '!==': -> operand1 isnt operand2
        '>>':  -> operand1 >> operand2
        '||':  -> operand1 || operand2
        '<':   -> operand1 < operand2
        '>':   -> operand1 > operand2
        '%':   -> operand1 % operand2
      }
      if ops[op]
        return ops[op]()
    else
      operand1 = Eval scope, ast.first
      if op == "-"
        return -1 * operand1
      if op == '!'
        return !operand1
    throw "unknown op #{op}"

  Parens: (scope, ast) ->
    body = ast.body
    if body[0] == 'Block'
      body = body[1]
    if body.expressions
      return Eval scope, body.expressions[0]
    else
      return Eval scope, body

  Range: (scope, ast) ->
    from_val = Eval scope, ast.from
    to_val = Eval scope, ast.to
    if ast.exclusive
      [from_val...to_val]
    else
      [from_val..to_val]

  Return: (scope, ast) ->
    retval = {obj: Eval scope, ast.expression}
    throw retval: retval

  Slice: (scope, ast) ->
    range = ast.range[1]
    from_val = Eval scope, range.from
    to_val = Eval scope, range.to
    to_val += 1 if !range.exclusive
    from_val: from_val
    to_val: to_val
    
  Try: (scope, ast) ->
    try
      Eval scope, ast.attempt
    catch e
      # traverse error, Literal, value, 1
      throw e unless e.__meta?
      catch_var = ast.error[1].value[1]
      scope.set catch_var, e.__meta
      Eval scope, ast.recovery
      
  Value: (scope, ast) ->
    obj = Eval scope, ast.base
    for accessor in ast.properties
      obj = AST.deref obj, scope, accessor
    return obj

  While: (scope, ast) ->
    while Eval scope, ast.condition
      Eval scope, ast.body

# Scope: returns an object to manage variable assignment
#
# Scope essentially just wraps a hash and parent scope for now.  It's mostly used by Assign.
# Scoping is still very primitive, e.g. it doesn't have full closures.  It uses
# its parent scope for lookups, but it's not rigorous about detecting hoisted
# variables.  It should work for most simple cases, though.
Scope = (params, parent_scope, this_value) ->
  vars = {}

  set_local_value = (key, value) ->
    # Vars are wrapped inside a hash, as a cheap trick to avoid ambiguity
    # w/r/t undefined values.  This prevents us from trying to go to the parent
    # scope when the variable has been assigned in our own scope.
    vars[key] = {obj: value}

  for key, value of params
    set_local_value(key, value)
  set_local_value("this", this_value)

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
        update_variable_reference(closure_wrapper, "obj", value, context)
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
        return closure_wrapper.obj

      # builtins
      val = root[var_name]
      internal_throw "reference", "Reference Error: #{var_name} is not defined" unless val?
      val
      
internal_throw = (type, e) ->
  throw {
    __meta: e
    __type: type
  }
    
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
  }
  throw "unknown context #{context}" unless commands[context]
  commands[context]()

      
util = require 'util'

pp = (obj, description) ->
  util.debug "-----"
  util.debug description if description?
  util.debug JSON.stringify obj, null, "  "

fs = require 'fs'
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
