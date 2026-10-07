#!/usr/bin/env python3
"""Read the plain data tables under src/shared/data from Python, for offline tools.

Handles the subset of Luau the data modules use: `local NAME [: type] = <literal>`, `return <literal>`,
single-line `type` / `export type` declarations, `for ... end` loops (skipped), identifiers that name an
earlier local, string and number keys, nested tables, `:: Type` casts, and `require(...)` or `Vector3.new(...)`
calls (which evaluate to None). Anything fancier should stay out of data tables anyway.

Usage: from luau_tables import load; cfg = load("src/shared/data/Config.luau")
"""
import re
import pathlib

_TOKEN = re.compile(r'''
    (?P<ws>\s+) |
    (?P<comment>--[^\n]*) |
    (?P<str>"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*') |
    (?P<num>-?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?) |
    (?P<name>[A-Za-z_][A-Za-z0-9_]*) |
    (?P<op>::|->|==|~=|<=|>=|[{}\[\]()=,;:.|<>?*+/-])
''', re.VERBOSE)

_BLOCK_OPENERS = {"for", "while", "if", "function"}


def _tokenize(src):
    out = []
    pos = 0
    while pos < len(src):
        m = _TOKEN.match(src, pos)
        if not m:
            raise SyntaxError("unexpected character at %d: %r" % (pos, src[pos:pos + 20]))
        pos = m.end()
        kind = m.lastgroup
        if kind in ("ws", "comment"):
            continue
        out.append((kind, m.group(kind)))
    return out


class _Parser:
    def __init__(self, tokens):
        self.t = tokens
        self.i = 0
        self.env = {}

    def peek(self, k=0):
        j = self.i + k
        return self.t[j] if j < len(self.t) else (None, None)

    def take(self):
        tok = self.peek()
        self.i += 1
        return tok

    def expect(self, value):
        kind, text = self.take()
        if text != value:
            raise SyntaxError("expected %r got %r at token %d" % (value, text, self.i))

    # statements -----------------------------------------------------------
    def run(self):
        result = None
        while self.peek()[0] is not None:
            kind, text = self.peek()
            if text == "local":
                self.take()
                _, name = self.take()
                if self.peek()[1] == ":":
                    self.skip_type_until("=")
                self.expect("=")
                self.env[name] = self.expr()
            elif text == "return":
                self.take()
                result = self.expr()
            elif text in ("type", "export"):
                self.skip_line_decl()
            elif text in _BLOCK_OPENERS:
                self.skip_block()
            else:
                # bare statements we do not model (assignments into existing tables): skip to the next line start
                self.take()
        return result

    def skip_line_decl(self):
        # `type X = ...` / `export type X = ...` : skip until the brace depth returns to 0 and the next
        # statement keyword appears.
        depth = 0
        while True:
            kind, text = self.take()
            if text in ("{", "("):
                depth += 1
            elif text in ("}", ")"):
                depth -= 1
            nxt = self.peek()[1]
            if depth == 0 and nxt in ("local", "return", "type", "export", None) or (depth == 0 and nxt in _BLOCK_OPENERS):
                return

    def skip_block(self):
        depth = 0
        while True:
            kind, text = self.take()
            if text in _BLOCK_OPENERS:
                depth += 1
            elif text == "end":
                depth -= 1
                if depth == 0:
                    return
            if kind is None:
                return

    def skip_type_until(self, stop):
        depth = 0
        while True:
            kind, text = self.peek()
            if kind is None:
                return
            if depth == 0 and text == stop:
                return
            self.take()
            if text in ("{", "(", "<"):
                depth += 1
            elif text in ("}", ")", ">"):
                depth -= 1

    def skip_cast(self):
        # after `::` skip a type until a `,` `;` `}` `)` at depth 0
        depth = 0
        while True:
            kind, text = self.peek()
            if kind is None:
                return
            if depth == 0 and text in (",", ";", "}", ")"):
                return
            self.take()
            if text in ("{", "(", "<"):
                depth += 1
            elif text in ("}", ")", ">"):
                depth -= 1

    # expressions ----------------------------------------------------------
    def expr(self):
        # Constant arithmetic on numbers (17 * 60, 30 * 24 * 3600): * and / bind tighter than + and -.
        value = self.term()
        while self.peek()[1] in ("+", "-") and isinstance(value, (int, float)):
            op = self.take()[1]
            rhs = self.term()
            value = value + rhs if op == "+" else value - rhs
        while self.peek()[1] == "::":
            self.take()
            self.skip_cast()
        return value

    def term(self):
        value = self.primary()
        while self.peek()[1] in ("*", "/") and isinstance(value, (int, float)):
            op = self.take()[1]
            rhs = self.primary()
            value = value * rhs if op == "*" else value / rhs
        return value

    def primary(self):
        kind, text = self.take()
        if text == "{":
            return self.table()
        if kind == "str":
            return bytes(text[1:-1], "utf-8").decode("unicode_escape")
        if kind == "num":
            return float(text) if ("." in text or "e" in text or "E" in text) else int(text)
        if text == "true":
            return True
        if text == "false":
            return False
        if text == "nil":
            return None
        if text == "-" and self.peek()[0] == "num":
            return -self.primary()
        if kind == "name":
            value = self.env.get(text)
            while self.peek()[1] in (".", "("):
                if self.take()[1] == ".":
                    _, field = self.take()
                    value = value.get(field) if isinstance(value, dict) else None
                else:
                    self.skip_call_args()
                    value = None
            return value
        raise SyntaxError("unexpected token %r" % (text,))

    def skip_call_args(self):
        depth = 1
        while depth > 0:
            kind, text = self.take()
            if text == "(":
                depth += 1
            elif text == ")":
                depth -= 1

    def table(self):
        result = {}
        index = 1
        while True:
            kind, text = self.peek()
            if text == "}":
                self.take()
                break
            if text in (",", ";"):
                self.take()
                continue
            if text == "[":
                self.take()
                key = self.expr()
                self.expect("]")
                self.expect("=")
                result[key] = self.expr()
            elif kind == "name" and self.peek(1)[1] == "=":
                self.take()
                self.take()
                result[text] = self.expr()
            else:
                result[index] = self.expr()
                index += 1
        # a pure array becomes a list
        if result and all(isinstance(k, int) for k in result) and sorted(result) == list(range(1, len(result) + 1)):
            return [result[k] for k in sorted(result)]
        return result


def load(path):
    src = pathlib.Path(path).read_text()
    parser = _Parser(_tokenize(src))
    return parser.run()


if __name__ == "__main__":
    import json
    import sys
    for p in sys.argv[1:]:
        print(p)
        print(json.dumps(load(p), indent=1, default=str)[:1500])
