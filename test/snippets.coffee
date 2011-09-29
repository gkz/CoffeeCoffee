banner = (header) ->
  console.log "******* #{header}"
  
########
banner "Functions"
  
fill = (container, liquid = "coffee") ->
  "Filling the #{container} with #{liquid}..."
console.log fill "cup"

########
banner "Objects and Arrays"

song = ["do", "re", "mi", "fa", "so"]

singers = {Jagger: "Rock", Elvis: "Roll"}

bitlist = [
  1, 0, 1
  0, 0, 1
  1, 1, 0
]

kids =
  brother:
    name: "Max"
    age:  11
  sister:
    name: "Ida"
    age:  9

console.log song.join " "
console.log kids.brother.name

#########
banner "Lexical Scoping"

outer = 1
changeNumbers = ->
  inner = -1
  outer = 10
inner = changeNumbers()
console.log inner


#########
banner "Splats"

gold = silver = rest = "unknown"

awardMedals = (first, second, others...) ->
  gold   = first
  silver = second
  rest   = others

contenders = [
  "Michael Phelps"
  "Liu Xiang"
  "Yao Ming"
  "Allyson Felix"
  "Shawn Johnson"
  "Roman Sebrle"
  "Guo Jingjing"
  "Tyson Gay"
  "Asafa Powell"
  "Usain Bolt"
]

awardMedals contenders...

console.log "Gold: " + gold
console.log "Silver: " + silver
console.log "The Field: " + rest

#########
banner "Loops and Comprehensions"
countdown = (num for num in [10..1])
console.log countdown


yearsOld = max: 10, ida: 9, tim: 11
ages = for child, age of yearsOld
  "#{child} is #{age}"
console.log ages

# Nursery Rhyme
num = 6
lyrics = while num -= 1
  "#{num} little monkeys, jumping on the bed.
    One fell out and bumped his head."
console.log lyrics

###########
banner "Slicing and Splicing"

numbers = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
copy    = numbers[0...numbers.length]
middle  = copy[3..6]
console.log middle

numbers = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
numbers[3..6] = [-3, -4, -5, -6]
console.log numbers

###########
banner "Everything is an Expression"

eldest = if 24 > 21 then "Liz" else "Ike"
console.log eldest

six = (one = 1) + (two = 2) + (three = 3)
console.log six

globals = (name for name of root)[0...10]
console.log globals

console.log(
  try
    nonexistent / undefined
  catch error
    "And the error is ... #{error}"
)

###########
banner "The Existential Operator"

footprints = yeti ? "bear"
console.log footprints

###########
banner "Classes, Inheritance, and Super"

class Animal
  constructor: (@name) ->

  move: (meters) ->
    console.log @name + " moved #{meters}m."

class Snake extends Animal
  move: ->
    console.log "Slithering..."
    super 5

class Horse extends Animal
  move: ->
    console.log "Galloping..."
    super 45

sam = new Snake "Sammy the Python"
tom = new Horse "Tommy the Palomino"

sam.move()
tom.move()