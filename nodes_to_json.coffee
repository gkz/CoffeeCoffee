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
    'base',
    'body',
    'condition',
    'elseBody',
    'expression',
    'first',
    'from',
    'index',
    'range',
    'second',
    'source',
    'to',
    'value',
    'variable',
    ]
  for key in keys
    if expression[key]
      expression[key] = wrap_obj expression[key]
  list_keys = [
    'args',
    'expressions'
    'objects',
    'properties',
  ]
  for list_key in list_keys
    if expression[list_key]
      expression[list_key] = wrap expression[list_key]
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

