activate_code_view_window = (code) ->
  div = $("#code_view")
  div.empty()
  table = $("<table>")
  table.append '''
    <tr>
      <th>line #</th>
      <th>num exprs evaluated</th>
      <th>stmt</th>
    </tr>
    '''
  for line, i in code.split('\n')
    tr = $("<tr>")
    table.append tr
    tr.append """
      <td>#{i+1}</td>
      <td id='count#{i+1}'>0</td>
      <td><pre id='line#{i+1}'>#{line}</pre></td>
      """
  div.append table


highlight_line = ->
  last_line_number = 0
  (line_number) ->
    count = $("#count#{line_number}")
    count.html parseInt(count.html()) + 1
    # NOTE: THIS IS THE STEP DEBUGGING FACILITY.  Close the
    # inspector if you don't want step debugging.
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
