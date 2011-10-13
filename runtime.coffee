# This is an experiment in having CS interpret itself. One use case would
# be educational environments, where students are learning CS and need
# to be able to pause/resume applications, etc.

# Example usage:
#  coffee nodes_to_json.coffee test/binary_search.coffee | coffee runtime.coffee -
#

# BIG OVERVIEW: The AST comes in as a JSON tree.  We recursively apply Eval to the nodes,
# using Scope to manage our variables.
handle_data = (data) ->
  program = JSON.parse data
  coffeecoffee(program)
  
coffeecoffee = (program) ->
  scope = Scope()
  for stmt in program
    Eval scope, stmt

Eval = (scope, ast) ->
  name = the_key_of(ast)
  method = AST[name]
  if method
    node = ast[name]
    Debugger.set_line_number(node)
    return method scope, node  
  throw "#{name} not supported yet"

CURRENT_OBJECT_METHOD_NAME = null # for super
  
AST =
  deref_properties: (scope, obj, properties) ->
    for accessor in properties.slice(0, properties.length - 1)
      key = Eval scope, accessor
      obj = obj[key]
    last_property = properties[properties.length - 1]
    if last_property.Access?.proto == ".prototype"
      obj = obj.prototype
    key = Eval scope, last_property
    [obj, key]

  name: (ast) ->
    return ast.name.Literal.value

  Access: (scope, ast) ->
    AST.name ast
    
  Arr: (scope, ast) ->
    objects = ast.objects
    return objects.map (obj) -> Eval scope, obj

  Assign: (scope, ast) ->
    context = ast.context
    
    set = (scope, ast, value) ->
      name = the_key_of(ast)
      method = LHS[name]
      if method
        return method scope, ast[name], value
      throw "#{name} not supported yet on LHS"

    # There is a bit of similarity within LHS vs. AST for handling
    # the left-hand-side of assignments, but the semantic differences
    # can get kind of subtle, so avoiding coupling is higher priority
    # than avoiding duplication.
    LHS = 
      Arr: (scope, ast, value) ->
        for object, i in ast.objects
          if object.Splat?
            num_to_grab = value.length - ast.objects.length + 1
            set scope, object.Splat.name, value[i...i+num_to_grab]
          else
            set scope, object, value[i]
          
      Obj: (scope, ast, value) ->
        for property in ast.properties
          if property.Assign?
            key = property.Assign.variable.Value.base.Literal.value
            val = value[key]
            set scope, property.Assign.value, val
          else
            name = property.Value.base.Literal.value
            scope.set name, value[name]
        
      Value: (scope, ast, value) ->
        if ast.properties.length == 0
          base_key = the_key_of(ast.base)
          if base_key == "Arr" || base_key == "Obj"
            set scope, ast.base, value
          else
            lhs = ast.base.Literal.value  
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
      if arg.Splat?
        args = args.concat Eval scope, arg.Splat.name
      else
        args.push Eval scope, arg

    if ast.isSuper
      this_var = scope.get "this"
      this_var.__super__[CURRENT_OBJECT_METHOD_NAME].apply this_var, args
      return

    variable = ast.variable.Value
    obj = Eval scope, variable.base
    properties = variable.properties

    if ast.isNew
      # may need to handle properties better
      val = newify obj, args
      Debugger.info "new #{obj} with args: #{args}" 
      return val

    if properties.length == 0
      val = obj args...
    else
      [obj, key] = AST.deref_properties scope, obj, properties
      if !obj[key]?
        throw "method #{key} does not exist for obj #{obj}"
      old_method_name = CURRENT_OBJECT_METHOD_NAME
      CURRENT_OBJECT_METHOD_NAME = key
      try
        Debugger.info "call #{key} with args: #{args}"
        val = obj[key].apply obj, args
      finally
        CURRENT_OBJECT_METHOD_NAME = old_method_name
      val
  
  Class: (scope, ast) ->
    class_name = ast.variable.Value.base.Literal.value

    expressions = ast.body.Block.expressions
    if expressions.length == 0
      class_code = null
      block_ast = null
    else if expressions.length == 1
      class_code = null
      block_ast = expressions[0]
    else
      [class_code, block_ast] = expressions
        
    if class_code
      Eval scope, class_code
        
    if block_ast
      proto = Eval scope, block_ast
    else
      proto = ->
        
    if ast.parent
      parent_class = Eval scope, ast.parent 
    else
      parent_class = null
    klass = build_class proto, parent_class
    klass.toString = -> "[class #{class_name}]"
    scope.set class_name, klass
    
  Code: (scope, ast) ->
    f = (args...) ->
      my_args = arg for arg in args
      parms = {}
      for param in ast.params
        param = param.Param
        if param.splat
          val = args
        else
          val = args.shift()
        if val == undefined && param.value
          val = Eval scope, param.value
        if param.name.Value?.properties
          field = AST.name param.name.Value.properties[0].Access
          this[field] = val
        else
          field = AST.name param
          parms[field] = val
      sub_scope = Scope(parms, scope, this, my_args)
      try
        return Eval sub_scope, ast.body
      catch e
        if e.retval?
          return e.retval.obj
        throw e
    if ast.bound
      obj = scope.get "this"
      return (args...) ->
        f.apply(obj, args)
    f

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
      key_var = ast.index.Literal.value
      val_var = ast.name && AST.name ast
      for key_val, val_val of obj
        scope.set key_var, key_val
        if val_var?
          scope.set val_var, val_val
        try
          val = Eval scope, ast.body
        catch e
          break if e.__meta_break
          continue if e.__meta_continue
          throw e
        val
    else
      range = Eval scope, ast.source
      step_var = AST.name ast
      for step_val in range
        scope.set step_var, step_val
        try
          val = Eval scope, ast.body
        catch e
          break if e.__meta_break
          continue if e.__meta_continue
          throw e
        val
      
  If: (scope, ast) ->
    if Eval scope, ast.condition
      Eval scope, ast.body
    else if ast.elseBody
      Eval scope, ast.elseBody
      
  In: (scope, ast) ->
    object = Eval scope, ast.object
    array = Eval scope, ast.array
    val = object in array
    val = !val if ast.negated
    val
    
  Index: (scope, ast) ->
    return Eval scope, ast.index

  Literal: (scope, ast) ->
    value = ast.value
    if value
      return false if value == 'false'
      return true if value == 'true'
      return null if value == 'null'
      return undefined if value == 'undefined'
      if value == 'break'
        throw __meta_break: true
      if value == 'continue'
        throw __meta_continue: true
      if value.charAt(0) == '"'
        return JSON.parse value
      if value.charAt(0) == "'"
        return JSON.parse '"' + value.substring(1, value.length-1) + '"'
      if value.match(/\d+/) != null
        return parseFloat(value)
      if value.charAt(0) == '/'
        regex = /\/(.*)\/(.*)/
        match = regex.exec(value)
        return RegExp match[1], match[2]
      return scope.get(value)
      
  Obj: (scope, ast) ->
    obj = {}
    for property in ast.properties
      ast = property.Assign

      LHS = 
        set: (ast, value) ->
          name = the_key_of(ast)
          method = LHS[name]
          if method
            return method ast[name], value
          throw "#{name} not supported yet on Obj LHS"

        Literal: (ast, value) ->
          lhs = ast.value
          obj[lhs] = value

        Value: (ast, value) ->    
          LHS.set ast.base, value
          
      value = Eval scope, ast.value
      LHS.set ast.variable, value
    obj

  Op: (scope, ast) ->
    is_chainable = (op) ->
      op in ['<', '>', '>=', '<=', '===', '!==']
    
    op = ast.operator
    
    if op == '++' or op == '--'
      return AST.Assign scope,
        context: op
        variable: ast.first
        value: ast.first
    
    if op == "?"
      try
        return Eval scope, ast.first
      catch e
        if e.__meta && e.__type == 'reference'
          return Eval scope, ast.second
      
    if op == 'new'
      class_name = ast.first.Value.base.Literal.value
      class_function = scope.get(class_name)
      return newify class_function, []
    
    if op == '&&'
      return Eval(scope, ast.first) && Eval(scope, ast.second)
      
    if ast.second
      operand1 = Eval scope, ast.first
      if is_chainable(op) && the_key_of(ast.first) == "Op" && is_chainable(ast.first.Op.operator)
        return false if !operand1
        operand1 = Eval scope, ast.first.Op.second

      operand2 = Eval scope, ast.second
      ops = {
        '*':   -> operand1 * operand2
        '/':   -> operand1 / operand2
        '+':   -> operand1 + operand2
        '-':   -> operand1 - operand2
        '|':   -> operand1 | operand2
        '&':   -> operand1 & operand2
        '^':   -> operand1 ^ operand2
        '===': -> operand1 is operand2
        '!==': -> operand1 isnt operand2
        '>>':  -> operand1 >> operand2
        '>>>': -> operand1 >>> operand2
        '<<':  -> operand1 << operand2
        '||':  -> operand1 || operand2
        '<':   -> operand1 < operand2
        '<=':  -> operand1 <= operand2
        '>':   -> operand1 > operand2
        '>=':  -> operand1 >= operand2
        '%':   -> operand1 % operand2
        'in':  -> operand1 of operand2
        'instanceof': -> operand1 instanceof operand2
      }
      if ops[op]
        val = ops[op]()
        Debugger.info "Op: #{operand1} #{op} #{operand2} -> #{val}"
        return val
    else
      operand1 = Eval scope, ast.first
      ops = {
        '-': -> -1 * operand1
        '!': -> !operand1
        '~': -> ~operand1
        'typeof': -> typeof operand1
      }
      if ops[op]
        return ops[op]()
    throw "unknown op #{op}"

  Parens: (scope, ast) ->
    body = ast.body
    if body.Block?
      body = body.Block
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
    range = ast.range.Range
    from_val = Eval scope, range.from
    to_val = Eval scope, range.to
    to_val += 1 if !range.exclusive
    from_val: from_val
    to_val: to_val
    
  Switch: (scope, ast) ->
    subject = Eval scope, ast.subject
    for case_ast in ast.cases
      match_value = Eval scope, case_ast.cond
      if subject == match_value
        return Eval scope, case_ast.block
    if ast.otherwise
      return Eval scope, ast.otherwise
    null
    
  Throw: (scope, ast) ->
    e = Eval scope, ast.expression
    throw __meta: e
    
  Try: (scope, ast) ->
    try
      Eval scope, ast.attempt
    catch e
      throw e unless e.__meta?
      catch_var = ast.error.Literal.value
      scope.set catch_var, e.__meta
      Eval scope, ast.recovery
    finally
      if ast.ensure
        Eval scope, ast.ensure
      
  Value: (scope, ast) ->
    obj = Eval scope, ast.base
    for property in ast.properties
      break if property.Access?.soak && !obj?
      key = the_key_of(property)
      if key == 'Slice'
        slice = Eval scope, property
        obj = obj.slice(slice.from_val, slice.to_val)
      else if key == 'Access'
        key = Eval scope, property
        obj = obj[key]
        Debugger.info "deref #{key} -> #{obj}"
      else if key == "Index"
        key = Eval scope, property
        obj = obj[key]
        Debugger.info "deref [#{key}] -> #{obj}"
      else
        throw "unexpected key #{key}"      
    return obj

  While: (scope, ast) ->
    while true
      Debugger.info "while <condition>..."
      cond = Eval scope, ast.condition
      break unless cond
      Debugger.info "(cond true)"
      try
        val = Eval scope, ast.body
      catch e
        break if e.__meta_break
        continue if e.__meta_continue
        throw e
      val

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
        if context != '='
          Debugger.info "#{var_name} = #{closure_wrapper.obj}..."
        assigned_val = update_variable_reference(closure_wrapper, "obj", value, context)
        Debugger.info "#{var_name} #{context} #{value} -> #{assigned_val}"
        assigned_val
      else if context == "="
        # first reference to local variable
        Debugger.info "#{var_name} = #{value} (original set)"
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
        Debugger.info "deref #{var_name} -> #{value}"
        return value

      # builtins
      Debugger.info "deref #{var_name} (builtin)"
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

