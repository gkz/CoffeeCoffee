(function() {
  jQuery(document).ready(function() {
    var ast, code;
    code = '[a, b] = [1, 1]\nwhile a < 1000000\n  [a, b] = [b, a+b]\n  console.log a';
    ast = window.nodes_to_json(code);
    return window.coffeecoffee(ast);
  });
}).call(this);
