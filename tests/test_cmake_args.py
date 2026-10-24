import os
import subprocess
import unittest
from pathlib import Path

PARSER = Path(__file__).resolve().parents[1] / 'parse-cmake-args.sh'


def parse(value):
    return subprocess.run(['bash', '-euo', 'pipefail', '-c', 'source "$1"; parse_cmake_args "$2"; for arg in "${EXTRA_ARGS[@]}"; do printf "%s\\0" "$arg"; done', 'test', str(PARSER), value], capture_output=True)


class ArgumentTests(unittest.TestCase):
    def assertWords(self, source, expected):
        result = parse(source)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, b''.join(word.encode() + b'\0' for word in expected))

    def test_spaces_and_preset(self):
        self.assertWords('--preset "Custom Debug" -DNAME="hello world"', ['--preset', 'Custom Debug', '-DNAME=hello world'])

    def test_quotes_and_empty_words(self):
        self.assertWords("'' \"\" -DNAME='one two' pre\"mid dle\"post", ['', '', '-DNAME=one two', 'premid dlepost'])

    def test_backslashes(self):
        self.assertWords(r'a\ b "C:\path\file" "a\"b"', ['a b', r'C:\path\file', 'a"b'])

    def test_shell_expressions_are_literal(self):
        self.assertWords("'$(touch /tmp/not-run)' '$HOME' '*' ';' '`id`'", ['$(touch /tmp/not-run)', '$HOME', '*', ';', '`id`'])

    def test_multiline_whitespace(self):
        self.assertWords('a\tb\nc', ['a', 'b', 'c'])

    def test_empty(self):
        self.assertWords('', [])

    def test_malformed_input_fails(self):
        for value in ["'unterminated", '"unterminated', 'trailing\\']:
            self.assertNotEqual(parse(value).returncode, 0)


if __name__ == '__main__':
    unittest.main()
