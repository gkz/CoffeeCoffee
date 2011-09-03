(function() {
  var ArrayView, IndentationHelper, data, fn, fs, handle_data, parse, parse_indented_lines, parse_line, pp, stdin;
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
        if (self.len() <= 0) {
          throw "illegal";
        }
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
  parse_line = function(text) {
    var label, match, re, val;
    re = RegExp(/(\S+) (.*)/);
    match = re.exec(text);
    if (match) {
      label = match[1];
      val = match[2];
      re = RegExp(/"(.*)"/);
      match = re.exec(val);
      if (match) {
        val = match[1];
      }
      return {
        kind: label,
        value: val
      };
    } else {
      return text;
    }
  };
  parse_indented_lines = function(obj, indented_lines) {
    var block, block_size, line, node, prefix, text, _results;
    _results = [];
    while (indented_lines.len() > 0) {
      line = indented_lines.shift();
      if (line == null) {
        break;
      }
      prefix = line[0], text = line[1];
      block_size = IndentationHelper.number_of_lines_in_indented_block(prefix.length, indented_lines);
      _results.push(block_size > 0 ? (block = indented_lines.shift_slice(block_size), node = [], parse_indented_lines(node, block), obj.push({
        parent: parse_line(text),
        children: node
      })) : obj.push(parse_line(text)));
    }
    return _results;
  };
  parse = function(data) {
    var indented_lines, line, lines, root;
    lines = data.split('\n');
    lines = (function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = lines.length; _i < _len; _i++) {
        line = lines[_i];
        if (line.trim() !== '') {
          _results.push(line);
        }
      }
      return _results;
    })();
    indented_lines = (function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = lines.length; _i < _len; _i++) {
        line = lines[_i];
        _results.push(IndentationHelper.find_indentation(line));
      }
      return _results;
    })();
    indented_lines = ArrayView(indented_lines);
    root = [];
    parse_indented_lines(root, indented_lines);
    return root;
  };
  pp = function(data) {
    return console.log(JSON.stringify(data, null, "  "));
  };
  handle_data = function(data) {
    return pp(parse(data));
  };
  fs = require('fs');
  fn = process.argv[2];
  if (fn) {
    data = fs.readFileSync(fn).toString();
    handle_data(data);
  } else {
    data = '';
    stdin = process.openStdin();
    stdin.on('data', function(buffer) {
      if (buffer) {
        return data += buffer.toString();
      }
    });
    stdin.on('end', function() {
      return handle_data(data);
    });
  }
}).call(this);
