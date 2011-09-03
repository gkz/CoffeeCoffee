ArrayView = (list, first, last) ->
  first = 0 unless first?
  last = list.length unless last?
  index = first
  self =
    shift: ->
      throw "illegal" if self.len() <= 0
      obj = list[index]
      index += 1
      obj
    peek: ->
      list[index]
    len: ->
      last - index
    at: (offset) ->
      list[index + offset]
    shift_slice: (how_many) ->
      view = ArrayView(list, index, index + how_many)
      index += how_many
      view
    shift_while: (f) ->
      while self.len() > 0
        return if !f(self.peek())
        self.shift()

IndentationHelper =
  number_of_lines_in_indented_block: (len_prefix, indented_lines) ->
      # Find how many lines are indented
      i = 0
      while i < indented_lines.len()
          [new_prefix, line] = indented_lines.at(i)
          if line and new_prefix.length <= len_prefix
              break
          i += 1
      return i

  find_indentation: (line) ->
    re = RegExp('( *)(.*)')
    match = re.exec(line)
    prefix = match[1]
    line = match[2]
    prefix = '' if line == ''
    return [prefix, line]

parse_line = (text) ->
  re = RegExp /(\S+) (.*)/
  match = re.exec(text)
  if match
    label = match[1]
    val = match[2]
    re = RegExp /"(.*)"/
    match = re.exec val
    if match
        val = match[1]
    {kind: label, value: val}
  else
    text
    
parse_indented_lines = (obj, indented_lines) ->
  while indented_lines.len() > 0
    line = indented_lines.shift()
    break unless line?
    [prefix, text] = line
    block_size = IndentationHelper.number_of_lines_in_indented_block(prefix.length, indented_lines)
    if block_size > 0
      block = indented_lines.shift_slice(block_size)
      node = []
      parse_indented_lines(node, block)
      obj.push {parent: parse_line(text), children: node}
    else
      obj.push parse_line text

parse = (data) ->
  lines = data.split('\n')
  lines = (line for line in lines when line.trim() != '')
  indented_lines = (IndentationHelper.find_indentation(line) for line in lines)
  indented_lines = ArrayView indented_lines
  root = []
  parse_indented_lines(root, indented_lines)
  root

pp = (data) ->
  console.log JSON.stringify(data, null, "  ")

handle_data = (data) ->pp parse data
  
fs = require 'fs' 
fn = process.argv[2] 
if fn 
  data = fs.readFileSync(fn).toString() 
  handle_data(data) 
else 
  data = '' 
  stdin = process.openStdin() 
  stdin.on 'data', (buffer) -> 
    data += buffer.toString() if buffer 
  stdin.on 'end', -> 
    handle_data(data)

