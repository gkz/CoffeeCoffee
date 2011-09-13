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
  keys = ['value', 'condition', 'first', 'second', 'base', 'index', 'expression', 'source', 'from', 'to']
  for key in keys
    if expression[key]
      expression[key] = wrap_obj expression[key]
  if expression.args
    expression.args = wrap(expression.args)
  if expression.properties
    expression.properties = wrap(expression.properties)
  if expression.objects
    expression.objects = wrap(expression.objects)
  if expression.body?.expressions
    expression.body.expressions = wrap(expression.body.expressions)
  if expression.elseBody?.expressions
    expression.elseBody.expressions = wrap(expression.elseBody.expressions)
  name = expression.constructor.name
  if name
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

