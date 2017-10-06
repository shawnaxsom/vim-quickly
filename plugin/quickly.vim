" quickly.vim - Quickly jump to files. Cozy :find, :buffer, and :oldfiles replacements.
" Maintainer:   Shawn Axsom <axs221@gmail.com>
" Version:      0.0.0
" License:      MIT
" Website:      https://github.com/axs221/vim-quickly

" -----------------------------------------------------------------------------------------
"  Dedup - Remove duplicates from an array
" -----------------------------------------------------------------------------------------
function! Dedup (lines)
  return filter(copy(a:lines), 'index(a:lines, v:val, v:key+1)==-1')
endfunction

" -----------------------------------------------------------------------------------------
"  ListComplete - Completion on pressing <Tab> (or your preferred completion mapping)
" -----------------------------------------------------------------------------------------
function! ListComplete(lines, ArgLead, CmdLine, CursorPos)
  let lines = a:lines

  for word in split(a:CmdLine, " ")[1:]
    let lines = filter(lines, 'v:val =~ "' . word . '"')
  endfor

  let lines = Dedup(lines)

  return lines
endfunction

" -----------------------------------------------------------------------------------------
"  GetMatches -
" -----------------------------------------------------------------------------------------
function! GetMatches (lines, arg)
  " Good resources for some of the code here:
  " * https://github.com/junegunn/fzf/issues/301
  " * https://vi.stackexchange.com/questions/6019/is-it-possible-to-populate-the-quickfix-list-with-the-errors-of-vimscript-functi
  " * https://www.reddit.com/r/vim/comments/finj2/how_do_you_put_information_in_the_quickfix_window/
  " * https://www.reddit.com/r/vim/comments/4gjbqn/what_tricks_do_you_use_instead_of_popular_plugins/
  " * http://learnvimscriptthehardway.stevelosh.com/chapters/40.html
  " * https://github.com/romainl/vim-tinyMRU
  let lines = a:lines

  for word in split(a:arg, " ")
    let lines = filter(lines, 'v:val =~ "' . word . '"')
  endfor

  let lines = Dedup(lines)

  " Remove relative path prefix, not necessary if your path is correct and can
  " lead to duplicates if some have relative path and some don't.
  let lines = Dedup(map(copy(lines), 'substitute(v:val, "^./", "", "g")'))

  return lines
endfunction
function! QuickfixOrGotoFile (lines, arg)
  let lines = GetMatches(a:lines, a:arg)

  if len(lines) > 0
    if len(lines) == 1
      execute 'e ' . lines[0]
    else
      let data = map(copy(lines), '{"filename": v:val, "text": "", "lnum": ""}')
      call setqflist(data)
      copen
    endif
  endif
endfunction


" -----------------------------------------------------------------------------------------
"  :QuicklyMru
" -----------------------------------------------------------------------------------------
function! MruLines ()
  return extend(
    \ filter(copy(v:oldfiles),
    \        "v:val !~ 'fugitive:\\|NERD_tree\\|^/tmp/\\|.git/'"),
    \ map(filter(range(1, bufnr('$')), 'buflisted(v:val)'), 'bufname(v:val)'))
endfunction
function! MruComplete (ArgLead, CmdLine, CursorPos)
  return ListComplete(MruLines(), a:ArgLead, a:CmdLine, a:CursorPos)
endfunction
function! MruQuickfixOrGotoFile (arg)
  call QuickfixOrGotoFile(MruLines(), a:arg)
endfunction
command! -nargs=* -complete=customlist,MruComplete QuicklyMru call MruQuickfixOrGotoFile(<q-args>)


" -----------------------------------------------------------------------------------------
"  :QuicklyBufferDelete
" -----------------------------------------------------------------------------------------
function! BufferLines ()
  return map(filter(range(1, bufnr('$')), 'buflisted(v:val)'), 'bufname(v:val)')
