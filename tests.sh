#!/usr/bin/env bash
# Tests for sbee, find_dup_label and find_word_part.
# Uses small fixtures (a tiny dictionary, a LaTeX tree, a text file), so it needs neither
# /usr/share/dict nor html2text. Run: ./tests.sh
set -uo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
WORK=$(mktemp -d "${TMPDIR:-/tmp}/shell_tests.XXXXXX")
trap 'rm -rf "$WORK"' EXIT
export TERM=xterm
export LC_ALL=C   # deterministic sort order in the expectations below

pass=0
fail=0
strip_colors() { sed -E 's/\x1b\[[0-9;]*m//g'; }
ok()   { pass=$((pass + 1)); }
bad()  { fail=$((fail + 1)); printf 'FAIL: %s\n' "$1"; [[ $# -gt 1 ]] && printf '%s\n' "$2"; }
# expect_eq NAME EXPECTED ACTUAL
expect_eq() {
	if [[ "$2" == "$3" ]]; then ok; else bad "$1" "$(diff <(printf '%s\n' "$2") <(printf '%s\n' "$3") | head -20)"; fi
}
# expect_has NAME NEEDLE HAYSTACK
expect_has() {
	if [[ "$3" == *"$2"* ]]; then ok; else bad "$1" "expected to find: $2"$'\n'"in: $3"; fi
}
expect_not_has() {
	if [[ "$3" != *"$2"* ]]; then ok; else bad "$1" "did not expect: $2"$'\n'"in: $3"; fi
}

#-------------------------------------------------------------------------------
# sbee
#-------------------------------------------------------------------------------
DICT="$WORK/dict"
mkdir -p "$DICT"
printf '%s\n' voltage Voltage gate gala glee toggle tale go gab goal ottava > "$DICT/american-english"
printf '%s\n' gaol goal > "$DICT/british-english"
export SBEE_DICT_DIR="$DICT"
sbee="$HERE/sbee"

expected=$'Special Word(s):\n\nvoltage\n\nSpecial Score = 7\n\n\nAll Words:\n\nvoltage\ngate\ngala\nglee\ntoggle\ngoal\n\nMaximum Possible Score = 24'
expect_eq "sbee: words, pangram and score" "$expected" "$("$sbee" oavtle g 2>/dev/null)"
expect_eq "sbee: upper case input is lower cased" "$expected" "$("$sbee" OAVTLE G 2>/dev/null)"
expect_eq "sbee: -m 5 drops the four letter words" \
	$'Special Word(s):\n\nvoltage\n\nSpecial Score = 7\n\n\nAll Words:\n\nvoltage\ntoggle\n\nMaximum Possible Score = 20' \
	"$("$sbee" -m 5 oavtle g 2>/dev/null)"
expect_eq "sbee: -v shows the expanded lists" $'ALPHABET: abcdefghi:orstuvy\nMAY-USE : abcdefghi\nMUST-USE: orstuvy' \
	"$("$sbee" -v '[a-i]' 'oy[r-v]' 2>&1 >/dev/null | strip_colors | grep -E 'ALPHABET|MAY-USE|MUST-USE')"
expect_eq "sbee: descending and embedded ranges" $'MAY-USE : abcdklmn\nMUST-USE: e' \
	"$("$sbee" -v '[d-a]k[l-n]' e 2>&1 >/dev/null | strip_colors | grep -E 'MAY-USE|MUST-USE')"
expect_eq "sbee: duplicate letters are collapsed" $'MAY-USE : a\nMUST-USE: b' \
	"$("$sbee" -v aa bb 2>&1 >/dev/null | strip_colors | grep -E 'MAY-USE|MUST-USE')"
expect_eq "sbee: -b uses the British dictionary" $'goal\ngaol' "$("$sbee" -b oal g 2>/dev/null | sed -n '/All Words/,$p' | grep -E '^[a-z]+$' | sort -r)"
expect_eq "sbee: no words found" "No words found." "$("$sbee" xyz q 2>&1 | strip_colors)"

out=$("$sbee" 'oavtle$(echo INJECTED>&2){a..b}' g 2>&1); rc=$?
expect_not_has "sbee: letter lists are never evaluated as code" "INJECTED" "$out"
expect_eq "sbee: injection attempt still exits 0" 0 "$rc"

out=$(SBEE_DICT_DIR="$WORK/nodict" "$sbee" oavtle g 2>&1); rc=$?
expect_eq "sbee: missing dictionary exits 8" 8 "$rc"
expect_has "sbee: missing dictionary is reported" "does not exist or is not readable" "$(strip_colors <<< "$out")"

out=$("$sbee" -m abc oavtle g 2>&1); rc=$?
expect_eq "sbee: -m must be a number (exit 7)" 7 "$rc"
expect_has "sbee: -m below the game minimum warns" "overridden" "$("$sbee" -m 1 oavtle g 2>&1 | strip_colors)"
out=$("$sbee" oavtle 1 2>&1); rc=$?
expect_eq "sbee: empty must-use list exits 10" 10 "$rc"
out=$("$sbee" oavtle 2>&1); rc=$?
expect_eq "sbee: missing argument exits 100" 100 "$rc"
expect_has "sbee: full path invocation shows the bare name" "Usage: sbee" "$("$HERE/sbee" -h 2>&1 | strip_colors | head -1 | tr -s '\t ' ' ')"

# Missing supporting program: a PATH with everything but gawk.
BIN="$WORK/bin"; mkdir -p "$BIN"
for p in bash grep sort tr sed cat mktemp find xargs uniq rm; do ln -s "$(command -v $p)" "$BIN/$p"; done
out=$(PATH="$BIN" "$sbee" oavtle g 2>&1); rc=$?
expect_eq "sbee: a missing first program (gawk) is detected" 6 "$rc"
expect_has "sbee: the missing program is named" "AWK -> gawk" "$(strip_colors <<< "$out")"

if [[ -r /usr/share/dict/american-english ]]; then
	out=$(SBEE_DICT_DIR=/usr/share/dict "$sbee" oavtle g 2>/dev/null)
	expect_has "sbee: README example 1 on the system dictionary (score)" "Maximum Possible Score = 165" "$out"
	expect_has "sbee: README example 1 on the system dictionary (pangram)" $'Special Word(s):\n\nvoltage' "$out"
fi

#-------------------------------------------------------------------------------
# find_dup_label
#-------------------------------------------------------------------------------
fdl="$HERE/find_dup_label"
TEX="$WORK/tex"; mkdir -p "$TEX/sub" "$TEX/empty"
printf '\\section{A}\\label{sec:a}\n%% \\label{eq:dup}\nSee \\eqref{eq:one} \\label{eq:one} %% trailing \\label{eq:one}\n' > "$TEX/a.tex"
printf '\\label{eq:one}\n\\label{eq.x+y}\n\\label{fig:1} and \\label{fig:1}\n' > "$TEX/sub/b.tex"
printf '\\label{eq.x+y}\n\\label{eqAxBy}\n\\label{eq:dup}\n\\label{a[1]}\n' > "$TEX/sub/c.tex"
printf '%% \\label{eq:one}\n\\label{a[1]} \\%% not a comment \\label{a[1]}\n' > "$TEX/sub/d.tex"
printf '\\label{other:1}\n' > "$TEX/notes.ltx"
printf '\\label{other:1}\n' > "$TEX/sub/more.ltx"

expected="Duplicate: a[1]
   $TEX/sub/c.tex:4:\\label{a[1]}
   $TEX/sub/d.tex:2:\\label{a[1]} \\% not a comment \\label{a[1]}
Duplicate: eq.x+y
   $TEX/sub/b.tex:2:\\label{eq.x+y}
   $TEX/sub/c.tex:1:\\label{eq.x+y}
Duplicate: eq:one
   $TEX/a.tex:3:See \\eqref{eq:one} \\label{eq:one} 
   $TEX/sub/b.tex:1:\\label{eq:one}
Duplicate: fig:1
   $TEX/sub/b.tex:3:\\label{fig:1} and \\label{fig:1}"
expect_eq "find_dup_label: duplicates with locations (regex chars, comments stripped)" "$expected" "$("$fdl" -d "$TEX" 2>&1)"
expect_eq "find_dup_label: no duplicates" "No Duplicate Labels Found." "$("$fdl" -d "$TEX/empty" 2>&1)"
expect_eq "find_dup_label: works without TERM" "No Duplicate Labels Found." "$(env -u TERM "$fdl" -d "$TEX/empty" 2>&1)"
expect_eq "find_dup_label: -p pattern" "Duplicate: other:1
   $TEX/notes.ltx:1:\\label{other:1}
   $TEX/sub/more.ltx:1:\\label{other:1}" "$("$fdl" -d "$TEX" -p '*.ltx' 2>&1)"
expect_eq "find_dup_label: default directory is ." "No Duplicate Labels Found." "$(cd "$TEX/empty" && "$fdl" 2>&1)"
out=$(cd "$TEX/sub" && "$fdl" -p *.tex 2>&1); rc=$?
expect_eq "find_dup_label: an unquoted -p glob is rejected" 4 "$rc"
expect_has "find_dup_label: the unquoted glob message says to quote" "must be quoted" "$(strip_colors <<< "$out")"
out=$("$fdl" -d "$WORK/nowhere" 2>&1); rc=$?
expect_eq "find_dup_label: missing directory exits 5" 5 "$rc"
out=$("$fdl" -z 2>&1); rc=$?
expect_eq "find_dup_label: invalid option exits 3" 3 "$rc"

#-------------------------------------------------------------------------------
# find_word_part
#-------------------------------------------------------------------------------
fwp="$HERE/find_word_part"
TXT="$WORK/words.txt"
printf 'Wise men say wise things; otherwise, the Wise-guy is unwise. "wise" (wisely) Wise'"'"'s\nA plus sign a+b and a dot w.se here.\n' > "$TXT"

expect_eq "find_word_part: default" $'      2 wise\n      1 Wise\n      1 Wise\'s\n      1 Wise-guy\n      1 otherwise\n      1 unwise\n      1 wisely' "$("$fwp" "$TXT" wise)"
expect_eq "find_word_part: -c" $'      2 wise\n      1 otherwise\n      1 unwise\n      1 wisely' "$("$fwp" -c "$TXT" wise)"
expect_eq "find_word_part: -f -u" $'otherwise\nunwise\nwise\nwise\'s\nwise-guy\nwisely' "$("$fwp" -f -u "$TXT" wise)"
expect_eq "find_word_part: -p" $'      1 Wise\'s\n      1 Wise-guy\n      1 otherwise\n      1 unwise\n      1 wisely' "$("$fwp" -p "$TXT" wise)"
expect_eq "find_word_part: -w" $'      2 wise\n      1 Wise' "$("$fwp" -w "$TXT" wise)"
expect_eq "find_word_part: word part starting with -" "      1 Wise-guy" "$("$fwp" "$TXT" -guy)"
expect_eq "find_word_part: word part starting with - after options" "      1 Wise-guy" "$("$fwp" -c "$TXT" -guy)"
expect_eq "find_word_part: the word part is literal, not a regex (w.se does not match wise)" "" "$("$fwp" "$TXT" 'w.se' 2>/dev/null)"
expect_eq "find_word_part: the word part is literal, not a regex (wis* does not match wise)" "" "$("$fwp" "$TXT" 'wis*' 2>/dev/null)"
expect_eq "find_word_part: literal regex characters can be searched for" "      1 co\$t" "$(printf 'a co$t b\n' > "$WORK/dollar.txt"; "$fwp" "$WORK/dollar.txt" 'co$t')"
out=$("$fwp" "$TXT" zzz 2>&1 >"$WORK/stdout"); rc=$?
expect_eq "find_word_part: nothing found exits 0 with empty stdout" "0|" "$rc|$(cat "$WORK/stdout")"
expect_eq "find_word_part: nothing found says so on stderr" "No matches found." "$out"
out=$("$fwp" "$WORK/missing.txt" wise 2>&1); rc=$?
expect_eq "find_word_part: missing file exits 8" 8 "$rc"
out=$("$fwp" "$TXT" "" 2>&1); rc=$?
expect_eq "find_word_part: empty word part exits 7" 7 "$rc"
out=$("$fwp" "$TXT" 2>&1); rc=$?
expect_eq "find_word_part: one argument exits 5" 5 "$rc"
expect_has "find_word_part: -p and -w conflict warns" "incompatible" "$("$fwp" -p -w "$TXT" wise 2>&1 >/dev/null | strip_colors)"
out=$(PATH="$BIN" "$fwp" "$TXT" wise 2>&1); rc=$?
expect_eq "find_word_part: a missing first program (gawk) is detected" 4 "$rc"
if ! command -v html2text >/dev/null 2>&1; then
	out=$("$fwp" -x "$TXT" wise 2>&1); rc=$?
	expect_eq "find_word_part: -x without html2text exits 6" 6 "$rc"
fi
expect_eq "find_word_part: no temp files are left behind" "" "$(ls "${TMPDIR:-/tmp}"/find_word_part_tmp.* 2>/dev/null)"

#-------------------------------------------------------------------------------
printf '%d passed, %d failed\n' "$pass" "$fail"
[[ $fail -eq 0 ]]
