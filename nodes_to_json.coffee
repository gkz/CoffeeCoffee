# HISTORY: this used to parse the ouput of coffee --nodes, but now it directly uses
#     CS to get more detailed info on nodes
# 
# USAGE: coffee nodes_to_json.coffee hello_world.coffee

CoffeeScript = require "./lib/coffee-script"
fs = require "fs"
  
wrap = (expressions) ->
  expressions = expressions.map (expression) ->
    expression.children = undefined
    if expression.value?.body?.expressions
      expression.value.body.expressions = wrap(expression.value.body.expressions)
    name = expression.constructor.name
    [name, expression]
  expressions

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

