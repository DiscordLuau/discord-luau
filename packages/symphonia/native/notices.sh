#!/usr/bin/env bash
# Regenerates THIRD_PARTY_NOTICES.md beside this script from `cargo metadata`: every crate linked into libsymphonia
# with its version, licence and repository, the crates used only to build it, and the licence text of every linked
# crate whose licence needs its notice shipped with the binary, read from that crate's licence file in the cargo
# registry. Dev-dependencies are left out. The output is sorted and holds no local paths, so it is the same on every
# machine for the same Cargo.lock. Needs Rust (rustup) and python3. Usage: bash packages/symphonia/native/notices.sh
set -euo pipefail

crateDirectory=$(realpath "$(dirname "${BASH_SOURCE[0]}")")

read -r -d '' program <<'PYTHON' || true
import json
import os
import re
import sys

NO_NOTICE_LICENCES = ["0BSD", "MIT-0", "Unlicense", "CC0-1.0", "Zlib", "BSL-1.0"]
CRATES_IO_SOURCES = ["registry+https://github.com/rust-lang/crates.io-index", "sparse+https://index.crates.io/"]
MIT_TEMPLATE = """Copyright (c) {holders}

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE."""


def fail(message):
    sys.exit(f"notices.sh: {message}")


def licence_options(package):
    expression = (package.get("license") or "").replace("/", " OR ").strip()

    if not expression:
        fail(f"{package['name']} {package['version']} states no licence; add a rule for it to notices.sh")

    if "(" in expression or " AND " in expression or " WITH " in expression:
        fail(f"{package['name']} {package['version']} has the compound licence {expression!r}; add a rule for it to notices.sh")

    return [option.strip() for option in expression.split(" OR ")]


def read_text(path):
    with open(path, "rb") as file:
        text = file.read().decode("utf-8", errors="replace")

    return text.replace("\r\n", "\n").replace("\r", "\n").strip("\n")


def licence_files(package):
    crate_directory = os.path.dirname(package["manifest_path"])
    names = sorted(name for name in os.listdir(crate_directory) if re.match(r"(?i)^(licen[cs]e|copying)", name))

    if package.get("license_file"):
        names.insert(0, package["license_file"])

    return [(name, read_text(os.path.join(crate_directory, name))) for name in names if os.path.isfile(os.path.join(crate_directory, name))]


def mit_notice(package):
    files = licence_files(package)
    named = [text for name, text in files if "mit" in name.lower()]
    granted = [text for name, text in files if "Permission is hereby granted" in text]

    if named:
        return named[0], None

    if granted:
        return granted[0], None

    holders = ", ".join(re.sub(r"\s*<[^>]*>", "", author).strip() for author in package.get("authors") or [])

    if not holders:
        fail(f"{package['name']} {package['version']} ships no MIT licence file and names no authors; add its notice to notices.sh")

    note = f"{package['name']} {package['version']} ships no MIT licence file. Its Cargo.toml declares MIT, so this is the standard MIT text with the authors its Cargo.toml names."

    return MIT_TEMPLATE.format(holders=holders), note


def apache_notice(package):
    files = licence_files(package)
    licences = [text for name, text in files if "apache" in name.lower() or "Apache License" in text]
    crate_directory = os.path.dirname(package["manifest_path"])
    notices = [read_text(os.path.join(crate_directory, name)) for name in sorted(os.listdir(crate_directory)) if re.match(r"(?i)^notice", name)]

    if not licences:
        fail(f"{package['name']} {package['version']} ships no Apache-2.0 licence file; add its notice to notices.sh")

    return "\n\n".join([licences[0], *notices]), None


def choose_licence(package):
    options = licence_options(package)

    if options == ["MPL-2.0"]:
        if package.get("source") not in CRATES_IO_SOURCES:
            fail(f"{package['name']} is MPL-2.0 but does not come from crates.io; the notice says its source is unmodified there, so check that and update notices.sh")

        return "MPL-2.0", None, None

    for licence in NO_NOTICE_LICENCES:
        if licence in options:
            return licence, None, None

    if "MIT" in options:
        return "MIT", *mit_notice(package)

    if "Apache-2.0" in options:
        return "Apache-2.0", *apache_notice(package)

    fail(f"{package['name']} {package['version']} has the licence {package['license']!r}, which notices.sh has no rule for")


