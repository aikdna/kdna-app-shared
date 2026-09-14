#!/usr/bin/env python3
"""Check public names, exact native inputs, dependency pins and CI coverage."""
import ast
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
FORBIDDEN_HASHES = {'32a183bfe17c2d785b66d5a328402623bc5ab674c86bd8ad29905a05c1a6319c', '068c8b48752eba18baf46af3324f3ffb9306457c54b6624fade5792109af536b', '5f60fde8e355d8d81ffbb60095c2bb25a52f723940c4c01a77473badd3faa8cd', '5de109ce9d5d074259ce2b3757d33b0a68afaaf88ca599ed77d78a46797cfdb0', '3ce236400925c24e9e5416bdc69abe5427b3183e2abe6f848b297334cfdeaa25', '7206c17a81fdc22e097e4b78d33fee460804b0c5bf4c0e461adc7114d16d85ed', '5a02d80676cf1acf987c1787c1201a7648f8cc606b6014a29ecda4eed68e6315', 'a1f44465ac220babc075de0f4489642440192302357a2fe90265fb2ad2c376e5', '0f89e837194f291beef89dcde345233adf1443f61763f05ee5cef5ad12d44c0a', '61e79d887fa6b41acfebaeee47c2ba816bc76c892b1f72a3c2ba3f34900a22f8', '4c94af7ca105abc9c4e2c9c7dce3b778b4bde7e6445c9e68101a0d9eb59f97bd', 'ad832a18658e09393a42c9966b94625c82effd30dfe8bc0a6d8c000fa8056222', 'e2f6321a5972a38700c02f6b4344c8b9deb52b523fceb7ce25a255fb44f0917c'}
TOKEN_PATTERN = re.compile(r"@[a-z][a-z0-9_-]*/[a-z][a-z0-9_-]*|[a-z][a-z0-9_-]*/[a-z][a-z0-9_-]*|[a-z][a-z0-9_-]*", re.I)
INTERNAL_ID = re.compile(r"\b[pP][dD]\d+\b")
GENERATION = re.compile(r"(?<![A-Za-z0-9])[vV]\d+(?!\d|\.\d)")
MACHINE_PATH = re.compile(r"/" + r"Users/(?!<user>/|you/|username/)[^/\s]+/|/private/" + r"tmp/kdna|/home/" + r"runner/work/[^\s]+|[A-Za-z]:\\Users\\[^\\\s]+\\", re.I)
# Start at the full local-part boundary to avoid quadratic retries on long text.
PLACEHOLDER_IDENTITY = re.compile(r"(?<![\w.+-])[\w.+-]+@[\w.-]+\.invalid\b")
STRICT_UTF8_SUFFIXES = {'.swift', '.py', '.json', '.md', '.yml', '.yaml', '.sh', '.txt', '.resolved'}
CORE_URL = 'https://github.com/aikdna/kdna-core-swift.git'


def digest(data):
    return hashlib.sha256(data).hexdigest()


def collect(root=ROOT):
    paths = subprocess.check_output(['git', 'ls-files', '--cached', '--others', '--exclude-standard', '-z'], cwd=root).split(b'\0')
    return {p.decode(): (root / p.decode()).read_bytes() for p in paths if p and (root / p.decode()).is_file()}


def third_party_spans(path, text):
    spans = []
    if Path(path).name == 'Package.swift' or path == 'scripts/verify_native.py':
        spans.extend(m.span() for m in re.finditer(r'\.(?:macOS|iOS)\(\.v\d+(?:_\d+)*\)', text))
    if path == '.github/workflows/stale.yml' or path == 'retired/.github/workflows/stale.yml':
        spans.extend(m.span() for m in re.finditer(r'uses:\s*actions/stale@v\d+', text))
    return spans


