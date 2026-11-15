" synID()-based verification for syntax/openppl.vim, run via:
"   vim -N -u NONE -es -c "source vim-openppl/test/synid_test.vim"
"
" Same discipline as vim-phh/vim-ohh's own synid_test.vim files: checks
" the real resolved highlight group at specific real-corpus positions,
" not assumed from reading the syntax file.

set nocompatible
let g:opplroot = fnamemodify(getcwd(), ':p')
let &runtimepath = &runtimepath . ',' . g:opplroot . 'vim-openppl'
syntax on
filetype on

let s:failures = 0
let s:report = []

function! s:Check(label, cond)
  if a:cond
    call add(s:report, '[ok] ' . a:label)
  else
    call add(s:report, '[FAIL] ' . a:label)
    let s:failures += 1
  endif
endfunction

function! s:GroupAt(line, col)
  return synIDattr(synID(a:line, a:col, 1), 'name')
endfunction

" 1. ftdetect + syntax load.
execute 'edit ' . g:opplroot . 'openppl-data/corpus/valid/structure-example.ohf'
call s:Check('ftdetect sets filetype=openppl', &filetype ==# 'openppl')
call s:Check('syntax item defined (b:current_syntax)', get(b:, 'current_syntax', '') ==# 'openppl')

" 2. Section header (line 1: "##f$preflop##").
call s:Check('line 1 col 1 (opening ##) is opplSection', s:GroupAt(1, 1) ==# 'opplSection')
call s:Check('line 1 col 5 (inside f$preflop) is opplSection', s:GroupAt(1, 5) ==# 'opplSection')

" 3. Comment (line 2).
call s:Check('line 2 col 5 (// comment) is opplComment', s:GroupAt(2, 5) ==# 'opplComment')

" 4. Keyword case-insensitivity: WHEN and FORCE, both upper-case here,
"    resolve to opplKeyword (line 4: "WHEN hand$AA RaiseMax FORCE").
call s:Check('line 4 col 5 (WHEN) is opplKeyword', s:GroupAt(4, 5) ==# 'opplKeyword')
call s:Check('line 4 col 27 (FORCE) is opplKeyword', s:GroupAt(4, 27) ==# 'opplKeyword')

" 5. hand$AA gets opplHandBoard; the bare action "RaiseMax" (no registry,
"    deliberately unhighlighted) stays plain/Normal, not any opplXxx group.
call s:Check('line 4 col 10 (hand$AA) is opplHandBoard', s:GroupAt(4, 10) ==# 'opplHandBoard')
call s:Check('line 4 col 18 (RaiseMax, an action name) has NO dedicated group (registry is blocked)',
      \ s:GroupAt(4, 18) ==# '')

" 6. Mixed-case keyword forms also resolve correctly (confirmed real
"    behavior, not just upper-case): "Fold" is an action (no group,
"    registry blocked) but line 5's own WHEN/FORCE still work regardless
"    of case consistency elsewhere in the file.
call s:Check('line 5 col 5 (WHEN, same as line 4) is opplKeyword', s:GroupAt(5, 5) ==# 'opplKeyword')

" 7. Operators, comparisons, SUITED keyword, from operators.ohf.
" Line numbers below reflect operators.ohf's CURRENT content (it gained
" two ##f$CardsLeft##/##f$Outs## sections at the top after this test was
" first written, recomputed via Python against the real file, not
" assumed, after that edit shifted every later line down by 9).
execute 'edit ' . g:opplroot . 'openppl-data/corpus/valid/operators.ohf'
call s:Check('line 16 col 24 (<=) is opplComparisonOp', s:GroupAt(16, 24) ==# 'opplComparisonOp')
call s:Check('line 16 col 27 (50%) is opplPercentage', s:GroupAt(16, 27) ==# 'opplPercentage')
call s:Check('line 18 col 20 (~~) is opplComparisonOp', s:GroupAt(18, 20) ==# 'opplComparisonOp')
call s:Check('line 19 col 19 (!=) is opplComparisonOp', s:GroupAt(19, 19) ==# 'opplComparisonOp')
call s:Check('line 21 col 19 (space-separated SUITED keyword) is opplSuitedKw', s:GroupAt(21, 19) ==# 'opplSuitedKw')

" 8. The confirmed hand$AKs trap: still just opplHandBoard at the syntax
"    level (this file doesn't (and can't, without a registry/hover)
"    distinguish the trap from an ordinary hand$ expression, that's
"    openppl-ls's job, confirmed in openppl-ls/README.md). Pinning down
"    the ACTUAL (unified) L0 behavior here, not an aspirational one.
call s:Check('line 26 col 10 (hand$AKs, the trap form) is still just opplHandBoard at L0',
      \ s:GroupAt(26, 10) ==# 'opplHandBoard')

" 9. Full-corpus sweep.
for path in glob(g:opplroot . 'openppl-data/corpus/valid/*.ohf', 0, 1)
      \ + glob(g:opplroot . 'openppl-data/corpus/invalid/*.ohf', 0, 1)
  execute 'edit ' . fnameescape(path)
  call s:Check(fnamemodify(path, ':t') . ': loads with filetype=openppl and syntax applied',
        \ &filetype ==# 'openppl' && get(b:, 'current_syntax', '') ==# 'openppl')
endfor

call add(s:report, '')
if s:failures > 0
  call add(s:report, s:failures . ' FAILURE(S)')
else
  call add(s:report, 'All checks passed.')
endif
call writefile(s:report, g:opplroot . 'vim-openppl/test/synid_test_output.txt')

if s:failures > 0
  cquit!
else
  qa!
endif
