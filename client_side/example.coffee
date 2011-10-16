window.EXAMPLES =
  fib: '''
    fib = (n) ->
      [a, b] = [1, 1]
      while b < n
        [a, b] = [b, a+b]
      a
        
    n = 100000
    answer = fib(n)
    alert "biggest fib number < #{n} = #{answer}"
    '''
  
  bubble_sort: '''
    # A bubble sort implementation, sorting the given array in-place.
    bubble_sort = (list) ->
      for i in [0...list.length]
        for j in [0...list.length - i]
          k = j + 1
          if list[j] > list[k]
            [list[j], list[k]] = [list[k], list[j]] 
      list

    # Test the function.
    alert bubble_sort([9, 2, 0, 4, 3, 8]).join(' ')
    '''
