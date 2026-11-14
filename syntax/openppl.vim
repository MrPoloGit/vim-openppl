" Vim syntax file for OpenPPL (.ohf), 
"
" Unlike vim-phh (which had to drop two features after hitting a real
" Vim syntax-engine limit, see that package's README) and vim-ohh
" (which needed a key-vs-value lookahead split for JSON strings), this
" language needs none of THAT caution: OpenPPL has no string-literal/
" region construct at all for a plain, non-contained match to ambiently
" bleed into (vim-phh's and vim-ohh's whole containment problem was
" specifically about protecting a quoted string's contents from
" unrelated ambient matches). Every rule below is a flat, non-contained
" `match`, confirmed sufficient by testing (see test/synid_test.vim).
"
" A DIFFERENT real quirk from the same family bit this file instead,
" confirmed by testing, not assumed: when two `match` patterns can both
" start at the same buffer position, Vim resolves the tie by
" LAST-DEFINITION-WINS, not by longest-match, the same finding
" vim-phh's README already documents for `region`s, now confirmed for
" plain `match`es too. Two real instances here: `opplArithmeticOp`'s
" bare "/" was winning over `opplComment`'s "//" at a comment's first
" character (fixed by moving opplComment to be defined LAST), and
" `opplNumber` was winning over `opplPercentage` at a percentage
" literal's first digit, truncating "50%" to just "50" with the "%"
" left in no group at all (fixed by moving opplPercentage to be defined
" AFTER opplNumber). The ordering below is deliberate, not incidental, " moving either of these two rules back "for tidiness" would reintroduce
" the bug.
" Case-sensitivity mirrors tree-sitter-openppl/grammar.js exactly:
" keywords (WHEN, FORCE, AND, OR, NOT, XOR, SET, RETURN, MOD, SUITED)
" are matched case-insensitively via Vim's `\c` pattern modifier, kept
" local to just these patterns rather than a file-wide `:syn case
" ignore`, everything else stays whatever Vim's default "Normal" color is.

if exists("b:current_syntax")
  finish
endif

syn match opplKeyword "\c\<\(WHEN\|FORCE\|SET\|RETURN\)\>"
syn match opplLogicalOp "\c\<\(AND\|OR\|XOR\|NOT\|MOD\)\>"
syn match opplSuitedKw "\c\<SUITED\>"

syn match opplComparisonOp "!=\|<=\|>=\|\~\~\|=\|<\|>"
syn match opplArithmeticOp "[+\-*/]"

" "##f$preflop##", "##list007##", one syntax for both functions and
" handlists.
syn match opplSection "##[A-Za-z_$][A-Za-z0-9_$]*##"

" "hand$AA", "hand$AQSuited", "hand$AKs" (NOT suited, a confirmed trap
" in the manual's own naming), "board$AT", "board$ATSuited". The optional
" trailing " SUITED" keyword after a board$ expression is already
" covered by opplSuitedKw above (ambient matching is fine here, there
" is no region to protect it from bleeding into).
syn match opplHandBoard "\c\<\(hand\|board\)\$[A-Za-z0-9]\+"

syn match opplNumber "\<[0-9]\+\(\.[0-9]\+\)\?\>"
syn match opplPercentage "\<[0-9]\+\(\.[0-9]\+\)\?%"

syn match opplParen "[()]"

" Defined LAST on purpose, see the file header's last-definition-wins
" note. "//" must win its tie against opplArithmeticOp's bare "/".
syn match opplComment "//.*$"

hi def link opplComment       Comment
hi def link opplKeyword       Keyword
hi def link opplLogicalOp     Keyword
hi def link opplSuitedKw      Keyword
hi def link opplComparisonOp  Operator
hi def link opplArithmeticOp  Operator
hi def link opplSection       Label
hi def link opplHandBoard     Special
hi def link opplPercentage    Number
hi def link opplNumber        Number
hi def link opplParen         Delimiter

let b:current_syntax = "openppl"
