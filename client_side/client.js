(function() {
  var activate_code_view_window, code_chart, highlight_line;
  code_chart = function() {
    var canvas, ctx, x, y;
    canvas = document.getElementById("canvas");
    ctx = canvas.getContext("2d");
    canvas.width = canvas.width;
    x = 0;
    y = 0;
    ctx.moveTo(x, 0);
    return {
      go_to_line: function(line_number) {
        if (y === line_number) {
          return;
        }
        y = line_number;
        x += 1;
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
    table.append('<tr>\n  <th>line #</th>\n  <th>num exprs evaluated</th>\n  <th>stmt</th>\n</tr>');
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
    var chart, last_line_number, update_code_view;
    last_line_number = 0;
    update_code_view = function(line_number) {
      var count;
      count = $("#count" + line_number);
      count.html(parseInt(count.html()) + 1);
      debugger;
      $("#line" + last_line_number).removeClass("highlight");
      $("#line" + line_number).addClass("highlight");
      return last_line_number = line_number;
    };
    chart = code_chart();
    return function(line_number) {
      update_code_view(line_number);
      return chart.go_to_line(line_number);
    };
  };
  jQuery(document).ready(function() {
    var code;
    code = EXAMPLES.fib;
    $("#code").val(code);
    return $("input.code").click(function() {
      var ast;
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
    });
  });
}).call(this);
