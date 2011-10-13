activate_code_view_window = (code) ->
  div = $("#code_view")
  div.empty()
  for line, i in code.split('\n')
    pre = $('<pre>').html(line)
    pre.attr "id", "line#{i+1}"
    div.append pre


highlight_line = ->
  last_line_number = 0
  (line_number) ->
    return if line_number == last_line_number
    debugger
    $("#line#{last_line_number}").removeClass("highlight")
    $("#line#{line_number}").addClass("highlight")
    last_line_number = line_number

Debugger.highlight_line = highlight_line()


jQuery(document).ready ->
  # to build unminified CS (so we get full introspection)
  # MINIFY=false bin/cake build:browser
  # cp extras/coffee-script.js ../CoffeeCoffee/client_side/coffee-script.js
  code = EXAMPLES.fib
  $("#code").val(code)
  $("input.code").click ->
    try
      code = $("#code").val()
      activate_code_view_window(code)
      highlight_line(1)
      ast = window.nodes_to_json(code);
      # console.log(JSON.stringify(ast, null, "   "));
      window.coffeecoffee(ast)
    catch e
      alert e
    finally
      return false
