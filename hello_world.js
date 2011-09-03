(function() {
  var hello_world;
  hello_world = function() {
    var seven, six;
    console.log("hello world");
    six = 6;
    seven = 7;
    return console.log(six * seven);
  };
  hello_world();
}).call(this);
