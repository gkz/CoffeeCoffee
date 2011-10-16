code_chart = (update_code_view) ->
  timeline = {}
  x = 0
  y = 0

  go_to_line: (line_number) ->
    return if y == line_number
    y = line_number
    x += 1
    timeline[x] = y
    
  draw_graph: ->
    $("#code_chart").html '<h6>Hover over graph to review the program execution.</h6>'
    canvas_html = '''
      <canvas id="canvas" width="620" height="100" style="border: 1px blue solid">
      </canvas>
    '''
    $("#code_chart").append canvas_html

    canvas = document.getElementById("canvas")
    ctx = canvas.getContext("2d")
    ctx.moveTo(x,0)

    for x of timeline
      y = timeline[x]
      ctx.lineTo(x, y)
      ctx.stroke()

    $(canvas).mousemove ->
      x = event.pageX - $(canvas).offset().left
      if timeline[x]
        update_code_view(timeline[x])


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

Timeline_tracker = ->
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
  highlight_line: (line_number) ->
    visit_line(line_number)
    chart.go_to_line(line_number)
  chart: chart

run_code = ->
  try
    code = $("#code").val()
    timeline_tracker = Timeline_tracker()
    Debugger.highlight_line = timeline_tracker.highlight_line
    ast = window.nodes_to_json(code);
    # console.log(JSON.stringify(ast, null, "   "));
    window.coffeecoffee(ast)
    activate_code_view_window(code)
    timeline_tracker.chart.draw_graph()
  catch e
    alert e
  finally
    return false

reset_example = ->
  $("#code_chart").empty()
  $("#code_view").empty()

populate_examples_dropdown = (examples) ->
  select = $("#examples")
  for example of examples
    html = "<option value=#{example}>#{example}</option>"
    select.append html
  select.change ->
    $("#code").val examples[select.val()]
    reset_example()

jQuery(document).ready ->
  # to build unminified CS (so we get full introspection)
  # MINIFY=false bin/cake build:browser
  # cp extras/coffee-script.js ../CoffeeCoffee/client_side/coffee-script.js
  code = EXAMPLES.fib
  populate_examples_dropdown(EXAMPLES)
  $("#code").val(code)
  $("input.code").click ->
    run_code()
