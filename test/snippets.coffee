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