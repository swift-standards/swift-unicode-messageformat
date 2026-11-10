extension Conformance {

    static let bidi = #"""
        {
          "$schema": "../schemas/v0/tests.schema.json",
          "scenario": "Bidi support",
          "description": "Tests for correct parsing of messages with bidirectional marks and isolates",
          "defaultTestProperties": {
            "bidiIsolation": "default",
            "locale": "en-US"
          },
          "tests": [
            {
              "description": "simple-message    = o [simple-start pattern]",
              "src": "  \u061c Hello world!",
              "exp": "  \u061c Hello world!"
            },
            {
              "description": "complex-message   = o *(declaration o) complex-body o",
              "src": "\u200e .local $x = {1} {{ {$x}}}",
              "exp": " \u20681\u2069"
            },
            {
              "description": "complex-message   = o *(declaration o) complex-body o",
              "src": ".local $x = {1} \u200f {{ {$x}}}",
              "exp": " \u20681\u2069"
            },
            {
              "description": "complex-message   = o *(declaration o) complex-body o",
              "src": ".local $x = {1} {{ {$x}}} \u2066",
              "exp": " \u20681\u2069"
            },
            {
              "description": "input-declaration = input o variable-expression",
              "src": ".input \u2067 {$x :number} {{hello}}",
              "params": [
                {
                  "name": "x",
                  "value": "1"
                }
              ],
              "exp": "hello"
            },
            {
              "description": "local s variable o \"=\" o expression",
              "src": ".local $x \u2068 = \u2069 {1} {{hello}}",
              "exp": "hello"
            },
            {
              "description": "local s variable o \"=\" o expression",
              "src": ".local \u2067 $x = {1} {{hello}}",
              "exp": "hello"
            },
            {
              "description": "local s variable o \"=\" o expression",
              "src": ".local\u2067 $x = {1} {{hello}}",
              "exp": "hello"
            },
            {
              "description": "o \"{{\" pattern \"}}\"",
              "src": "\u2067 {{hello}}",
              "exp": "hello"
            },
            {
              "description": "match-statement s variant *(o variant)",
              "src": ".local $x = {1 :number}\n.match $x\n1 {{one}}\n\u061c * {{other}}",
              "exp": "one"
            },
            {
              "description": "match-statement s variant *(o variant)",
              "src": ".local $x = {1 :number}.match $x \u061c1 {{one}}* {{other}}",
              "exp": "one"
            },
            {
              "description": "match-statement s variant *(o variant)",
              "src": ".local $x = {1 :number}.match $x\u061c1 {{one}}* {{other}}",
              "expErrors": [
                {
                  "type": "syntax-error"
                }
              ]
            },
            {
              "description": "variant = key *(s key) quoted-pattern",
              "src": ".local $x = {1 :number} .local $y = {$x :number}.match $x $y\n1 \u200e 1 {{one}}* * {{other}}",
              "exp": "one"
            },
            {
              "description": "variant = key *(s key) quoted-pattern",
              "src": ".local $x = {1 :number} .local $y = {$x :number}.match $x $y\n1\u200e 1 {{one}}* * {{other}}",
              "exp": "one"
            },
            {
              "description": "literal-expression  = \"{\" o literal [s function] *(s attribute) o \"}\"",
              "src": "{\u200e hello \u200f}",
              "exp": "\u2068hello\u2069"
            },
            {
              "description": "variable-expression = \"{\" o variable [s function] *(s attribute) o \"}\"",
              "src": ".local $x = {1} {{ {\u200e $x \u200f} }}",
              "exp": " \u20681\u2069 "
            },
            {
              "description": "function-expression = \"{\" o function *(s attribute) o \"}\"",
              "src": "{1 \u200e :number \u200f}",
              "exp": "1"
            },
            {
              "description": "markup = \"{\" o \"#\" identifier *(s option) *(s attribute) o [\"/\"] \"}\"",
              "src": "{\u200f #b \u200e }",
              "exp": ""
            },
            {
              "description": "markup = \"{\" o \"/\" identifier *(s option) *(s attribute) o \"}\"",
              "src": "{\u200f /b \u200e }",
              "exp": ""
            },
            {
              "description": "option = identifier o \"=\" o (literal / variable)",
              "src": "{1 :number minimumFractionDigits\u200f=\u200e1 }",
              "exp": "1.0"
            },
            {
              "description": "attribute      = \"@\" identifier [o \"=\" o (literal / variable)]",
              "src": "{1 :number @locale\u200f=\u200een }",
              "exp": "1"
            },
            {
              "description": "name... excludes bidi formatting character U+061C -- this parses as name -> [bidi] name-start *name-char",
              "src": ".local $\u061cfoo = {1} {{ {$\u061cfoo} }}",
              "exp": " \u20681\u2069 "
            },
            {
              "description": "name excludes bidi formatting character U+061C",
              "src": ".local $foo\u061cbar = {2} {{ }}",
              "expErrors": [
                {
                  "type": "syntax-error"
                }
              ]
            },
            {
              "description": "name       = [bidi] name-start *name-char [bidi]",
              "src": ".local $\u200efoo\u200f = {3} {{{$\u200efoo\u200f}}}",
              "exp": "\u20683\u2069"
            },
            {
              "description": "name       = [bidi] name-start *name-char [bidi]",
              "src": ".local $foo = {4} {{{$\u200efoo\u200f}}}",
              "exp": "\u20684\u2069"
            },
            {
              "description": "name       = [bidi] name-start *name-char [bidi]",
              "src": ".local $\u200efoo\u200f = {5} {{{$foo}}}",
              "exp": "\u20685\u2069"
            },
            {
              "description": "name       = [bidi] name-start *name-char [bidi]",
              "src": ".local $foo\u200ebar = {5} {{{$foo\u200ebar}}}",
              "expErrors": [
                {
                  "type": "syntax-error"
                }
              ]
            }
          ]
        }
        """#
}
