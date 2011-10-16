code_chart = (update_code_view) ->
  timeline = []
  y = 0
  max_y = 0
  debug_info = {}

  go_to_line: (line_number) ->
    # return if y == line_number
    y = line_number
    max_y = y if y > max_y
    timeline.push y
    
  info: (s) ->
    t = timeline.length - 1
    debug_info[t] = [] unless debug_info[t]?
    debug_info[t].push s
    
  draw_graph: ->
    width = 1000
    height = 100
    y_scale = Math.floor(height / max_y)
    y_scale = 1 if y_scale == 0
    x_scale = Math.floor(width / timeline.length)
    x_scale = 1 if x_scale == 0
    
    $("#code_chart").html '<h6>Hover over graph to review the program execution.</h6>'
    canvas_html = """
      <canvas id='canvas' width='#{width}' height='#{height}' style='border: 1px blue solid'>
      </canvas>
    """
    $("#code_chart").append canvas_html

    canvas = document.getElementById("canvas")
    ctx = canvas.getContext("2d")
    ctx.moveTo(x,0)

    for y, x in timeline
      ctx.lineTo(x * x_scale + 1, y * y_scale)
      ctx.stroke()

    write_debug_info = (s) ->
      debug_html = $("<pre>").html s.join('\n')
      $("#debug_info_view").html debug_html

    $(canvas).mousemove ->
      xx = event.pageX - $(canvas).offset().left
      t = Math.floor((xx - 1) / x_scale)
      if timeline[t]
        update_code_view(timeline[t])
      if debug_info[t]
        write_debug_info debug_info[t]

activate_code_view_window = (code, num_visits) ->
  div = $("#code_view")
  div.empty()
  table = $("<table>")
  table.append '''
    <tr>
      <th>line #</th>
      <th>num evals</th>
      <th>stmt</th>
    </tr>
    '''
  for line, index in code.split('\n')
    i = index+1
    num_visits[i] = 0 unless num_visits[i]?
    tr = $("<tr>")
    table.append tr
    tr.append """
      <td>#{i}</td>
      <td id='count#{i}'>#{num_visits[i]}</td>
      <td><pre id='line#{i}'>#{line}</pre></td>
      """
  div.append table

Timeline_tracker = ->
  num_visits = {}
  visit_line = (line_number) ->
    num_visits[line_number] = 0 unless num_visits[line_number]?
    num_visits[line_number] += 1
    
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
  num_visits: num_visits

run_code = ->
  try
    code = $("#code").val()
    timeline_tracker = Timeline_tracker()
    Debugger.highlight_line = timeline_tracker.highlight_line
    Debugger.info = timeline_tracker.chart.info
    ast = window.nodes_to_json(code);
    # console.log(JSON.stringify(ast, null, "   "));
    window.coffeecoffee(ast)
    activate_code_view_window(code, timeline_tracker.num_visits)
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
