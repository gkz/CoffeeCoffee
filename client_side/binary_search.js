COFFEECOFFEE_PROGRAM = [
  {
    "Assign": {
      "variable": {
        "Value": {
          "base": {
            "Literal": {
              "value": "index"
            }
          },
          "properties": []
        }
      },
      "value": {
        "Code": {
          "params": [
            {
              "Param": {
                "name": {
                  "Literal": {
                    "value": "list"
                  }
                }
              }
            },
            {
              "Param": {
                "name": {
                  "Literal": {
                    "value": "target"
                  }
                }
              }
            }
          ],
          "body": {
            "Block": {
              "expressions": [
                {
                  "Assign": {
                    "variable": {
                      "Value": {
                        "base": {
                          "Arr": {
                            "objects": [
                              {
                                "Value": {
                                  "base": {
                                    "Literal": {
                                      "value": "low"
                                    }
                                  },
                                  "properties": []
                                }
                              },
                              {
                                "Value": {
                                  "base": {
                                    "Literal": {
                                      "value": "high"
                                    }
                                  },
                                  "properties": []
                                }
                              }
                            ]
                          }
                        },
                        "properties": []
                      }
                    },
                    "value": {
                      "Value": {
                        "base": {
                          "Arr": {
                            "objects": [
                              {
                                "Value": {
                                  "base": {
                                    "Literal": {
                                      "value": "0"
                                    }
                                  },
                                  "properties": []
                                }
                              },
                              {
                                "Value": {
                                  "base": {
                                    "Literal": {
                                      "value": "list"
                                    }
                                  },
                                  "properties": [
                                    {
                                      "Access": {
                                        "name": {
                                          "Literal": {
                                            "value": "length",
                                            "asKey": true
                                          }
                                        },
                                        "proto": "",
                                        "soak": false
                                      }
                                    }
                                  ]
                                }
                              }
                            ]
                          }
                        },
                        "properties": []
                      }
                    }
                  }
                },
                {
                  "While": {
                    "condition": {
                      "Op": {
                        "operator": "<",
                        "first": {
                          "Value": {
                            "base": {
                              "Literal": {
                                "value": "low"
                              }
                            },
                            "properties": []
                          }
                        },
                        "second": {
                          "Value": {
                            "base": {
                              "Literal": {
                                "value": "high"
                              }
                            },
                            "properties": []
                          }
                        },
                        "flip": false
                      }
                    },
                    "body": {
                      "Block": {
                        "expressions": [
                          {
                            "Assign": {
                              "variable": {
                                "Value": {
                                  "base": {
                                    "Literal": {
                                      "value": "mid"
                                    }
                                  },
                                  "properties": []
                                }
                              },
                              "value": {
                                "Op": {
                                  "operator": ">>",
                                  "first": {
                                    "Value": {
                                      "base": {
                                        "Parens": {
                                          "body": {
                                            "Block": {
                                              "expressions": [
                                                {
                                                  "Op": {
                                                    "operator": "+",
                                                    "first": {
                                                      "Value": {
                                                        "base": {
                                                          "Literal": {
                                                            "value": "low"
                                                          }
                                                        },
                                                        "properties": []
                                                      }
                                                    },
                                                    "second": {
                                                      "Value": {
                                                        "base": {
                                                          "Literal": {
                                                            "value": "high"
                                                          }
                                                        },
                                                        "properties": []
                                                      }
                                                    },
                                                    "flip": false
                                                  }
                                                }
                                              ]
                                            }
                                          }
                                        }
                                      },
                                      "properties": []
                                    }
                                  },
                                  "second": {
                                    "Value": {
                                      "base": {
                                        "Literal": {
                                          "value": "1"
                                        }
                                      },
                                      "properties": []
                                    }
                                  },
                                  "flip": false
                                }
                              }
                            }
                          },
                          {
                            "Assign": {
                              "variable": {
                                "Value": {
                                  "base": {
                                    "Literal": {
                                      "value": "val"
                                    }
                                  },
                                  "properties": []
                                }
                              },
                              "value": {
                                "Value": {
                                  "base": {
                                    "Literal": {
                                      "value": "list"
                                    }
                                  },
                                  "properties": [
                                    {
                                      "Index": {
                                        "index": {
                                          "Value": {
                                            "base": {
                                              "Literal": {
                                                "value": "mid"
                                              }
                                            },
                                            "properties": []
                                          }
                                        }
                                      }
                                    }
                                  ]
                                }
                              }
                            }
                          },
                          {
                            "If": {
                              "body": {
                                "Block": {
                                  "expressions": [
                                    {
                                      "Return": {
                                        "expression": {
                                          "Value": {
                                            "base": {
                                              "Literal": {
                                                "value": "mid"
                                              }
                                            },
                                            "properties": []
                                          }
                                        }
                                      }
                                    }
                                  ]
                                }
                              },
                              "condition": {
                                "Op": {
                                  "operator": "===",
                                  "first": {
                                    "Value": {
                                      "base": {
                                        "Literal": {
                                          "value": "val"
                                        }
                                      },
                                      "properties": []
                                    }
                                  },
                                  "second": {
                                    "Value": {
                                      "base": {
                                        "Literal": {
                                          "value": "target"
                                        }
                                      },
                                      "properties": []
                                    }
                                  },
                                  "flip": false
                                }
                              },
                              "elseBody": null,
                              "isChain": false
                            }
                          },
                          {
                            "If": {
                              "body": {
                                "Block": {
                                  "expressions": [
                                    {
                                      "Assign": {
                                        "variable": {
                                          "Value": {
                                            "base": {
                                              "Literal": {
                                                "value": "low"
                                              }
                                            },
                                            "properties": []
                                          }
                                        },
                                        "value": {
                                          "Op": {
                                            "operator": "+",
                                            "first": {
                                              "Value": {
                                                "base": {
                                                  "Literal": {
                                                    "value": "mid"
                                                  }
                                                },
                                                "properties": []
                                              }
                                            },
                                            "second": {
                                              "Value": {
                                                "base": {
                                                  "Literal": {
                                                    "value": "1"
                                                  }
                                                },
                                                "properties": []
                                              }
                                            },
                                            "flip": false
                                          }
                                        }
                                      }
                                    }
                                  ]
                                }
                              },
                              "condition": {
                                "Op": {
                                  "operator": "<",
                                  "first": {
                                    "Value": {
                                      "base": {
                                        "Literal": {
                                          "value": "val"
                                        }
                                      },
                                      "properties": []
                                    }
                                  },
                                  "second": {
                                    "Value": {
                                      "base": {
                                        "Literal": {
                                          "value": "target"
                                        }
                                      },
                                      "properties": []
                                    }
                                  },
                                  "flip": false
                                }
                              },
                              "elseBody": {
                                "Block": {
                                  "expressions": [
                                    {
                                      "Assign": {
                                        "variable": {
                                          "Value": {
                                            "base": {
                                              "Literal": {
                                                "value": "high"
                                              }
                                            },
                                            "properties": []
                                          }
                                        },
                                        "value": {
                                          "Value": {
                                            "base": {
                                              "Literal": {
                                                "value": "mid"
                                              }
                                            },
                                            "properties": []
                                          }
                                        }
                                      }
                                    }
                                  ]
                                }
                              },
                              "isChain": false
                            }
                          }
                        ]
                      }
                    }
                  }
                },
                {
                  "Return": {
                    "expression": {
                      "Op": {
                        "operator": "-",
                        "first": {
                          "Value": {
                            "base": {
                              "Literal": {
                                "value": "1"
                              }
                            },
                            "properties": []
                          }
                        },
                        "flip": false
                      }
                    }
                  }
                }
              ]
            }
          },
          "bound": false
        }
      }
    }
  },
  {
    "Call": {
      "args": [
        {
          "Op": {
            "operator": "===",
            "first": {
              "Value": {
                "base": {
                  "Literal": {
                    "value": "2"
                  }
                },
                "properties": []
              }
            },
            "second": {
              "Call": {
                "args": [
                  {
                    "Value": {
                      "base": {
                        "Arr": {
                          "objects": [
                            {
                              "Value": {
                                "base": {
                                  "Literal": {
                                    "value": "10"
                                  }
                                },
                                "properties": []
                              }
                            },
                            {
                              "Value": {
                                "base": {
                                  "Literal": {
                                    "value": "20"
                                  }
                                },
                                "properties": []
                              }
                            },
                            {
                              "Value": {
                                "base": {
                                  "Literal": {
                                    "value": "30"
                                  }
                                },
                                "properties": []
                              }
                            },
                            {
                              "Value": {
                                "base": {
                                  "Literal": {
                                    "value": "40"
                                  }
                                },
                                "properties": []
                              }
                            },
                            {
                              "Value": {
                                "base": {
                                  "Literal": {
                                    "value": "50"
                                  }
                                },
                                "properties": []
                              }
                            }
                          ]
                        }
                      },
                      "properties": []
                    }
                  },
                  {
                    "Value": {
                      "base": {
                        "Literal": {
                          "value": "30"
                        }
                      },
                      "properties": []
                    }
                  }
                ],
                "soak": false,
                "isNew": false,
                "isSuper": false,
                "variable": {
                  "Value": {
                    "base": {
                      "Literal": {
                        "value": "index"
                      }
                    },
                    "properties": []
                  }
                }
              }
            },
            "flip": false
          }
        }
      ],
      "soak": false,
      "isNew": false,
      "isSuper": false,
      "variable": {
        "Value": {
          "base": {
            "Literal": {
              "value": "console"
            }
          },
          "properties": [
            {
              "Access": {
                "name": {
                  "Literal": {
                    "value": "log",
                    "asKey": true
                  }
                },
                "proto": "",
                "soak": false
              }
            }
          ]
        }
      }
    }
  },
  {
    "Call": {
      "args": [
        {
          "Op": {
            "operator": "===",
            "first": {
              "Value": {
                "base": {
                  "Literal": {
                    "value": "4"
                  }
                },
                "properties": []
              }
            },
            "second": {
              "Call": {
                "args": [
                  {
                    "Value": {
                      "base": {
                        "Arr": {
                          "objects": [
                            {
                              "Op": {
                                "operator": "-",
                                "first": {
                                  "Value": {
                                    "base": {
                                      "Literal": {
                                        "value": "97"
                                      }
                                    },
                                    "properties": []
                                  }
                                },
                                "flip": false
                              }
                            },
                            {
                              "Value": {
                                "base": {
                                  "Literal": {
                                    "value": "35"
                                  }
                                },
                                "properties": []
                              }
                            },
                            {
                              "Value": {
                                "base": {
                                  "Literal": {
                                    "value": "67"
                                  }
                                },
                                "properties": []
                              }
                            },
                            {
                              "Value": {
                                "base": {
                                  "Literal": {
                                    "value": "88"
                                  }
                                },
                                "properties": []
                              }
                            },
                            {
                              "Value": {
                                "base": {
                                  "Literal": {
                                    "value": "1200"
                                  }
                                },
                                "properties": []
                              }
                            }
                          ]
                        }
                      },
                      "properties": []
                    }
                  },
                  {
                    "Value": {
                      "base": {
                        "Literal": {
                          "value": "1200"
                        }
                      },
                      "properties": []
                    }
                  }
                ],
                "soak": false,
                "isNew": false,
                "isSuper": false,
                "variable": {
                  "Value": {
                    "base": {
                      "Literal": {
                        "value": "index"
                      }
                    },
                    "properties": []
                  }
                }
              }
            },
            "flip": false
          }
        }
      ],
      "soak": false,
      "isNew": false,
      "isSuper": false,
      "variable": {
        "Value": {
          "base": {
            "Literal": {
              "value": "console"
            }
          },
          "properties": [
            {
              "Access": {
                "name": {
                  "Literal": {
                    "value": "log",
                    "asKey": true
                  }
                },
                "proto": "",
                "soak": false
              }
            }
          ]
        }
      }
    }
  },
  {
    "Call": {
      "args": [
        {
          "Op": {
            "operator": "===",
            "first": {
              "Value": {
                "base": {
                  "Literal": {
                    "value": "0"
                  }
                },
                "properties": []
              }
            },
            "second": {
              "Call": {
                "args": [
                  {
                    "Value": {
                      "base": {
                        "Arr": {
                          "objects": [
                            {
                              "Value": {
                                "base": {
                                  "Literal": {
                                    "value": "0"
                                  }
                                },
                                "properties": []
                              }
                            },
                            {
                              "Value": {
                                "base": {
                                  "Literal": {
                                    "value": "45"
                                  }
                                },
                                "properties": []
                              }
                            },
                            {
                              "Value": {
                                "base": {
                                  "Literal": {
                                    "value": "70"
                                  }
                                },
                                "properties": []
                              }
                            }
                          ]
                        }
                      },
                      "properties": []
                    }
                  },
                  {
                    "Value": {
                      "base": {
                        "Literal": {
                          "value": "0"
                        }
                      },
                      "properties": []
                    }
                  }
                ],
                "soak": false,
                "isNew": false,
                "isSuper": false,
                "variable": {
                  "Value": {
                    "base": {
                      "Literal": {
                        "value": "index"
                      }
                    },
                    "properties": []
                  }
                }
              }
            },
            "flip": false
          }
        }
      ],
      "soak": false,
      "isNew": false,
      "isSuper": false,
      "variable": {
        "Value": {
          "base": {
            "Literal": {
              "value": "console"
            }
          },
          "properties": [
            {
              "Access": {
                "name": {
                  "Literal": {
                    "value": "log",
                    "asKey": true
                  }
                },
                "proto": "",
                "soak": false
              }
            }
          ]
        }
      }
    }
  }
]
