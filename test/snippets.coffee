class Foo
  (n) ->
    @foo = n
  bar: ->
    this.foo
  yo: ->
    @incr()
    this.foo
  incr: ->
    @foo += 1
  
c = new Foo(2)
console.log c.bar()
c.incr()
console.log c.foo
console.log c.yo()

class X
  yo: (n) ->
    console.log(20 + n)
c = new X()
c.yo(3)
