# Create an intermediate language that is easy to parse and step-debug.

# Example usage:
#  coffee nodes_to_json.coffee test/binary_search.coffee | coffee builder.coffee -
#

handle_data = (data) ->
  program = JSON.parse data
  transcompile(program)
  
transcompile = (program) ->
  for stmt in program
    Build stmt

Build = (ast) ->
  name = the_key_of(ast)
  method = AST[name]
  if method
    node = ast[name]
    return method node  
  throw "#{name} not supported yet"

TAB = ''

PUT = (s, f) ->
  console.log TAB, s
  if f
    INDENT()
    f()
    DEDENT()

INDENT = -> TAB += '  '
DEDENT = -> TAB = TAB[0...TAB.length - 2]

AST =
  deref_properties: (scope, obj, properties) ->
    for accessor in properties.slice(0, properties.length - 1)
      key = Build scope, accessor
      obj = obj[key]
    last_property = properties[properties.length - 1]
    if last_property.Access?.proto == ".prototype"
      obj = obj.prototype
    key = Build scope, last_property
    [obj, key]

  name: (ast) ->
    return ast.name.Literal.value

  Access: (scope, ast) ->
    AST.name ast
    
  Arr: (ast) ->
    PUT "ARR", ->
      for object in ast.objects
        Build object

  Assign: (ast) ->
    context = ast.context || '='

    PUT "ASSIGN #{context}", ->
      Build ast.variable
      Build ast.value
    return

    context = ast.context
    
    set = (scope, ast, value) ->
      name = the_key_of(ast)
      method = LHS[name]
      if method
        return method scope, ast[name], value
      throw "#{name} not supported yet on LHS"

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
            PUT "ASSIGN #{context}"
            PUT lhs
            PUT value
        else
          lhs = Build scope, ast.base
          [lhs, key] = AST.deref_properties scope, lhs, ast.properties
          update_variable_reference lhs, key, value, context

    rhs = Build scope, ast.value
    set scope, ast.variable, rhs

  Block: (ast) ->
    code = ast.expressions
    for stmt in code
      Build stmt
    
  Call: (ast) ->
    PUT "CALL", ->
      Build ast.variable
      PUT "ARGS", ->
        for arg in ast.args
          Build arg
    return
    
    args = []
    for arg in ast.args
      if arg.Splat?
        args = args.concat Build scope, arg.Splat.name
      else
        args.push Build scope, arg

    if ast.isSuper
      this_var = scope.get "this"
      this_var.__super__[CURRENT_OBJECT_METHOD_NAME].apply this_var, args
      return

    variable = ast.variable.Value
    obj = Build scope, variable.base
    properties = variable.properties

    if ast.isNew
      # may need to handle properties better
      Debugger.info "new #{obj} with args: #{args}" 
      val = newify obj, args
      return val

    if properties.length == 0
      Debugger.info "call with args: #{args}"
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
    Debugger.info "return #{val}"
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
      Build scope, class_code
        
    if block_ast
      proto = Build scope, block_ast
    else
      proto = ->
        
    if ast.parent
      parent_class = Build scope, ast.parent 
    else
      parent_class = null
    klass = build_class proto, parent_class
    klass.toString = -> "[class #{class_name}]"
    scope.set class_name, klass
    
  Code: (ast) ->
    PUT 'CODE', ->
      PUT 'PARAMS', ->
        for param in ast.params
          PUT param.Param.name.Literal.value
      Build ast.body
    return
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
          val = Build scope, param.value
        if param.name.Value?.properties
          field = AST.name param.name.Value.properties[0].Access
          Debugger.info "this.#{field} = #{val}"
          this[field] = val
        else
          field = AST.name param
          parms[field] = val
      sub_scope = Scope(parms, scope, this, my_args)
      try
        return Build sub_scope, ast.body
      catch e
        if e.retval?
          return e.retval.obj
        throw e
    if ast.bound
      obj = scope.get "this"
      return (args...) ->
        f.apply(obj, args)
    f.toString = -> "[function]"
    f

  Existence: (ast) ->
    PUT "EXISTENCE", ->
      Build ast.expression

  For: (ast) ->
    if ast.index
      obj = Build scope, ast.source
      key_var = ast.index.Literal.value
      val_var = ast.name && AST.name ast
      for key_val, val_val of obj
        Debugger.set_line_number(ast)
        Debugger.info "loop on #{key_var}"
        scope.set key_var, key_val
        if val_var?
          scope.set val_var, val_val
        try
          val = Build scope, ast.body
        catch e
          break if e.__meta_break
          continue if e.__meta_continue
          throw e
        val
    else
      PUT "FOR_IN", ->
        PUT ast.name.Literal.value
        Build ast.source
        Build ast.body
      return

      range = Build scope, ast.source
      step_var = AST.name ast
      for step_val in range
        Debugger.set_line_number(ast)
        Debugger.info "loop on #{step_var}"
        scope.set step_var, step_val
        try
          val = Build scope, ast.body
        catch e
          break if e.__meta_break
          continue if e.__meta_continue
          throw e
        val
      
  If: (ast) ->
    PUT "IF", ->
      PUT "COND", ->
        Build ast.condition
      PUT "DO", ->
        Build ast.body
      if ast.elseBody
        PUT "DO", ->
          Build ast.elseBody
    return
    
    if Build scope, ast.condition
      Build scope, ast.body
    else if ast.elseBody
      Build scope, ast.elseBody
      
  In: (scope, ast) ->
    object = Build scope, ast.object
    array = Build scope, ast.array
    val = object in array
    val = !val if ast.negated
    val
    
  Index: (scope, ast) ->
    return Build scope, ast.index

  Literal: (ast) ->
    value = ast.value
    literal = ->
      return false if value == 'false'
      return true if value == 'true'
      return null if value == 'null'
      return undefined if value == 'undefined'
      if value == 'break'
        throw __meta_break: true
      if value == 'continue'
        throw __meta_continue: true
      c = value.charAt(0)
      if c == "'" || c == '"'
        return PUT "STRING #{value}"
      if value.match(/\d+/) != null
        float = parseFloat(value)
        return PUT "NUMBER #{float}"
      if value.charAt(0) == '/'
        regex = /\/(.*)\/(.*)/
        match = regex.exec(value)
        return RegExp match[1], match[2]
      PUT "EVAL #{value}"
    literal()
      
  Obj: (ast) ->
    PUT "OBJ", ->
      for property in ast.properties
        Build property
    return

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
          Debugger.info "Obj: #{lhs}: #{value}"

        Value: (ast, value) ->    
          LHS.set ast.base, value
          
      value = Build scope, ast.value
      LHS.set ast.variable, value
    obj

  Op: (ast) ->
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
        return Build scope, ast.first
      catch e
        if e.__meta && e.__type == 'reference'
          return Build scope, ast.second
      
    if op == 'new'
      class_name = ast.first.Value.base.Literal.value
      class_function = scope.get(class_name)
      return newify class_function, []
    
    if ast.second
      if is_chainable(op) && the_key_of(ast.first) == "Op" && is_chainable(ast.first.Op.operator)
        return false if !operand1
        operand1 = Build scope, ast.first.Op.second

      PUT "OP_BINARY #{op}", ->
        Build ast.first
        Build ast.second
      return
    else
      PUT "OP_UNARY #{op}", ->
        Build ast.first
      return
    throw "unknown op #{op}"

  Parens: (ast) ->
    body = ast.body
    if body.Block?
      body = body.Block
    if body.expressions
      PUT "PARENS", ->
        return Build body.expressions[0]
    else
      return Build body

  Range: (ast) ->
    if ast.exclusive
      stmt = "RANGE_EXCLUSIVE"
    else
      stmt = "RANGE_INCLUSIVE"
    PUT stmt, ->
      Build ast.from
      Build ast.to

  Return: (ast) ->
    PUT "RETURN", ->
      Build ast.expression

  Slice: (scope, ast) ->
    range = ast.range.Range
    from_val = Build scope, range.from
    to_val = Build scope, range.to
    to_val += 1 if !range.exclusive
    from_val: from_val
    to_val: to_val
    
  Switch: (scope, ast) ->
    subject = Build scope, ast.subject
    for case_ast in ast.cases
      match_value = Build scope, case_ast.cond
      if subject == match_value
        return Build scope, case_ast.block
    if ast.otherwise
      return Build scope, ast.otherwise
    null
    
  Throw: (scope, ast) ->
    e = Build scope, ast.expression
    throw __meta: e
    
  Try: (scope, ast) ->
    try
      Build scope, ast.attempt
    catch e
      throw e unless e.__meta?
      catch_var = ast.error.Literal.value
      scope.set catch_var, e.__meta
      Build scope, ast.recovery
    finally
      if ast.ensure
        Build scope, ast.ensure
      
  Value: (ast) ->
    if ast.properties.length == 0
      Build ast.base
    else
      properties = ast.properties
      last_property = properties[properties.length - 1]   
      priors = properties.slice(0, properties.length - 1)
      
      prior = -> AST.Value
          base: ast.base
          properties: priors
      if last_property.Access?
        PUT "ACCESS", ->
          prior()
          PUT last_property.Access.name.Literal.value
      else if last_property.Index?
        PUT "INDEX", ->
          prior()
          Build last_property.Index.index
      else if last_property.Slice?
        PUT "SLICE", ->
          prior()
          Build last_property.Slice.range
      else
        throw "yo"
      return
      
    for property in ast.properties
      break if property.Access?.soak && !obj?
      key = the_key_of(property)
      if key == 'Slice'
        slice = Build scope, property
        obj = obj.slice(slice.from_val, slice.to_val)
      else if key == 'Access'
        key = Build scope, property
        obj = obj[key]
        Debugger.info "deref #{key} -> #{obj}"
      else if key == "Index"
        key = Build scope, property
        obj = obj[key]
        Debugger.info "deref [#{key}] -> #{obj}"
      else
        throw "unexpected key #{key}"      
    return obj

  While: (ast) ->
    PUT "WHILE", ->
      PUT "COND", ->
        Build ast.condition
      PUT "DO", ->
        Build ast.body
    return
    while true
      Debugger.info "while <condition>..."
      cond = Build scope, ast.condition
      if cond
        Debugger.info "(while cond true)"
      else
        Debugger.info "(while cond false)"
        break
      try
        val = Build scope, ast.body
      catch e
        break if e.__meta_break
        continue if e.__meta_continue
        throw e
      val

the_key_of = (ast) ->
  # there is just one key
  for key of ast
    return key
      
pp = (obj, description) ->
  util = require 'util'
  util.debug "-----"
  util.debug description if description?
  util.debug JSON.stringify obj, null, "  "

if window?
  window.transcompile = transcompile
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
