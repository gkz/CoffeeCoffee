window.EXAMPLES =
  fib: '''
    output = (s) ->
      # This div is set up for us already.  Note that we
      # can access JS libraries like jQuery.
      $("#output").html s
      
    fib = (n) ->
      [a, b] = [1, 1]
      while b < n
        [a, b] = [b, a+b]
        output a
      a
        
    n = 1000000
    answer = fib(n)
    output "biggest fib number < #{n} = #{answer}"
    '''
