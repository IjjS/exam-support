#!/bin/sh
# wrongbook.sh — read and write state/wrongbook.md without loading it into the model's context.
#
# The wrongbook grows with every miss, so no skill reads it whole. This script answers the narrow
# questions the skills actually ask, and does every write as a whole-row operation followed by a
# cell-count check and a hot-block recount. Run from the repo root.
#
#   sh _spec/wrongbook.sh <slug> index              one line: "T-041 2 miss,shaky; T-052 1 lucky; …"
#   sh _spec/wrongbook.sh <slug> rows T-041 T-005   full rows for those topics
#   sh _spec/wrongbook.sh <slug> id W-016 W-102     full rows for those entries
#   sh _spec/wrongbook.sh <slug> type confusion     full rows of one error type
#   sh _spec/wrongbook.sh <slug> next-id            the next unused W-id (checks _resolved.md too)
#   … add      < rows     append new entries (whole rows, IDs must be new)
#   … set      < rows     replace existing entries, matched by W-id (whole rows)
#   … retire   < rows     rows in _resolved.md format: removed from the book, appended to _resolved.md
#   … keywords < line     replace the value of the hot block's "missed keywords:" line
#
# Rows on stdin are complete markdown table rows, one per line. Uses only POSIX sh and awk.
set -eu

usage() { grep '^#   ' "$0" >&2; exit 2; }
[ $# -ge 2 ] || usage
slug=$1; cmd=$2; shift 2
dir="exams/$slug/state"; wb="$dir/wrongbook.md"; rs="$dir/_resolved.md"
[ -f "$wb" ] || { echo "not found: $wb" >&2; exit 1; }
tmp="${TMPDIR:-/tmp}/wrongbook.$$"; trap 'rm -f "$tmp" "$tmp.ids"' EXIT

# --- helpers ---------------------------------------------------------------------------------

trim_ids() { awk -F'|' '{ id=$2; gsub(/ /,"",id); if (id ~ /^W-[0-9]+$/) print id }' "$1"; }

# insert the rows in $2 into the table of $1: after the last "| W-" row; in an empty table, in place of
# the template's placeholder row ("| | | |"), or else right under the header's separator line
insert() {
  grep -q '^| ID ' "$1" || { echo "no table found in $1" >&2; exit 1; }
  awk -v src="$2" '
    NR==FNR { if ($0 ~ /^\| W-/) last=FNR
              else if (!ph && $0 ~ /^\|( *\|)+ *$/) ph=FNR
              else if (hdr && !sep && $0 ~ /^\|-/) sep=FNR
              if ($0 ~ /^\| ID /) hdr=1
              next }
    !last && FNR==ph { while ((getline l < src) > 0) print l; next }
    { print }
    FNR==(last ? last : (ph ? -1 : sep)) { while ((getline l < src) > 0) print l }
  ' "$1" "$1" > "$1.tmp" && mv "$1.tmp" "$1"
}

# reject malformed input before anything is written: every row needs the target header's cell count
validate() {
  awk -F'|' 'NR==FNR { if ($0 ~ /^\| ID /) n=NF; next }
    { if (NF != n || $0 !~ /\| *$/) { print "malformed row (" NF - 2 " cells, header has " n - 2 "): " substr($0, 1, 40) > "/dev/stderr"; bad=1 } }
    END { exit bad }' "$1" "$2"
}

# every row whose W-id is listed in $2 must have the header's cell count and end in "|"
check() {
  awk -F'|' -v idfile="$2" '
    BEGIN { while ((getline l < idfile) > 0) want[l]=1 }
    /^\| ID / { n=NF }
    /^\| W-/ { id=$2; gsub(/ /,"",id); if (id in want) { ok=(NF==n && $0 ~ /\| *$/); if (!ok) { print "BAD " id; bad=1 } } }
    END { exit bad }
  ' "$1"
}

recount() {
  awk -F'|' '
    NR==FNR { if ($0 ~ /^\| W-/) { a=$4; b=$5; gsub(/ /,"",a); gsub(/ /,"",b); n++; o[a]++; t[b]++ }; next }
    /^active: / { printf "active: %d  (miss %d / lucky %d / shaky %d)\n", n, o["miss"], o["lucky"], o["shaky"]; next }
    /^types: /  { printf "types: unknown %d / confusion %d / misread %d / distractor %d / recall %d\n", t["unknown"], t["confusion"], t["misread"], t["distractor"], t["recall"]; next }
    { print }
  ' "$wb" "$wb" > "$wb.tmp" && mv "$wb.tmp" "$wb"
  [ -f "$rs" ] || return 0
  awk 'NR==FNR { if ($0 ~ /^\| W-/) n++; next } /^resolved: / { printf "resolved: %d\n", n; next } { print }' \
    "$rs" "$rs" > "$rs.tmp" && mv "$rs.tmp" "$rs"
}

read_stdin() { grep '^| W-' > "$tmp" || { echo "no rows on stdin" >&2; exit 1; }; trim_ids "$tmp" > "$tmp.ids"; }

# --- commands --------------------------------------------------------------------------------

case $cmd in
index)
  awk -F'|' '/^\| W-/ { t=$3; o=$4; gsub(/ /,"",t); gsub(/ /,"",o); c[t]++; g[t]=g[t] (g[t] ? "," : "") o }
             END { for (t in c) print t " " c[t] " " g[t] }' "$wb" | sort | paste -sd';' - | sed 's/;/; /g'
  ;;
