coffeecoffee is a program that interprets CoffeeScript programs without transcompiling to Javascript.

The main engine here is runtime.coffee, which directly evaluates expressions from the AST.  Here is the script:

```
#!/bin/sh
filename=$1
shift
echo "--------- $filename"
coffee nodes_to_json.coffee "$filename" | coffee runtime.coffee - $@
```

You can see it in action here:

```
> ./coffeecoffee test/snippets.coffee 
--------- test/snippets.coffee
******* Functions
Filling the cup with coffee...
******* Objects and Arrays
do re mi fa so
Max
******* Lexical Scoping
10
******* Splats
Gold: Michael Phelps
Silver: Liu Xiang
The Field: Yao Ming,Allyson Felix,Shawn Johnson,Roman Sebrle,Guo Jingjing,Tyson Gay,Asafa Powell,Usain Bolt
******* Loops and Comprehensions
[ 10, 9, 8, 7, 6, 5, 4, 3, 2, 1 ]
[ 'max is 10', 'ida is 9', 'tim is 11' ]
[ '5 little monkeys, jumping on the bed.    One fell out and bumped his head.',
  '4 little monkeys, jumping on the bed.    One fell out and bumped his head.',
  '3 little monkeys, jumping on the bed.    One fell out and bumped his head.',
  '2 little monkeys, jumping on the bed.    One fell out and bumped his head.',
  '1 little monkeys, jumping on the bed.    One fell out and bumped his head.' ]
******* Slicing and Splicing
[ 3, 4, 5, 6 ]
[ 0, 1, 2, -3, -4, -5, -6, 7, 8, 9 ]
******* Everything is an Expression
Liz
6
[ 'global',
  'process',
  'GLOBAL',
  'root',
  'Buffer',
  'setTimeout',
  'setInterval',
  'clearTimeout',
  'clearInterval',
  'console' ]
And the error is ... ReferenceError: nonexistent is not defined
******* The Existential Operator
bear
******* Classes, Inheritance, and Super
Slithering...
Sammy the Python moved 5m.
Galloping...
Tommy the Palomino moved 45m.
one-two
******* Destructuring Assignment
0
Mostly Sunny
F.T. Marinetti-Via Roma 42R
impossible
******* Function Binding
alice
******* Switch/When/Else
Monday
Tuesday
no match
******* Try/Catch/Finally
1 leads to exception
finally
2
finally
******* Chained Comparisons
true
******* String Interpolation, Heredocs, and Block Comments
3.142857142857143 is a decent approximation of π
Call me Ishmael. Some years ago -- never mind how long precisely -- having little or no money in my purse, and nothing particular to interest me on shore, I thought I would sail about a little and see the watery part of the world...
<strong>
  cup of coffeescript
</strong>
******* Misc: bare classes and instanceof, etc.
true
true
true
string
true true true
true true true
true true
true true
true true
true true
true
******* break and continue
1
3
5
1
3
5
```

Here is the program:

```
> cat test/snippets.coffee 
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

####

String::dasherize = ->
  this.replace /_/g, "-"
console.log "one_two".dasherize()

###########
banner "Destructuring Assignment"

theBait   = 1000
theSwitch = 0

[theBait, theSwitch] = [theSwitch, theBait]
console.log theBait


weatherReport = (location) ->
  # Make an Ajax request to fetch the weather...
  [location, 72, "Mostly Sunny"]

[city, temp, forecast] = weatherReport "Berkeley, CA"
console.log forecast


futurists =
  sculptor: "Umberto Boccioni"
  painter:  "Vladimir Burliuk"
  poet:
    name:   "F.T. Marinetti"
    address: [
      "Via Roma 42R"
      "Bellagio, Italy 22021"
    ]

{poet: {name, address: [street, city]}} = futurists
console.log name + '-' + street

# splats
tag = "<impossible>"
[open, contents..., close] = tag.split("")
console.log contents.join ''

#############
banner "Function Binding"

class Button
  click: (@f) ->
  do_click: -> @f.apply(@)

button = new Button    

class Account
  constructor: (@customer) ->
    button.click =>
      console.log @customer
    
account = new Account("alice")
button.do_click()

##############
banner "Switch/When/Else"
f = (day) -> 
  long_name = switch day
      when "Mon" then "Monday"
      when "Tue" then "Tuesday"
      else "no match"
  console.log long_name

f "Mon"
f "Tue"
f "Wed"

#############
banner "Try/Catch/Finally"
f = (n) ->
  try
    if n == 1
      throw "1 leads to exception"
    console.log n
  catch error
    console.log error
  finally
    console.log "finally"
f(1)
f(2)

#############
banner "Chained Comparisons"
cholesterol = 127
healthy = 200 > cholesterol > 60
console.log healthy

############
banner "String Interpolation, Heredocs, and Block Comments"

sentence = "#{ 22 / 7 } is a decent approximation of π"
console.log sentence

mobyDick = "Call me Ishmael. Some years ago --
 never mind how long precisely -- having little
 or no money in my purse, and nothing particular
 to interest me on shore, I thought I would sail
 about a little and see the watery part of the
 world..."
console.log mobyDick


html = '''
       <strong>
         cup of coffeescript
       </strong>
       '''
console.log html


#########
banner "Misc: bare classes and instanceof, etc."

class C

class D
  
c = new C
console.log c instanceof C
console.log !(c instanceof D)
console.log C not instanceof D
console.log typeof "x"
console.log true, on, yes
console.log !false, !off, not no
console.log 4 is 4, 4 isnt 5
console.log true and true, true or false
console.log "x" of {x: 0}, "y" not of {x: 0}
console.log 1 in [1,2], 3 not in [1,2]
console.log !("x".foo?.bar.whatever)?

########
banner "break and continue"

for i in [0..10]
  continue if i % 2 == 0
  console.log i
  break if i == 5

i = 0
while true
  i += 1
  continue if i % 2 == 0
  console.log i
  break if i == 5
```
