" Colors the Octane directives the tsx tree-sitter grammar cannot see.
" Tree-sitter extmarks win at priority 100, so this cannot fight it.

if exists("b:current_syntax")
  finish
endif

" Fallback when the tsx parser is unavailable.
if !exists("b:ts_highlight")
  runtime! syntax/typescriptreact.vim
  unlet! b:current_syntax
endif

syntax match tsrxDirective /@\%(if\|else\|for\|empty\|switch\|case\|default\|try\|pending\|catch\)\>/
syntax match tsrxDirectiveBrace /@\ze{/
syntax match tsrxForKey /;\s*\zskey\>/

highlight default link tsrxDirective      Keyword
highlight default link tsrxDirectiveBrace Keyword
highlight default link tsrxForKey         Keyword

let b:current_syntax = "tsrx"
