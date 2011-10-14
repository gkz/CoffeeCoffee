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
        
    n = 1000000000000
    answer = fib(n)
    output "biggest fib number < #{n} = #{answer}"
    '''
  
  bubble_sort: '''
    # A bubble sort implementation, sorting the given array in-place.
    bubble_sort = (list) ->
      for i in [0...list.length]
        for j in [0...list.length - i]
          if list[j] > list[j+1]
            [list[j], list[j+1]] = [list[j+1], list[j]] 
      list

    # Test the function.
    alert bubble_sort([9, 2, 7, 0, 1, 5, 4, 3, 8]).join(' ')
    '''
