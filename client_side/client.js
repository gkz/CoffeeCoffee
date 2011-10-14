(function() {
  var activate_code_view_window, code_chart, highlight_line, populate_examples_dropdown, reset_example, run_code;
  code_chart = function(update_code_view) {
    var canvas, canvas_html, ctx, timeline, x, y;
    $("#code_chart").html('<h6>Hover over graph to review the program execution.</h6>');
    canvas_html = '<canvas id="canvas" width="520" height="100" style="border: 1px blue solid">\n</canvas>';
    $("#code_chart").append(canvas_html);
    canvas = document.getElementById("canvas");
    ctx = canvas.getContext("2d");
    x = 0;
    y = 0;
    ctx.moveTo(x, 0);
    timeline = {};
    $(canvas).mousemove(function() {
      x = event.pageX - $(canvas).offset().left;
      if (timeline[x]) {
        return update_code_view(timeline[x]);
      }
    });
    return {
      go_to_line: function(line_number) {
        if (y === line_number) {
          return;
        }
        y = line_number;
        x += 1;
        timeline[x] = y;
        ctx.lineTo(x, y);
        return ctx.stroke();
      }
    };
  };
  activate_code_view_window = function(code) {
    var div, i, line, table, tr, _len, _ref;
    div = $("#code_view");
    div.empty();
    table = $("<table>");
    table.append('<tr>\n  <th>line #</th>\n  <th>num visits</th>\n  <th>stmt</th>\n</tr>');
    _ref = code.split('\n');
    for (i = 0, _len = _ref.length; i < _len; i++) {
      line = _ref[i];
      tr = $("<tr>");
      table.append(tr);
      tr.append("<td>" + (i + 1) + "</td>\n<td id='count" + (i + 1) + "'>0</td>\n<td><pre id='line" + (i + 1) + "'>" + line + "</pre></td>");
    }
    return div.append(table);
  };
  highlight_line = function() {
    var chart, last_highlight, last_line_number, update_code_view, visit_line;
    last_line_number = 0;
    visit_line = function(line_number) {
      var count;
      if (line_number === last_line_number) {
        return;
      }
      count = $("#count" + line_number);
      count.html(parseInt(count.html()) + 1);
      return last_line_number = line_number;
    };
    last_highlight = 0;
    update_code_view = function(line_number) {
      $("#line" + last_highlight).removeClass("highlight");
      $("#line" + line_number).addClass("highlight");
      return last_highlight = line_number;
    };
    chart = code_chart(update_code_view);
    return function(line_number) {
      visit_line(line_number);
      return chart.go_to_line(line_number);
    };
  };
  run_code = function() {
    var ast, code;
    try {
      code = $("#code").val();
      activate_code_view_window(code);
      Debugger.highlight_line = highlight_line();
      ast = window.nodes_to_json(code);
      return window.coffeecoffee(ast);
    } catch (e) {
      return alert(e);
    } finally {
      return false;
    }
  };
  reset_example = function() {
    $("#code_chart").empty();
    return $("#code_view").empty();
  };
  populate_examples_dropdown = function(examples) {
    var example, html, select;
    select = $("#examples");
    for (example in examples) {
      html = "<option value=" + example + ">" + example + "</option>";
      select.append(html);
    }
    return select.change(function() {
      $("#code").val(examples[select.val()]);
      return reset_example();
    });
  };
  jQuery(document).ready(function() {
    var code;
    code = EXAMPLES.fib;
    populate_examples_dropdown(EXAMPLES);
    $("#code").val(code);
    return $("input.code").click(function() {
      return run_code();
    });
  });
}).call(this);