def surface_errors(files):
    errors = []
    def require(condition, message):
        if not condition: errors.append(message)
    def read(path):
        require(path in files, f'missing public input: {path}')
        return files.get(path, b'').decode('utf8', errors='replace')
    def data(path):
        try: return json.loads(read(path))
        except ValueError:
            errors.append(f'invalid JSON: {path}')
            return {}
    for path, raw in files.items():
        require(Path(path).name not in {'AGENTS.md', 'WORKLOG.md'}, f'private coordination file: {path}')
        require(not INTERNAL_ID.search(path), f'internal identifier in path: {path}')
        require(not GENERATION.search(path), f'generation label in path: {path}')
        for token in TOKEN_PATTERN.findall(path):
            require(digest(token.lower().encode()) not in FORBIDDEN_HASHES, f'private name in path: {path}')
        if Path(path).suffix in STRICT_UTF8_SUFFIXES:
            try: text = raw.decode('utf8')
            except UnicodeError:
                errors.append(f'invalid UTF-8: {path}')
                continue
        else:
            if b'\0' in raw: continue
            # An arbitrary suffix is not a privacy exemption. Preserve readable
            # portions of non-NUL data even when another byte is not UTF-8.
            text = raw.decode('utf8', errors='replace')
        require(not INTERNAL_ID.search(text), f'internal identifier in text: {path}')
        path_text = text
        if path == 'retired/scripts/check_public_surface.py':
            original_path_rule = r"/" + r"Users/(?!<user>/|you/|username/)[^/\s]+/|/private/" + r"tmp/kdna"
            path_text = text.replace(original_path_rule, '')
        require(not MACHINE_PATH.search(path_text), f'private machine path: {path}')
        require(not PLACEHOLDER_IDENTITY.search(text), f'placeholder identity: {path}')
        for token in TOKEN_PATTERN.findall(text):
            require(digest(token.lower().encode()) not in FORBIDDEN_HASHES, f'private name in text: {path}')
        spans = third_party_spans(path, text)
        for match in GENERATION.finditer(text):
            require(any(start <= match.start() and match.end() <= end for start, end in spans), f'owned generation label: {path}:{text[:match.start()].count(chr(10))+1}')

    inputs = data('public-inputs.json').get('files', [])
    expected = [row['path'] for row in inputs]
    actual = {path for path in files if path.startswith(('Sources/', 'Tests/')) or path == 'public-contract-binding.json'}
    require(len(expected) == len(set(expected)) and set(expected) == actual, 'frozen native input inventory differs')
    for row in inputs:
        require(row['path'] in files and digest(files[row['path']]) == row['sha256'], f'frozen native bytes differ: {row["path"]}')
    history = data('public-history.json').get('original_files', [])
    require(bool(history), 'public history must retain the original inventory')
    for row in history:
        name = row['preserved_at']
        require(name in files and digest(files[name]) == row['sha256'], f'historical bytes differ: {name}')

    old_gate = read('retired/scripts/check_public_surface.py')
    original_hashes = set()
    original_pattern = None
    for node in ast.parse(old_gate).body:
        if isinstance(node, ast.Assign):
            names = [target.id for target in node.targets if isinstance(target, ast.Name)]
            if 'FORBIDDEN_HASHES' in names: original_hashes = ast.literal_eval(node.value)
            if 'TOKEN_PATTERN' in names: original_pattern = ast.literal_eval(node.value.args[0])
    require(bool(original_hashes) and original_hashes <= FORBIDDEN_HASHES and original_pattern == TOKEN_PATTERN.pattern and bool(TOKEN_PATTERN.flags & re.I), 'original private-name patterns must stay covered')

    package = read('Package.swift')
    pin = re.search(r'\.package\(\s*url:\s*"' + re.escape(CORE_URL) + r'",\s*revision:\s*"([0-9a-f]{40})"\s*\)', package)
    require(pin is not None, 'public package must pin the exact remote Core revision')
    require('path: "../kdna-core-swift"' not in package, 'public package must not require a sibling Core checkout')
    require('exclude: ["AuthorizationPresentation.swift"]' in package and 'exclude: ["AuthorizationPresentationTests.swift"]' in package, 'retired authorization surfaces must stay excluded')
    require('.copy("Fixtures")' in package, 'all fixture resources must stay bundled')
    lock = data('Package.resolved').get('pins', [])
    require(len(lock) == 1 and lock[0].get('identity') == 'kdna-core-swift' and lock[0].get('location') == CORE_URL and lock[0].get('kind') == 'remoteSourceControl' and pin is not None and lock[0].get('state', {}).get('revision') == pin.group(1), 'resolved Core input must match the exact remote dependency')
    require('path: "../kdna-core-swift"' not in read('README.md'), 'installation docs must use the public dependency')
    require('restored source inspection' not in read('Docs/AUTHORIZATION_PRESENTATION.md'), 'contract docs must not expose private consumer inventory')

    ci = read('.github/workflows/ci.yml')
    require(re.search(r'^  build:\s*$', ci, re.M) is not None, 'required build context must remain unchanged')
    for command in ['python3 scripts/check_public_surface.py', 'python3 scripts/test_public_surface.py', 'python3 scripts/verify_native.py']:
        require(re.search(r'^\s+run:\s*' + re.escape(command) + r'(?:\s|$)', ci, re.M) is not None, f'CI must execute {command}')
    require(' --ios' in ci, 'CI must retain generic iOS compilation')
    for ref in re.findall(r'\buses:\s*[^@\s]+@([^\s#]+)', ci):
        require(re.fullmatch(r'[0-9a-f]{40}', ref), 'CI action refs must be immutable')
    native = read('scripts/verify_native.py')
    try:
        commands=[]
        for node in ast.walk(ast.parse(native)):
            if isinstance(node, ast.Call) and isinstance(node.func, ast.Name) and node.func.id=='run' and node.args and isinstance(node.args[0], ast.List):
                commands.append([x.value for x in node.args[0].elts if isinstance(x, ast.Constant) and isinstance(x.value, str)])
        for prefix in [['swift','build'], ['swift','test'], ['swift','run'], ['xcodebuild','-quiet','-scheme','kdna-app-shared']]:
            require(any(command[:len(prefix)]==prefix for command in commands), f'native verification must execute {" ".join(prefix)}')
        require(not any('--filter' in command or '--skip' in command for command in commands), 'native verification must run the complete suite')
        require("['debug', 'release']" in native, 'consumer must run in debug and release')
        require('check=True' in native, 'native command failures must propagate')
        require('result.returncode == 0' in native and 'cannot find type' in native, 'retired API compilation must fail for missing types')
        require('import KDNAAppShared' in native and '@testable' not in native and 'precondition(object[key] == nil)' in native, 'consumer must check the public no-body-copy boundary')
    except SyntaxError: errors.append('native runner must be valid Python')
    return errors


def main():
    errors = surface_errors(collect())
    if errors:
        print('\n'.join(errors), file=sys.stderr)
        return 1
    print('Exact public inputs, remote dependency, preserved history and native CI verified.')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
