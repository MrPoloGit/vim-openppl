# vim-openppl

Plain-Vim (not Neovim) support for OpenPPL (.ohf), plain Vim has no tree-sitter
and no built-in LSP client, so L1 comes from `openppl-ls` through a
general-purpose LSP plugin, documented below, not a bespoke plugin
shipped here (same split as `vim-phh`/`vim-ohh`).

## Install

Add this directory to `'runtimepath'` before `filetype on`/`syntax on`
run. Needs `:filetype on` and `:syntax on` enabled.

**Not listed anywhere.** This repo is pushed to
`github.com/MrPoloGit/vim-openppl`, usable today by any plugin manager
that takes a plain git URL, but it isn't listed on vim.org, vimawesome,
or any other curated index, nothing has been submitted anywhere.

## What's implemented (L0)

- **Filetype detection** (`ftdetect/openppl.vim`): `.ohf` → `openppl`.
- **Syntax highlighting** (`syntax/openppl.vim`): section headers
  (`##f$preflop##`, `##list007##`), case-insensitive keywords (`WHEN`,
  `FORCE`, `SET`, `RETURN`, `AND`, `OR`, `XOR`, `NOT`, `MOD`, `SUITED`
  via Vim's `\c` pattern modifier, kept local to just these patterns,
  not a file-wide `:syn case ignore`), the full operator set, `hand$`/
  `board$` expressions, numbers and percentages, parens. Deliberately
  **no highlight at all** for bare symbol/action names (`RaiseMax`,
  `StillToAct`, ...), that's an L1 (registry-backed, via `openppl-ls`)
  distinction, not an L0 one, same split `vim-phh`/`vim-ohh` already
  draw; they're left exactly the color Vim's "Normal" group already
  gives them, rather than guessed at syntactically.
- **ftplugin** (`ftplugin/openppl.vim`): `commentstring`/`comments` for
  `//`.

## L1: diagnostics and hover via openppl-ls

No bespoke plugin here, same reasoning as `vim-phh`/`vim-ohh`. Point any
general LSP client at `../openppl-ls/build/openppl-ls ../openppl/registry`
for filetype `openppl`. For [vim-lsp](https://github.com/prabirshrestha/vim-lsp):

```vim
if executable('openppl-ls')
  au User lsp_setup call lsp#register_server({
      \ 'name': 'openppl-ls',
      \ 'cmd': {server_info->['/path/to/openppl-ls/build/openppl-ls', '/path/to/openppl/registry']},
      \ 'allowlist': ['openppl'],
      \ 'root_uri': {server_info->lsp#utils#path_to_uri(fnamemodify(lsp#utils#get_buffer_path(), ':p:h'))},
      \ })
endif
```

**`root_uri` is included from the start here**, `vim-phh/README.md`
already paid the cost of discovering it's required (without it, vim-lsp
silently skips initialization); no need to rediscover that a third time.
This snippet has the same "not independently re-verified end-to-end"
status `vim-phh`'s and `vim-ohh`'s both do, see `vim-phh/README.md` for
exactly what was and wasn't confirmed about vim-lsp's full handshake in
this project's test harness. `openppl-ls`'s own hover/diagnostics
behavior is independently proven correct over real JSON-RPC
(`openppl-ls/tests/lsp_smoke_test.py`) and through Neovim's real LSP
client (`nvim-openppl/test/headless_test.lua`), what's specifically
unconfirmed is only vim-lsp's own handshake completing in a live,
interactive Vim session.

For [coc.nvim](https://github.com/neoclient/coc.nvim):

```json
{
  "languageserver": {
    "openppl": {
      "command": "/path/to/openppl-ls/build/openppl-ls",
      "args": ["/path/to/openppl/registry"],
      "filetypes": ["openppl"]
    }
  }
}
```

## This language turns out to be SIMPLER for Vim than PHH or OHH were

`vim-phh`'s README documents real Vim syntax-engine limits around
`contains=` not being exhaustive, which forced dropping two planned
features. `vim-ohh` needed a key-vs-value lookahead split to highlight
JSON keys and values differently. **Neither problem exists here**:
OpenPPL has no string-literal/region construct at all, so there is
nothing for a plain, non-contained `match` to ambiently bleed into or
need protecting from, every rule in `syntax/openppl.vim` is a flat
`match`, and that turned out to be sufficient, confirmed by testing, not
assumed because it looked simpler going in.

## A different, real quirk from the same family, found here instead

Testing surfaced a **new** instance of the same general issue
`vim-phh` already named for `region`s: when two `match` patterns can
both start at the same position, Vim resolves the tie by
**last-definition-wins**, not by longest-match. Two real cases hit this:

1. `opplArithmeticOp`'s bare `/` was winning over `opplComment`'s `//`
   at a comment's very first character, `// a real comment` was being
   highlighted as an arithmetic operator at its first slash, with the
   rest of the line falling back to no highlight at all. Fixed by moving
   `opplComment` to be defined **last** in the file.
2. `opplNumber` was winning over `opplPercentage` at a percentage
   literal's first digit, `50%` was truncating to just `50` colored as
   a plain number, with the `%` character left in no highlight group at
   all. Fixed by moving `opplPercentage` to be defined **after**
   `opplNumber`.

Both are confirmed via `synstack()`, not guessed at from reading the
file, see `syntax/openppl.vim`'s own header comment for exactly where
this matters so the ordering isn't "tidied" back into the bug later.

## How this was verified

`test/synid_test.vim` (run via `vim -N -u NONE -es`) checks the real
resolved highlight group at specific real-corpus positions via
`synID()`/`synstack()`, including both bugs above, the confirmed
`hand$AKs` trap form (still just `opplHandBoard` at this L0 layer, only
`openppl-ls`'s hover can actually explain the trap, confirmed in that
package's own README), and a full-corpus load sweep. **All checks
pass.**