endfunction
function! BufferComplete (ArgLead, CmdLine, CursorPos)
  return ListComplete(BufferLines(), a:ArgLead, a:CmdLine, a:CursorPos)
endfunction
function! BufferQuickfixOrGotoFile (arg)
  call QuickfixOrGotoFile(BufferLines(), a:arg)
endfunction
command! -nargs=* -complete=customlist,BufferComplete QuicklyBuffer call BufferQuickfixOrGotoFile(<q-args>)


" -----------------------------------------------------------------------------------------
"  :QuicklyBufferDelete
" -----------------------------------------------------------------------------------------
function! BuffersDelete (arg)
  let lines = GetMatches(BuffersLines(), a:arg)

  if len(lines) > 0
    for line in lines
      execute 'bd '.line
    endfor
  endif
endfunction
command! -nargs=* -complete=customlist,BuffersComplete QuicklyBufferDelete call BuffersDelete(<q-args>)


" -----------------------------------------------------------------------------------------
"  :QuicklyFind
" -----------------------------------------------------------------------------------------
function! FindLines (ArgLead)
  if a:ArgLead =~ '\.\/.*' || a:ArgLead =~ '\/.*'
    " User must have used completion, last argument is probably full path
    let args = split(a:ArgLead, ' ')
    return [ args[len(args) - 1] ]
  endif

  " Just uses the first word if there are multiple. A little slower
  " but more flexible in ordering of words and subdirectories.
  " Other words get filtered out in QuickfixOrGotoFile()
  let firstArg = split(a:ArgLead, ' ')[0]
  " Limit to just JavaScript for now, and don't include folders
  let excludeFolders = '-not -path "*/node_modules/*" -not -path "*/.git/*" -not -path "*/bower_components/*"'
  let lines = split(system("find . -path '*" . firstArg . "*' -type f " . excludeFolders), '\n')
  return lines
endfunction
function! FindComplete (ArgLead, CmdLine, CursorPos)
  return ListComplete(FindLines(a:ArgLead), a:ArgLead, a:CmdLine, a:CursorPos)
endfunction
function! FindQuickfixOrGotoFile (arg)
  call QuickfixOrGotoFile(FindLines(a:arg), a:arg)
endfunction
command! -nargs=* -complete=customlist,FindComplete QuicklyFind call FindQuickfixOrGotoFile(<q-args>)


" -----------------------------------------------------------------------------------------
"  :QuicklyAny
" -----------------------------------------------------------------------------------------
function! AnyLines (ArgLead)
  let lines = GetMatches(BufferLines(), a:ArgLead)

  if len(lines) == 0
    let lines = extend(lines, GetMatches(MruLines(), a:ArgLead))
  endif

  if len(lines) == 0
    " Only run FilesLines if no matches from other two? For performance.
    let lines = extend(lines, FilesLines(a:ArgLead))
  endif
  return lines
endfunction
function! AnyComplete (ArgLead, CmdLine, CursorPos)
  return ListComplete(AnyLines(a:ArgLead), a:ArgLead, a:CmdLine, a:CursorPos)
endfunction
function! AnyQuickfixOrGotoFile (arg)
  call QuickfixOrGotoFile(AnyLines(a:arg), a:arg)
endfunction
command! -nargs=* -complete=customlist,AnyComplete QuicklyAny call AnyQuickfixOrGotoFile(<q-args>)

" -----------------------------------------------------------------------------------------
"  Default Key Mappings
" -----------------------------------------------------------------------------------------
let g:quickly_enable_default_key_mappings =
      \ get( g:, 'quickly_enable_default_key_mappings', 1 )

if g:quickly_enable_default_key_mappings == 1
  nnoremap <leader><leader>c :QuicklyBufferDelete<space>
  nnoremap <leader>b :QuicklyBuffer<space>
  nnoremap <leader>o :QuicklyMru<space>
  nnoremap <leader>f :QuicklyFind<space>
  nnoremap <leader>p :QuicklyAny<space>
  nnoremap <c-p> :QuicklyAny<space>
endif
