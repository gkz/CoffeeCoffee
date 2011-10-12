jQuery(document).ready ->
  # to build unminified CS (so we get full introspection)
  # MINIFY=false bin/cake build:browser
  code = '''
    [a, b] = [1, 1]
    while a < 1000000
      [a, b] = [b, a+b]
      console.log a
    '''
  ast = window.nodes_to_json(code);
  # console.log(JSON.stringify(ast, null, "   "));
  window.coffeecoffee(ast)
