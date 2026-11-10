extension Conformance {

    static let string = #"""
        {
          "$schema": "../../schemas/v0/tests.schema.json",
          "scenario": "String function",
          "description": "The built-in formatter for strings.",
          "defaultTestProperties": {
            "bidiIsolation": "none",
            "locale": "en-US"
          },
          "tests": [
            {
              "src": ".input {$foo :string} .match $foo |1| {{one}} * {{other}}",
              "params": [
                {
                  "name": "foo",
                  "value": "1"
                }
              ],
              "exp": "one"
            },
            {
              "src": ".input {$foo :string} .match $foo 1 {{one}} * {{other}}",
              "params": [
                {
                  "name": "foo",
                  "value": "1"
                }
              ],
              "exp": "one"
            },
            {
              "src": ".input {$foo :string} .match $foo 1 {{one}} * {{other}}",
              "params": [
                {
                  "name": "foo",
                  "value": "2"
                }
              ],
              "exp": "other"
            },
            {
              "src": ".input {$foo :string} .match $foo 1 {{one}} * {{other}}",
              "exp": "other",
              "expErrors": [
                {
                  "type": "unresolved-variable"
                }
              ]
            },
            {
              "description": "NFC: keys are normalized (unquoted)",
              "src": ".local $x = {\u1e0a\u0323 :string} .match $x \u1e0a\u0323 {{Not normalized}} \u1e0c\u0307 {{Normalized}} * {{Wrong}}",
              "expErrors": [
                {
                  "type": "duplicate-variant"
                }
              ]
            },
            {
              "description": "NFC: keys are normalized (quoted)",
              "src": ".local $x = {\u1e0a\u0323 :string} .match $x |\u1e0a\u0323| {{Not normalized}} |\u1e0c\u0307| {{Normalized}} * {{Wrong}}",
              "expErrors": [
                {
                  "type": "duplicate-variant"
                }
              ]
            },
            {
              "description": "NFC: keys are normalized (mixed)",
              "src": ".local $x = {\u1e0a\u0323 :string} .match $x \u1e0a\u0323 {{Not normalized}} |\u1e0c\u0307| {{Normalized}} * {{Wrong}}",
              "expErrors": [
                {
                  "type": "duplicate-variant"
                }
              ]
            },
            {
              "description": "NFC: :string normalizes the comparison value (un-normalized selector, normalized key)",
              "src": ".local $x = {\u1e0a\u0323 :string} .match $x \u1e0c\u0307 {{Right}} * {{Wrong}}",
              "exp": "Right"
            },
            {
              "description": "NFC: keys are normalized (normalized selector, un-normalized key)",
              "src": ".local $x = {\u1e0c\u0307 :string} .match $x \u1e0a\u0323 {{Right}} * {{Wrong}}",
              "exp": "Right"
            }
          ]
        }
        """#
}
