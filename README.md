# vim-openppl

Vim support for OpenPPL (.ohf).

## Install

Add this directory to `'runtimepath'` before `filetype on`/`syntax on`
run. Needs `:filetype on` and `:syntax on` enabled.

**Not listed anywhere.** This repo is pushed to
`github.com/MrPoloGit/vim-openppl`, usable today by any plugin manager
that takes a plain git URL, but it isn't listed on vim.org, vimawesome,
or any other curated index, nothing has been submitted anywhere.

No bespoke plugin here, same reasoning as `vim-phh`/`vim-ohh`. Point any
general LSP client at `../openppl-ls/build/openppl-ls ../openppl-data/registry`
for filetype `openppl`. For [vim-lsp](https://github.com/prabirshrestha/vim-lsp):

```vim
if executable('openppl-ls')
  au User lsp_setup call lsp#register_server({
      \ 'name': 'openppl-ls',
      \ 'cmd': {server_info->['/path/to/openppl-ls/build/openppl-ls', '/path/to/openppl-data/registry']},
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
      "args": ["/path/to/openppl-data/registry"],
      "filetypes": ["openppl"]
    }
  }
}
```
