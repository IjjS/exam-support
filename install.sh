#!/bin/sh
set -eu
target=${1:-exam-support}
ref=${EXAM_SUPPORT_REF:-main}
[ ! -e "$target" ] || { echo "Destination already exists: $target" >&2; exit 1; }
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT HUP INT TERM
curl -fsSL "https://codeload.github.com/IjjS/exam-support/zip/$ref" -o "$work/source.zip"
unzip -q "$work/source.zip" -d "$work/source"
source_dir=$(find "$work/source" -mindepth 1 -maxdepth 1 -type d)
mkdir "$work/workspace"
for item in .agents _spec _template _inbox docs CLAUDE.md README.md README_KO.md LICENSE .gitignore; do
  cp -R "$source_dir/$item" "$work/workspace/"
done
cp "$work/workspace/CLAUDE.md" "$work/workspace/AGENTS.md"
cp "$work/workspace/CLAUDE.md" "$work/workspace/GEMINI.md"
mkdir "$work/workspace/.claude"
cp -R "$work/workspace/.agents/skills" "$work/workspace/.claude/skills"
cp -R "$work/workspace/_template/exams" "$work/workspace/exams"
mv "$work/workspace" "$target"
echo "Installed: $target — open this folder in your agent and ask to register an exam."
