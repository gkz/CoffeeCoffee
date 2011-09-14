foo = ->
  console.log bar()
  
bar = ->
  5

x = "foo"
y = x.slice
console.log y(1)
console.log x.slice(1)  
foo()