jQuery(document).ready ->
  # to build unminified CS (so we get full introspection)
  # MINIFY=false bin/cake build:browser
  # cp extras/coffee-script.js ../CoffeeCoffee/client_side/coffee-script.js
  code = '''
    [a, b] = [1, 1]
    n = 1000000
    while b < n
      [a, b] = [b, a+b]
      console.log a
    $("#output").html "biggest fib number < #{n} = #{a}"
    '''
  $("#code").val(code)
  $("input.code").click ->
    try
      code = $("#code").val()
      ast = window.nodes_to_json(code);
       # console.log(JSON.stringify(ast, null, "   "));
      window.coffeecoffee(ast)
    catch e
      alert e
    finally
      return false
