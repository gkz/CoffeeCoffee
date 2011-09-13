x = ->
  arr = [0, 5]
  result = arr[1]
  while result < 400
    x = 6 * 7
    result += x
  console.log "*********"
  console.log result
x()
# multiply = (i) ->
#   while i > 5
#     console.log i
#     if i > 10
#       i = i - 3
#     else
#       i = i >> 1
#   console.log i
# 
# multiply(15)