rows)
  [ $# -ge 1 ] || { echo "rows needs topic IDs" >&2; exit 2; }
  grep -E "^\| W-[0-9]+ \| ($(echo "$*" | tr ' ' '|')) \|" "$wb" || true
  ;;
id)
  [ $# -ge 1 ] || { echo "id needs W-ids" >&2; exit 2; }
  grep -E "^\| ($(echo "$*" | tr ' ' '|')) \|" "$wb" || true
  ;;
type)
  [ $# -eq 1 ] || { echo "type needs one error type" >&2; exit 2; }
  awk -F'|' -v ty="$1" '/^\| W-/ { b=$5; gsub(/ /,"",b); if (b == ty) print }' "$wb"
  ;;
next-id)
  n=$(cat "$wb" "$rs" 2>/dev/null | grep -o '^| W-[0-9]*' | tr -dc '0-9\n' | sed 's/^0*//' | sort -n | tail -1)
  printf 'W-%03d\n' $(( ${n:-0} + 1 ))
  ;;
add)
  read_stdin; validate "$wb" "$tmp"
  for id in $(cat "$tmp.ids"); do
    if grep -q "^| $id |" "$wb" || { [ -f "$rs" ] && grep -q "^| $id |" "$rs"; }; then
      echo "$id already exists — use next-id" >&2; exit 1
    fi
  done
  insert "$wb" "$tmp"; check "$wb" "$tmp.ids"; recount
  echo "added $(wc -l < "$tmp.ids" | tr -d ' ')"
  ;;
set)
  read_stdin; validate "$wb" "$tmp"
  awk -F'|' -v src="$tmp" '
    BEGIN { while ((getline l < src) > 0) { split(l, f, "|"); id=f[2]; gsub(/ /,"",id); r[id]=l } }
    /^\| W-/ { id=$2; gsub(/ /,"",id); if (id in r) { print r[id]; done[id]=1; next } }
    { print }
    END { for (id in r) if (!(id in done)) { print "not in the book: " id > "/dev/stderr"; bad=1 }; exit bad }
  ' "$wb" > "$wb.tmp" && mv "$wb.tmp" "$wb" || { rm -f "$wb.tmp"; exit 1; }
  check "$wb" "$tmp.ids"; recount
  echo "set $(wc -l < "$tmp.ids" | tr -d ' ')"
  ;;
retire)
  read_stdin
  [ -f "$rs" ] || { echo "not found: $rs" >&2; exit 1; }
  validate "$rs" "$tmp"
  for id in $(cat "$tmp.ids"); do grep -q "^| $id |" "$wb" || { echo "not in the book: $id" >&2; exit 1; }; done
  awk -F'|' -v idfile="$tmp.ids" 'BEGIN { while ((getline l < idfile) > 0) gone[l]=1 }
    /^\| W-/ { id=$2; gsub(/ /,"",id); if (id in gone) next } { print }' "$wb" > "$wb.tmp" && mv "$wb.tmp" "$wb"
  insert "$rs" "$tmp"; check "$rs" "$tmp.ids"; recount
  echo "retired $(wc -l < "$tmp.ids" | tr -d ' ')"
  ;;
keywords)
  line=$(head -1)
  awk -v v="$line" '/^missed keywords: / { print "missed keywords: " v; next } { print }' "$wb" > "$wb.tmp" && mv "$wb.tmp" "$wb"
  ;;
*) usage ;;
esac
