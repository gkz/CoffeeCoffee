code_chart = (update_code_view) ->
  canvas_html = '''
    <canvas id="canvas" width="520" height="100" style="border: 1px blue solid">
    </canvas>
  '''
  $("#code_chart").html canvas_html
  
  canvas = document.getElementById("canvas")
  ctx = canvas.getContext("2d")
  x = 0
  y = 0
  ctx.moveTo(x,0)
  timeline = {}

  $(canvas).mousemove ->
    x = event.pageX - $(canvas).offset().left
    if timeline[x]
      update_code_view(timeline[x])

  go_to_line: (line_number) ->
    return if y == line_number
    y = line_number
    x += 1
    timeline[x] = y
    ctx.lineTo(x, y)
    ctx.stroke()

activate_code_view_window = (code) ->
  div = $("#code_view")
  div.empty()
  table = $("<table>")
  table.append '''
    <tr>
      <th>line #</th>
      <th>num visits</th>
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

  visit_line = (line_number) ->
    return if line_number == last_line_number
    count = $("#count#{line_number}")
    count.html parseInt(count.html()) + 1
    last_line_number = line_number
    
  last_highlight = 0
  update_code_view = (line_number) ->
    $("#line#{last_highlight}").removeClass("highlight")
    $("#line#{line_number}").addClass("highlight")
    last_highlight = line_number

  chart = code_chart(update_code_view)
  (line_number) ->
    visit_line(line_number)
    chart.go_to_line(line_number)

run_code = ->
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

jQuery(document).ready ->
  # to build unminified CS (so we get full introspection)
  # MINIFY=false bin/cake build:browser
  # cp extras/coffee-script.js ../CoffeeCoffee/client_side/coffee-script.js
  code = EXAMPLES.fib
  $("#code").val(code)
  $("input.code").click ->
    run_code()
