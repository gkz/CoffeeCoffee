nodes_to_json.coffee helps turn the --nodes output from "coffee" into a JSON data structure that you can easily walk.

It is probably best demonstrated with a small program.

Here is a pretty simple program:

```
# This is just a small program to test with.
hello_world = ->
  console.log "hello world"
  six = 6
  seven = 7
  console.log six * seven
hello_world()
```

Using the --nodes option, you can see the AST, but you can't walk it easily.

```
~/WORKSPACE/CoffeeNodesToJson > coffee -n hello_world.coffee 
Block
  Assign
    Value "hello_world"
    Code
      Block
        Call
          Value "console"
            Access "log"
          Value ""hello world""
        Assign
          Value "six"
          Value "6"
        Assign
          Value "seven"
          Value "7"
        Call
          Value "console"
            Access "log"
          Op *
            Value "six"
            Value "seven"
  Call
    Value "hello_world"
```

If you run it through nodes_to_json.coffee, you get a data structure that you can walk.


```
~/WORKSPACE/CoffeeNodesToJson > coffee -n hello_world.coffee | coffee nodes_to_json.coffee 
[
  {
    "parent": "Block",
    "children": [
      {
        "parent": "Assign",
        "children": [
          {
            "kind": "Value",
            "value": "hello_world"
          },
          {
            "parent": "Code",
            "children": [
              {
                "parent": "Block",
                "children": [
                  {
                    "parent": "Call",
                    "children": [
                      {
                        "parent": {
                          "kind": "Value",
                          "value": "console"
                        },
                        "children": [
                          {
                            "kind": "Access",
                            "value": "log"
                          }
                        ]
                      },
                      {
                        "kind": "Value",
                        "value": "\"hello world\""
                      }
                    ]
                  },
                  {
                    "parent": "Assign",
                    "children": [
                      {
                        "kind": "Value",
                        "value": "six"
                      },
                      {
                        "kind": "Value",
                        "value": "6"
                      }
                    ]
                  },
                  {
                    "parent": "Assign",
                    "children": [
                      {
                        "kind": "Value",
                        "value": "seven"
                      },
                      {
                        "kind": "Value",
                        "value": "7"
                      }
                    ]
                  },
                  {
                    "parent": "Call",
                    "children": [
                      {
                        "parent": {
                          "kind": "Value",
                          "value": "console"
                        },
                        "children": [
                          {
                            "kind": "Access",
                            "value": "log"
                          }
                        ]
                      },
                      {
                        "parent": {
                          "kind": "Op",
                          "value": "*"
                        },
                        "children": [
                          {
                            "kind": "Value",
                            "value": "six"
                          },
                          {
                            "kind": "Value",
                            "value": "seven"
                          }
                        ]
                      }
                    ]
                  }
                ]
              }
            ]
          }
        ]
      },
      {
        "parent": "Call",
        "children": [
          {
            "kind": "Value",
            "value": "hello_world"
          }
        ]
      }
    ]
  }
]

```
