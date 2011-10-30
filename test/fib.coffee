class Fib
  # this is done as a class for demo purposes only...
  # it makes more sense as a pure function, prolly
  constructor: (@n) ->
    console.log n
    null
  calc: ->
    [a, b] = [0, 1]
    n = 0
    while n < @n
      n += 1
      [a, b] = [b, a+b]
      console.log a
    
n = process.argv[2]
fibber = new Fib(n)
fibber.calc()