banner = (header) ->
  console.log "******* #{header}"
  
banner "Functions"
  
fill = (container, liquid = "coffee") ->
  "Filling the #{container} with #{liquid}..."
console.log fill "cup"
