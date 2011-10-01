# HISTORY: this used to parse the ouput of coffee --nodes, but now it directly uses
#     CS to get more detailed info on nodes
# 
# USAGE: coffee nodes_to_json.coffee hello_world.coffee

CoffeeScript = require "./lib/coffee-script"
fs = require "fs"
  
wrap = (expressions) ->
  expressions = expressions.map (expression) ->
    wrap_obj(expression)
    
wrap_obj = (expression) ->
  expression.children = undefined
  keys = [
    'attempt',
    'base',
    'body',
    'condition',
    'elseBody',
    'error',
    'expression',
    'first',
    'from',
    'index',
    'name',
    'parent',
    'range',
    'recovery',
    'second',
    'source',
    'subject',
    'to',
    'value',
    'variable',
    ]
  for key in keys
    if expression[key]
      expression[key] = wrap_obj expression[key]
  list_keys = [
    'args',
    'expressions',
    'objects',
    'params',
    'properties',
  ]
  for list_key in list_keys
    if expression[list_key]
      expression[list_key] = wrap expression[list_key]
  if expression.cases
    my_cases = []
    for when_statement in expression.cases
      my_cases.push
        conds: wrap_obj my_cond for my_cond in when_statement[0]
        block: wrap_obj when_statement[1]
    expression.cases = my_cases
  name = expression.constructor.name
  if name == 'Obj'
    expression.objects = undefined
  if name && name != 'Array'
    [name, expression]
  else
    expression

handle_data = (data) ->
  expressions = CoffeeScript.nodes(data).expressions
  console.log JSON.stringify wrap(expressions), null, "  "

fs = require 'fs'
fn = process.argv[2]
if fn
  data = fs.readFileSync(fn).toString()
  handle_data(data)
else
  data = ''
  stdin = process.openStdin()
  stdin.on 'data', (buffer) ->
    data += buffer.toString() if buffer
  stdin.on 'end', ->
    handle_data(data)

