class Fib
  # this is done as a class for demo purposes only...
  # it makes more sense as a pure function, prolly
  constructor: (@n) ->
  calc: ->
    [a, b] = [0, 1]
    n = 0
    while n < @n
      n += 1
      [a, b] = [b, a+b]
      console.log "(program output)", a
    
n = process.argv[2]
f = new Fib(n)
f.calc()