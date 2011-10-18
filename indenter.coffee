# <hr>
# ArrayView is basically an iterator on an array.  We use it
# to avoid creating lots of little lists as we descend the
# document.
ArrayView = (list, first, last) ->
  first = 0 unless first?
  last = list.length unless last?
  index = first
  self =
    shift: ->
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
  
# <hr>
# Indentation helper methods:
IndentationHelper =
  # Shift empty lines off of our ArrayView.  Useful in modes
  # where empty lines aren't needed for the final output.
  eat_empty_lines: (indented_lines) ->
    indented_lines.shift_while (elem) ->
      [prefix, line] = elem
      line == ''

  # Count how many lines are in next indented block, but exclude
  # any trailing final whitespace, while still allowing for empty
  # lines within the block.
  number_of_lines_in_indented_block: (len_prefix, indented_lines) ->
      # Find how many lines are indented
      i = 0
      while i < indented_lines.len()
          [new_prefix, line] = indented_lines.at(i)
          if line and new_prefix.length <= len_prefix
              break
          i += 1
      # Rewind to exclude empty lines
      while i-1 >= 0 and indented_lines.at(i-1)[1] == ''
          i -= 1
      return i

  # transform "  hello" to ["  ", "hello"]
  find_indentation: (line) ->
    re = RegExp('( *)(.*)')
    match = re.exec(line)
    prefix = match[1]
    line = match[2]
    prefix = '' if line == ''
    return [prefix, line]

small_block = (indented_lines) ->
  [prefix, line] = indented_lines.shift()
  block_size = IndentationHelper.number_of_lines_in_indented_block prefix.length, indented_lines
  block = indented_lines.shift_slice(block_size)
  [prefix, line, block]
  
parser = (indented_lines) ->
  while indented_lines.len() > 0
    [prefix, line, block] = small_block(indented_lines)
    console.log line
    parser(block)
    
s = '''
  YO
    one
    two
    three
  BAR
  '''

big_block = (s) -> ArrayView (IndentationHelper.find_indentation(line) for line in s.split('\n'))    

prefix_line_array = big_block(s)
parser(prefix_line_array)
    
# if exports?
#   # node.js has require mechanism
#   exports.convert = convert
#   exports.convert_widget_package = convert_widget_package
# else
#   # in browser use a more unique name
#   this.pipedent_convert = convert
#   this.convert_widget_package = convert_widget_package
# 
