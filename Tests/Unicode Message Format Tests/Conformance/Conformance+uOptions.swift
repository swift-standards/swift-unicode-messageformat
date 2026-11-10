extension Conformance {

    static let uOptions = #"""
        {
          "$schema": "../schemas/v0/tests.schema.json",
          "scenario": "u: Options",
          "description": "Common options affecting the function context",
          "defaultTestProperties": {
            "bidiIsolation": "default",
            "locale": "en-US"
          },
          "tests": [
            {
              "tags": [
                "u:id"
              ],
              "src": "{#tag u:id=x}content{/ns:tag u:id=x}",
              "exp": "content",
              "expParts": [
                {
                  "type": "markup",
                  "kind": "open",
                  "id": "x",
                  "name": "tag"
                },
                {
                  "type": "text",
                  "value": "content"
                },
                {
                  "type": "markup",
                  "kind": "close",
                  "id": "x",
                  "name": "ns:tag"
                }
              ]
            },
            {
              "tags": [
                "u:dir"
              ],
              "src": "{#tag u:dir=rtl}content{/ns:tag}",
              "exp": "content",
              "expErrors": [
                {
                  "type": "bad-option"
                }
              ],
              "expParts": [
                {
                  "type": "markup",
                  "kind": "open",
                  "name": "tag"
                },
                {
                  "type": "text",
                  "value": "content"
                },
                {
                  "type": "markup",
                  "kind": "close",
                  "name": "ns:tag"
                }
              ]
            },
            {
              "tags": [
                "u:dir",
                "u:id"
              ],
              "src": "hello {world :string u:dir=ltr u:id=foo}",
              "exp": "hello \u2066world\u2069",
              "expParts": [
                {
                  "type": "text",
                  "value": "hello "
                },
                {
                  "type": "bidiIsolation",
                  "value": "\u2066"
                },
                {
                  "type": "string",
                  "dir": "ltr",
                  "id": "foo",
                  "value": "world"
                },
                {
                  "type": "bidiIsolation",
                  "value": "\u2069"
                }
              ]
            },
            {
              "tags": [
                "u:dir"
              ],
              "src": "hello {world :string u:dir=rtl}",
              "exp": "hello \u2067world\u2069",
              "expParts": [
                {
                  "type": "text",
                  "value": "hello "
                },
                {
                  "type": "bidiIsolation",
                  "value": "\u2067"
                },
                {
                  "type": "string",
                  "dir": "rtl",
                  "locale": "en-US",
                  "value": "world"
                },
                {
                  "type": "bidiIsolation",
                  "value": "\u2069"
                }
              ]
            },
            {
              "tags": [
                "u:dir"
              ],
              "src": "hello {world :string u:dir=auto}",
              "exp": "hello \u2068world\u2069",
              "expParts": [
                {
                  "type": "text",
                  "value": "hello "
                },
                {
                  "type": "bidiIsolation",
                  "value": "\u2068"
                },
                {
                  "type": "string",
                  "locale": "en-US",
                  "value": "world"
                },
                {
                  "type": "bidiIsolation",
                  "value": "\u2069"
                }
              ]
            },
            {
              "tags": [
                "u:dir",
                "u:id"
              ],
              "src": ".local $world = {world :string u:dir=ltr u:id=foo} {{hello {$world}}}",
              "exp": "hello \u2066world\u2069",
              "expParts": [
                {
                  "type": "text",
                  "value": "hello "
                },
                {
                  "type": "bidiIsolation",
                  "value": "\u2066"
                },
                {
                  "type": "string",
                  "dir": "ltr",
                  "id": "foo",
                  "value": "world"
                },
                {
                  "type": "bidiIsolation",
                  "value": "\u2069"
                }
              ]
            },
            {
              "tags": [
                "u:dir"
              ],
              "locale": "ar",
              "src": "\u0623\u0647\u0644\u0627\u064b {\u0628\u0627\u0644\u0639\u0627\u0644\u0645 :string u:dir=rtl}",
              "exp": "\u0623\u0647\u0644\u0627\u064b \u2067\u0628\u0627\u0644\u0639\u0627\u0644\u0645\u2069"
            },
            {
              "tags": [
                "u:dir"
              ],
              "locale": "ar",
              "src": "\u0623\u0647\u0644\u0627\u064b {\u0628\u0627\u0644\u0639\u0627\u0644\u0645 :string u:dir=auto}",
              "exp": "\u0623\u0647\u0644\u0627\u064b \u2068\u0628\u0627\u0644\u0639\u0627\u0644\u0645\u2069"
            },
            {
              "tags": [
                "u:dir"
              ],
              "locale": "ar",
              "src": "\u0623\u0647\u0644\u0627\u064b {world :string u:dir=ltr}",
              "exp": "\u0623\u0647\u0644\u0627\u064b \u2066world\u2069"
            },
            {
              "locale": "ar",
              "src": "\u0623\u0647\u0644\u0627\u064b {\u0628\u0627\u0644\u0639\u0627\u0644\u0645 :string}",
              "exp": "\u0623\u0647\u0644\u0627\u064b \u2068\u0628\u0627\u0644\u0639\u0627\u0644\u0645\u2069"
            }
          ]
        }
        """#
}
