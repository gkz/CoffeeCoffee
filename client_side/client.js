(function() {
  var activate_code_view_window, highlight_line;
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
    var last_line_number;
    last_line_number = 0;
    return function(line_number) {
      var count;
      count = $("#count" + line_number);
      count.html(parseInt(count.html()) + 1);
      debugger;
      $("#line" + last_line_number).removeClass("highlight");
      $("#line" + line_number).addClass("highlight");
      return last_line_number = line_number;
    };
  };
  Debugger.highlight_line = highlight_line();
  jQuery(document).ready(function() {
    var code;
    code = EXAMPLES.fib;
    $("#code").val(code);
    return $("input.code").click(function() {
      var ast;
      try {
        code = $("#code").val();
        activate_code_view_window(code);
        highlight_line(1);
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
