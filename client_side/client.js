(function() {
  var activate_code_view_window, highlight_line;
  activate_code_view_window = function(code) {
    var div, i, line, pre, _len, _ref, _results;
    div = $("#code_view");
    div.empty();
    _ref = code.split('\n');
    _results = [];
    for (i = 0, _len = _ref.length; i < _len; i++) {
      line = _ref[i];
      pre = $('<pre>').html(line);
      pre.attr("id", "line" + (i + 1));
      _results.push(div.append(pre));
    }
    return _results;
  };
  highlight_line = function() {
    var last_line_number;
    last_line_number = 0;
    return function(line_number) {
      if (line_number === last_line_number) {
        return;
      }
      debugger;
      $("#line" + last_line_number).removeClass("highlight");
      $("#line" + line_number).addClass("highlight");
      return last_line_number = line_number;
    };
  };
  Debugger.highlight_line = highlight_line();
  jQuery(document).ready(function() {
    var code;
    code = '[a, b] = [1, 1]\nn = 1000000\nwhile b < n\n  [a, b] = [b, a+b]\n  console.log a\n\n# integrate w/jQuery\n$("#output").html "biggest fib number < #{n} = #{a}"';
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
