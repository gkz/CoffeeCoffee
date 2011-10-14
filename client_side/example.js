(function() {
  window.EXAMPLES = {
    fib: 'output = (s) ->\n  # This div is set up for us already.  Note that we\n  # can access JS libraries like jQuery.\n  $("#output").html s\n  \nfib = (n) ->\n  [a, b] = [1, 1]\n  while b < n\n    [a, b] = [b, a+b]\n    output a\n  a\n    \nn = 1000000000000\nanswer = fib(n)\noutput "biggest fib number < #{n} = #{answer}"'
  };
}).call(this);
