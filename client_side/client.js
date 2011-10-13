(function() {
  jQuery(document).ready(function() {
    var code;
    code = '[a, b] = [1, 1]\nn = 1000000\nwhile b < n\n  [a, b] = [b, a+b]\n  console.log a\n$("#output").html "biggest fib number < #{n} = #{a}"';
    $("#code").val(code);
    return $("input.code").click(function() {
      var ast;
      try {
        code = $("#code").val();
        ast = window.nodes_to_json(code);
        console.log(JSON.stringify(ast, null, "   "));
        return window.coffeecoffee(ast);
      } catch (e) {
        return alert(e);
      } finally {
        return false;
      }
    });
  });
}).call(this);
