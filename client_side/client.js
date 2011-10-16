(function() {
  var Timeline_tracker, activate_code_view_window, code_chart, populate_examples_dropdown, reset_example, run_code;
  code_chart = function(update_code_view) {
    var debug_info, max_y, timeline, y;
    timeline = [];
    y = 0;
    max_y = 0;
    debug_info = {};
    return {
      go_to_line: function(line_number) {
        y = line_number;
        if (y > max_y) {
          max_y = y;
        }
        return timeline.push(y);
      },
      info: function(s) {
        var t;
        t = timeline.length - 1;
        if (debug_info[t] == null) {
          debug_info[t] = [];
        }
        return debug_info[t].push(s);
      },
      draw_graph: function() {
        var canvas, canvas_html, ctx, height, width, write_debug_info, x, x_scale, y, y_scale, _len;
        width = 1000;
        height = 100;
        y_scale = Math.floor(height / max_y);
        if (y_scale === 0) {
          y_scale = 1;
        }
        x_scale = Math.floor(width / timeline.length);
        if (x_scale === 0) {
          x_scale = 1;
        }
        $("#code_chart").html('<h6>Hover over graph to review the program execution.</h6>');
        canvas_html = "<canvas id='canvas' width='" + width + "' height='" + height + "' style='border: 1px blue solid'>\n</canvas>";
        $("#code_chart").append(canvas_html);
        canvas = document.getElementById("canvas");
        ctx = canvas.getContext("2d");
        ctx.moveTo(x, 0);
        for (x = 0, _len = timeline.length; x < _len; x++) {
          y = timeline[x];
          ctx.lineTo(x * x_scale + 1, y * y_scale);
          ctx.stroke();
        }
        write_debug_info = function(s) {
          var debug_html;
          debug_html = $("<pre>").html(s.join('\n'));
          return $("#debug_info_view").html(debug_html);
        };
        return $(canvas).mousemove(function() {
          var t, xx;
          xx = event.pageX - $(canvas).offset().left;
          t = Math.floor((xx - 1) / x_scale);
          if (timeline[t]) {
            update_code_view(timeline[t]);
          }
          if (debug_info[t]) {
            return write_debug_info(debug_info[t]);
          }
        });
      }
    };
  };
  activate_code_view_window = function(code, num_visits) {
    var div, i, index, line, table, tr, _len, _ref;
    div = $("#code_view");
    div.empty();
    table = $("<table>");
    table.append('<tr>\n  <th>line #</th>\n  <th>num evals</th>\n  <th>stmt</th>\n</tr>');
    _ref = code.split('\n');
    for (index = 0, _len = _ref.length; index < _len; index++) {
      line = _ref[index];
      i = index + 1;
      if (num_visits[i] == null) {
        num_visits[i] = 0;
      }
      tr = $("<tr>");
      table.append(tr);
      tr.append("<td>" + i + "</td>\n<td id='count" + i + "'>" + num_visits[i] + "</td>\n<td><pre id='line" + i + "'>" + line + "</pre></td>");
    }
    return div.append(table);
  };
  Timeline_tracker = function() {
    var chart, last_highlight, num_visits, update_code_view, visit_line;
    num_visits = {};
    visit_line = function(line_number) {
      if (num_visits[line_number] == null) {
        num_visits[line_number] = 0;
      }
      return num_visits[line_number] += 1;
    };
    last_highlight = 0;
    update_code_view = function(line_number) {
      $("#line" + last_highlight).removeClass("highlight");
      $("#line" + line_number).addClass("highlight");
      return last_highlight = line_number;
    };
    chart = code_chart(update_code_view);
    return {
      highlight_line: function(line_number) {
        visit_line(line_number);
        return chart.go_to_line(line_number);
      },
      chart: chart,
      num_visits: num_visits
    };
  };
  run_code = function() {
    var ast, code, timeline_tracker;
    try {
      code = $("#code").val();
      timeline_tracker = Timeline_tracker();
      Debugger.highlight_line = timeline_tracker.highlight_line;
      Debugger.info = timeline_tracker.chart.info;
      ast = window.nodes_to_json(code);
      window.coffeecoffee(ast);
      activate_code_view_window(code, timeline_tracker.num_visits);
      return timeline_tracker.chart.draw_graph();
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
