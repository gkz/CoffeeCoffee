(function() {
  var ArrayView, IndentationHelper, big_block, small_block;
  ArrayView = function(list, first, last) {
    var index, self;
    if (first == null) {
      first = 0;
    }
    if (last == null) {
      last = list.length;
    }
    index = first;
    return self = {
      shift: function() {
        var obj;
        obj = list[index];
        index += 1;
        return obj;
      },
      peek: function() {
        return list[index];
      },
      len: function() {
        return last - index;
      },
      at: function(offset) {
        return list[index + offset];
      },
      shift_slice: function(how_many) {
        var view;
        view = ArrayView(list, index, index + how_many);
        index += how_many;
        return view;
      },
      shift_while: function(f) {
        var _results;
        _results = [];
        while (self.len() > 0) {
          if (!f(self.peek())) {
            return;
          }
          _results.push(self.shift());
        }
        return _results;
      }
    };
  };
  IndentationHelper = {
    eat_empty_lines: function(indented_lines) {
      return indented_lines.shift_while(function(elem) {
        var line, prefix;
        prefix = elem[0], line = elem[1];
        return line === '';
      });
    },
    number_of_lines_in_indented_block: function(len_prefix, indented_lines) {
      var i, line, new_prefix, _ref;
      i = 0;
      while (i < indented_lines.len()) {
        _ref = indented_lines.at(i), new_prefix = _ref[0], line = _ref[1];
        if (line && new_prefix.length <= len_prefix) {
          break;
        }
        i += 1;
      }
      while (i - 1 >= 0 && indented_lines.at(i - 1)[1] === '') {
        i -= 1;
      }
      return i;
    },
    find_indentation: function(line) {
      var match, prefix, re;
      re = RegExp('( *)(.*)');
      match = re.exec(line);
      prefix = match[1];
      line = match[2];
      if (line === '') {
        prefix = '';
      }
      return [prefix, line];
    }
  };
  small_block = function(indented_lines) {
    var block, block_size, line, prefix, _ref;
    _ref = indented_lines.shift(), prefix = _ref[0], line = _ref[1];
    block_size = IndentationHelper.number_of_lines_in_indented_block(prefix.length, indented_lines);
    block = indented_lines.shift_slice(block_size);
    return [prefix, line, block];
  };
  big_block = function(s) {
    var line;
    return ArrayView((function() {
      var _i, _len, _ref, _results;
      _ref = s.split('\n');
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        line = _ref[_i];
        _results.push(IndentationHelper.find_indentation(line));
      }
      return _results;
    })());
  };
  if (typeof exports !== "undefined" && exports !== null) {
    exports.small_block = small_block;
    exports.big_block = big_block;
  }
}).call(this);
