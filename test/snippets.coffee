class Foo
  bar: ->
    this.foo = 5
    this.foo
  yo: ->
    @incr()
    this.foo
  incr: ->
    @foo = @foo + 1
  
c = new Foo("bar")
console.log c.bar()
c.incr()
console.log c.foo
console.log c.yo()
