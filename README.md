nodes_to_json.coffee uses the CS compiler to generate a JSON representation of the AST.

(Aside: This distro also includes runtime.coffee, which is very experimental at this point.)

It requires the coffee-script lib, so make sure it is in your path:

```
~/WORKSPACE/CoffeeNodesToJson > ls -l lib
lrwxr-xr-x  1 steve  staff  21 Sep 11 12:54 lib -> ../coffee-script/lib/
```

We'll use a small program to show nodes_to_json.coffee in action.

```
# This is just a small program to test with.
hello_world = ->
  console.log "hello world"
  six = 6
  seven = 7
  console.log six * seven
hello_world()
```

If you run it through nodes_to_json.coffee, you get a data structure that you can walk.  Think about using this for code visualizers, linters, etc.


```
~/WORKSPACE/CoffeeNodesToJson > coffee nodes_to_json.coffee hello_world.coffee 
[
  [
    "Assign",
    {
      "variable": {
        "base": {
          "value": "hello_world"
        },
        "properties": []
      },
      "value": {
        "params": [],
        "body": {
          "expressions": [
            {
              "args": [
                {
                  "base": {
                    "value": "\"hello world\""
                  },
                  "properties": []
                }
              ],
              "soak": false,
              "isNew": false,
              "isSuper": false,
              "variable": {
                "base": {
                  "value": "console"
                },
                "properties": [
                  {
                    "name": {
                      "value": "log",
                      "asKey": true
                    },
                    "proto": "",
                    "soak": false
                  }
                ]
              }
            },
            {
              "variable": {
                "base": {
                  "value": "six"
                },
                "properties": []
              },
              "value": {
                "base": {
                  "value": "6"
                },
                "properties": []
              }
            },
            {
              "variable": {
                "base": {
                  "value": "seven"
                },
                "properties": []
              },
              "value": {
                "base": {
                  "value": "7"
                },
                "properties": []
              }
            },
            {
              "args": [
                {
                  "operator": "*",
                  "first": {
                    "base": {
                      "value": "six"
                    },
                    "properties": []
                  },
                  "second": {
                    "base": {
                      "value": "seven"
                    },
                    "properties": []
                  },
                  "flip": false
                }
              ],
              "soak": false,
              "isNew": false,
              "isSuper": false,
              "variable": {
                "base": {
                  "value": "console"
                },
                "properties": [
                  {
                    "name": {
                      "value": "log",
                      "asKey": true
                    },
                    "proto": "",
                    "soak": false
                  }
                ]
              }
            }
          ]
        },
        "bound": false
      }
    }
  ],
  [
    "Call",
    {
      "args": [],
      "soak": false,
      "isNew": false,
      "isSuper": false,
      "variable": {
        "base": {
          "value": "hello_world"
        },
        "properties": []
      }
    }
  ]
]

```