def walk(root, nodes, packages, kinds):
    seen = set()
    pending = [root]

    while pending:
        identifier = pending.pop()

        for dependency in nodes[identifier]["deps"]:
            dependency_kinds = {kind["kind"] for kind in dependency["dep_kinds"]}
            child = dependency["pkg"]
            is_proc_macro = any("proc-macro" in target["kind"] for target in packages[child]["targets"])

            if not dependency_kinds & kinds or child in seen:
                continue

            if kinds == {None} and is_proc_macro:
                continue

            seen.add(child)
            pending.append(child)

    return seen


def cell(value):
    return (value or "-").replace("|", "\\|")


def fence(text):
    longest = max((len(run) for run in re.findall(r"`+", text)), default=0)

    return "`" * max(3, longest + 1)


def ordered(identifiers, packages):
    return sorted((packages[identifier] for identifier in identifiers), key=lambda package: (package["name"], package["version"]))


metadata = json.load(sys.stdin)
packages = {package["id"]: package for package in metadata["packages"]}
nodes = {node["id"]: node for node in metadata["resolve"]["nodes"]}
root = metadata["resolve"]["root"]
root_package = packages[root]
linked = walk(root, nodes, packages, {None})
built = walk(root, nodes, packages, {None, "build"}) - linked
linked_rows = []
mpl_packages = []
notice_groups = {}

for package in ordered(linked, packages):
    licence, text, note = choose_licence(package)
    linked_rows.append((package, licence))

    if licence == "MPL-2.0":
        mpl_packages.append(package)

    if text is not None:
        group = notice_groups.setdefault(text, {"packages": [], "notes": []})
        group["packages"].append(package)

        if note:
            group["notes"].append(note)

lines = [
    "# Third-party notices",
    "",
    f"`libsymphonia`, the native library in `packages/symphonia/binaries/`, is built from the `{root_package['name']}` crate in this folder, which is MIT like the rest of discord-luau. It statically links the Rust crates below.",
    "",
    "`notices.sh` generates this file from `cargo metadata` over the release dependency graph, without dev-dependencies. Run `bash notices.sh` here after changing `Cargo.toml` or `Cargo.lock`, rather than editing this file.",
    "",
    "## Crates in the library",
    "",
    "| Crate | Version | Licence | Used under | Repository |",
    "|---|---|---|---|---|",
]

for package, licence in linked_rows:
    lines.append(f"| {cell(package['name'])} | {cell(package['version'])} | {cell(package.get('license'))} | {licence} | {cell(package.get('repository'))} |")

lines += [
    "",
    "The library also contains the Rust standard library, compiled by the toolchain that `rust-toolchain.toml` pins. It is MIT OR Apache-2.0, and its notices are in that toolchain's `share/doc/rust/COPYRIGHT-library.html` and at https://github.com/rust-lang/rust.",
    "",
    "## Crates used only to build it",
    "",
    "These are procedural macros and build scripts. They run while the library compiles, and none of their code is in it.",
    "",
    "| Crate | Version | Licence | Repository |",
    "|---|---|---|---|",
]

for package in ordered(built, packages):
    lines.append(f"| {cell(package['name'])} | {cell(package['version'])} | {cell(package.get('license'))} | {cell(package.get('repository'))} |")

lines += [
    "",
    "## Licence choices",
    "",
    "- A crate offered under a licence that needs no notice in a binary (" + ", ".join(NO_NOTICE_LICENCES) + ") is used under that licence and listed above only.",
    "- Otherwise, a crate offered under MIT, alone or as one of its choices, is used under MIT, and its MIT notice is below.",
]

if mpl_packages:
    repositories = sorted({package.get("repository") or "-" for package in mpl_packages})
    lines.append("- The crates under MPL-2.0 are used unmodified, as published on crates.io. The licence text is in `licences/symphonia` at the root of this repository. Their source is on crates.io, at `https://crates.io/crates/<name>/<version>` for each crate, and in their repositories:")

    for repository in repositories:
        names = ", ".join(f"{package['name']} {package['version']}" for package in mpl_packages if (package.get("repository") or "-") == repository)
        lines.append(f"  - {repository}: {names}")

lines += ["", "## Licence texts"]

for text, group in sorted(notice_groups.items(), key=lambda item: (item[1]["packages"][0]["name"], item[1]["packages"][0]["version"])):
    marker = fence(text)
    lines += ["", "### " + ", ".join(f"{package['name']} {package['version']}" for package in group["packages"]), ""]

    for note in group["notes"]:
        lines += [note, ""]

    lines += [marker + "text", text, marker]

with open(sys.argv[1], "w", encoding="utf-8", newline="\n") as output:
    output.write("\n".join(lines) + "\n")
PYTHON

cd "$crateDirectory"
cargo metadata --format-version 1 --locked | python3 -I -c "$program" THIRD_PARTY_NOTICES.md
