code_chart = ->
  canvas = document.getElementById("canvas")
  ctx = canvas.getContext("2d")
  canvas.width = canvas.width
  x = 0
  y = 0
  ctx.moveTo(x,0)

  go_to_line: (line_number) ->
    return if y == line_number
    y = line_number
    x += 1
    ctx.lineTo(x, y)
    ctx.stroke()

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
  update_code_view = (line_number) ->
    count = $("#count#{line_number}")
    count.html parseInt(count.html()) + 1
    # NOTE: THIS IS THE STEP DEBUGGING FACILITY.  Close the
    # inspector if you don't want step debugging.
    debugger
    $("#line#{last_line_number}").removeClass("highlight")
    $("#line#{line_number}").addClass("highlight")
    last_line_number = line_number
  chart = code_chart()
  (line_number) ->
    update_code_view(line_number)
    chart.go_to_line(line_number)

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
      Debugger.highlight_line = highlight_line()
      ast = window.nodes_to_json(code);
      # console.log(JSON.stringify(ast, null, "   "));
      window.coffeecoffee(ast)
    catch e
      alert e
    finally
      return false
