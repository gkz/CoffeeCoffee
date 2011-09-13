multiply = (i) ->
  while i > 5
    console.log i
    if i > 10
      i = i - 3
    else
      i = i >> 1
  console.log i

multiply(15)