internal_throw = (type, e) ->
  throw {
    __meta: e
    __type: type
  }

build_class = (proto, superclass)->
  # The class mechanism is mostly handled through JS, rather than
  # simulated, but we need to do this to play nice with JS libraries.
  extendify = (child, parent) ->
    ctor = ->
      this.constructor = child
      null # super important
    for key of parent
      if Object::hasOwnProperty.call(parent, key)
        child[key] = parent[key]
    ctor.prototype = parent.prototype
    child.prototype = new ctor
    child.__super__ = parent.prototype
    child

  X = ->
    this.__super__ = X.__super__
    if Object::hasOwnProperty.call(proto, "constructor")
      proto.constructor.apply this, arguments
    else if superclass
      X.__super__.constructor.apply this, arguments
    else
      undefined
  if superclass
    extendify(X, superclass)
  for key of proto
    X.prototype[key] = proto[key]
  X
  
newify = (func, args) ->
  ctor = ->
  ctor.prototype = func.prototype
  child = new ctor
  result = func.apply child, args
  if typeof result is "object"
    result
  else
    child

the_key_of = (ast) ->
  # there is just one key
  for key of ast
    return key
      
pp = (obj, description) ->
  util = require 'util'
  util.debug "-----"
  util.debug description if description?
  util.debug JSON.stringify obj, null, "  "

# Note that this mostly gets overridden client side.
Debugger =
  info: (s) ->
    console.log "(interpreter)", s
  set_line_number: (ast) ->
    if ast.firstLineNumber
      Debugger.highlight_line(ast.firstLineNumber)
  highlight_line: (line_number) ->
    console.log "(interpreter) line = #{line_number}"

if window?
  window.coffeecoffee = coffeecoffee
  window.Debugger = Debugger
else
  # assume we're running node side for now
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
