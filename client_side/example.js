(function() {
  window.EXAMPLES = {
    fib: 'fib = (n) ->\n  [a, b] = [1, 1]\n  while b < n\n    [a, b] = [b, a+b]\n  a\n    \nn = 100000\nanswer = fib(n)\nalert "biggest fib number < #{n} = #{answer}"',
    bubble_sort: '# A bubble sort implementation, sorting the given array in-place.\nbubble_sort = (list) ->\n  for i in [0...list.length]\n    for j in [0...list.length - i]\n      k = j + 1\n      if list[j] > list[k]\n        [list[j], list[k]] = [list[k], list[j]] \n  list\n\n# Test the function.\nalert bubble_sort([9, 2, 0, 4, 3, 8]).join(\' \')'
  };
}).call(this);
