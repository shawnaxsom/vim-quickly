" quickly.vim - Quickly jump to files. Cozy :find, :buffer, and :oldfiles replacements.
" Maintainer:   Shawn Axsom <axs221@gmail.com>
" Version:      0.0.4
" License:      MIT
" Website:      https://github.com/axs221/vim-quickly

" --------------------------------------------------------------
"  Options
" --------------------------------------------------------------

" Enable default key mappings
let g:quickly_enable_default_key_mappings = get(g:, 'quickly_enable_default_key_mappings', 1)

" Jump to first result even if there are multiple matches.
let g:quickly_always_jump_to_first_result = get(g:, 'quickly_always_jump_to_first_result', 0)

" Open quickfix window when there are multiple matches.
let g:quickly_open_quickfix_window = get(g:, 'quickly_open_quickfix_window', 1)

" Location to store file path of MRU file
let g:quickly_mru_file_path = get(g:, 'quickly_mru_file_path', $HOME."/.quickly_mru")


" --------------------------------------------------------------
"  Maybe - Return string or default of empty
" --------------------------------------------------------------
function! Maybe(str)
  let str = a:str
  if !exists('a:str')
    let str = ''
  endif

  return str
endfunction

" --------------------------------------------------------------
"  FirstWord - Return first word in string, or empty string
" --------------------------------------------------------------
function! FirstWord(str)
  let firstArg = ''
  if a:str != ''
    let firstArg = split(a:str, ' ')[0]
  endif
  return firstArg
endfunction


" --------------------------------------------------------------
"  WithinPwd - Filter out lines that aren't within PWD.
"              Only absolute paths are filtered.
" --------------------------------------------------------------
function! WithinPwd (lines)
  return filter(a:lines, 'v:val =~ getcwd() || v:val !~ "^\/.*"')
endfunction

" --------------------------------------------------------------
"  RelativePath - Truncate PWD, for e.g. absolute paths found in v:oldfiles
" --------------------------------------------------------------
function! RelativePath (lines)
  return map(copy(a:lines), 'substitute(v:val, getcwd() . "/", "", "g")')
endfunction

" --------------------------------------------------------------
"  Dedup - Remove duplicates from an array.
"          Preserve order. Keep duplicate with lowest index.
" --------------------------------------------------------------
function! Dedup (lines)
  if !exists("a:lines")
    return []
  endif

  " Reverse lines, to ensure first result is the one kept.
  " (index() looks for matches after current position)
  let lines = reverse(copy(a:lines))
  " Filter mutates state. Compare with cloned list,
  " otherwise (['b', 'b', 'a', 'b']) == ['b', 'b', 'a']
  let reverselines = reverse(copy(a:lines))
  let filtered = filter(lines, 'index(reverselines, v:val, v:key+1)==-1')
  return reverse(filtered)
endfunction

" --------------------------------------------------------------
"  Wildignore - Remove lines that match any pattern found in 'set wildignore'
"               Note that QuicklyFind will also use these patterns, but this
"               applies across the board for all types of Quickly commands.
"               It is of course faster to apply the filters earlier on in the
"               process, but this function acts as a safeguard.
" --------------------------------------------------------------
function! Wildignore (lines)
  let lines = a:lines

  for ignorePattern in split(&wildignore, ",")
    let ignoreRegex = glob2regpat(ignorePattern)
    let lines = filter(lines, 'v:val !~ "' . ignoreRegex . '"')
  endfor

  return lines
endfunction


" --------------------------------------------------------------
"  FilterCurrentFile - Filter out the current filename from the list
" --------------------------------------------------------------
function! FilterCurrentFile (lines)
  if !exists("a:lines")
    return []
  endif

  return filter(a:lines, 'v:val != expand("%")')
endfunction

" --------------------------------------------------------------
"  FilterBlankLines - Filter out blank lines from an array
" --------------------------------------------------------------
function! FilterBlankLines (lines)
  if !exists("a:lines")
    return []
  endif

  return filter(a:lines, 'v:val != ""')
endfunction

" --------------------------------------------------------------
"  ListComplete - Completion on pressing <Tab> (or your preferred completion mapping)
" --------------------------------------------------------------
function! ListComplete(lines, ArgLead, CmdLine, CursorPos)
  let lines = a:lines

  for word in split(a:CmdLine, " ")[1:]
    let lines = filter(lines, 'v:val =~ "' . word . '"')
  endfor

  let lines = Dedup(lines)
  let lines = FilterCurrentFile(lines)
  let lines = FilterBlankLines(lines)
  let lines = Wildignore(lines)

  return lines
endfunction

" --------------------------------------------------------------
"  GetMatches - Filter lines by one or more arguments
" --------------------------------------------------------------
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
  let lines = FilterCurrentFile(lines)
  let lines = Wildignore(lines)

  " Remove relative path prefix, not necessary if your path is correct and can
  " lead to duplicates if some have relative path and some don't.
  let lines = Dedup(map(copy(lines), 'substitute(v:val, "^./", "", "g")'))

  return lines
endfunction
function! QuickfixOrGotoFile (lines, arg)
  let lines = GetMatches(a:lines, a:arg)

  if len(lines) > 0
    if len(lines) == 1 || g:quickly_always_jump_to_first_result == 1
      execute 'e ' . lines[0]
    endif

    if len(lines) > 1
      let data = map(copy(lines), '{"filename": v:val, "text": "", "lnum": ""}')
      call setqflist(data)

      if g:quickly_open_quickfix_window == 1
        copen
      endif
    endif
  endif
endfunction


" --------------------------------------------------------------
"  :QuicklyMru
" --------------------------------------------------------------
" TODO: Keep using Oldfiles, or add option for project local file?
" function! SaveMru ()
"   let current_file = expand('%')
"   if len(current_file) > 0
"     call system("echo " . current_file . " >> " . g:quickly_mru_file_path)
"   endif
" endfunction
" augroup saveMru
"   autocmd!
"   autocmd BufEnter * call SaveMru()
" augroup END
function! SaveMru ()
  let current_file = expand('%:p')
  if len(current_file) > 0
    let v:oldfiles = extend([ current_file, ], v:oldfiles)
  endif
endfunction
augroup saveMru
  autocmd!
  autocmd BufEnter * call SaveMru()
augroup END

function! MruLines ()
  let lines = []
  let lines = extend(lines, copy(v:oldfiles))
  let lines = WithinPwd(lines)
  let lines = RelativePath(lines)
  return lines
endfunction
function! MruComplete (ArgLead, CmdLine, CursorPos)
  return ListComplete(MruLines(), a:ArgLead, a:CmdLine, a:CursorPos)
endfunction
function! MruQuickfixOrGotoFile (arg)
  call QuickfixOrGotoFile(MruLines(), a:arg)
endfunction
command! -nargs=* -complete=customlist,MruComplete QuicklyMru call MruQuickfixOrGotoFile(<q-args>)


" --------------------------------------------------------------
"  :QuicklyMostRecentlyModified
" --------------------------------------------------------------
function! MostRecentlyModifiedLines (ArgLead, Count)
  let argLead = Maybe(a:ArgLead)

  if argLead =~ '\.\/.*' || argLead =~ '\/.*'
    " User must have used completion, last argument is probably full path
    let args = split(argLead, ' ')
    return [ args[len(args) - 1] ]
  endif

  let firstArg = FirstWord(argLead)

  let lines = split(system("find . -type d \\( -path ./.git -o -path ./node_modules \\) -prune -o -path '*" . firstArg . "*' -print0 | xargs -0 ls -t | head -n " . a:Count), "\n")
  let lines = WithinPwd(lines)
  let lines = RelativePath(lines)
  return lines
endfunction
function! MostRecentlyModifiedComplete (ArgLead, CmdLine, CursorPos)
  return ListComplete(MostRecentlyModifiedLines(Maybe(a:ArgLead), 50), Maybe(a:ArgLead), Maybe(a:CmdLine), a:CursorPos)
endfunction
function! MostRecentlyModifiedQuickfixOrGotoFile (arg)
  call QuickfixOrGotoFile(MostRecentlyModifiedLines(a:arg, 50), a:arg)
endfunction
command! -nargs=* -complete=customlist,MostRecentlyModifiedComplete QuicklyMostRecentlyModified call MostRecentlyModifiedQuickfixOrGotoFile(<q-args>)

" --------------------------------------------------------------
"  :QuicklyWhatChanged
" --------------------------------------------------------------
function! WhatChangedLines ()
  let lines = split(system("git whatchanged --oneline --name-only --since='1 month ago' --pretty=format:"), "\n")
  if len(lines) == 0
    let lines = split(system("git whatchanged --oneline --name-only --since='1 year ago' --pretty=format:"), "\n")
  endif

  let lines = WithinPwd(lines)
  let lines = RelativePath(lines)
  return lines
endfunction
function! WhatChangedComplete (ArgLead, CmdLine, CursorPos)
  return ListComplete(WhatChangedLines(), a:ArgLead, a:CmdLine, a:CursorPos)
endfunction
function! WhatChangedQuickfixOrGotoFile (arg)
  call QuickfixOrGotoFile(WhatChangedLines(), a:arg)
endfunction
command! -nargs=* -complete=customlist,WhatChangedComplete QuicklyWhatChanged call WhatChangedQuickfixOrGotoFile(<q-args>)

" --------------------------------------------------------------
"  :QuicklyBufferDelete
" --------------------------------------------------------------
function! BufferLines ()
  let lines = extend(map(filter(range(1, bufnr('$')), 'bufloaded(v:val)'), 'bufname(v:val)'),
    \ map(filter(range(1, bufnr('$')), 'buflisted(v:val)'), 'bufname(v:val)'))

  let lines = WithinPwd(lines)
  let lines = RelativePath(lines)
  return lines
endfunction
function! BufferComplete (ArgLead, CmdLine, CursorPos)
  return ListComplete(BufferLines(), a:ArgLead, a:CmdLine, a:CursorPos)
endfunction
function! BufferQuickfixOrGotoFile (arg)
  call QuickfixOrGotoFile(BufferLines(), a:arg)
endfunction
command! -nargs=* -complete=customlist,BufferComplete QuicklyBuffer call BufferQuickfixOrGotoFile(<q-args>)


" --------------------------------------------------------------
"  :QuicklyBufferDelete
" --------------------------------------------------------------
function! BufferDelete (arg)
  let lines = GetMatches(BufferLines(), a:arg)

  if len(lines) > 0
    for line in lines
      execute 'bd '.line
    endfor
  endif
endfunction
command! -nargs=* -complete=customlist,BufferComplete QuicklyBufferDelete call BufferDelete(<q-args>)


" --------------------------------------------------------------
"  :QuicklyFind
" --------------------------------------------------------------
function! FindLines (ArgLead)
  let argLead = Maybe(a:ArgLead)

  if argLead =~ '\.\/.*' || argLead =~ '\/.*'
    " User must have used completion, last argument is probably full path
    let args = split(argLead, ' ')
    return [ args[len(args) - 1] ]
  endif

  " Just uses the first word if there are multiple. A little slower
  " but more flexible in ordering of words and subdirectories.
  " Other words get filtered out in QuickfixOrGotoFile()
  let firstArg = ''
  if argLead != ''
    let firstArg = split(argLead, ' ')[0]
  endif

  if executable('rg')
    let ignoreClause = ''
    for ignorePattern in split(&wildignore, ",")
      let ignoreClause  = ignoreClause . ' --iglob "!' . ignorePattern . '"'
    endfor
    let command = "rg --files --hidden --glob '*" . firstArg . "*' " . ignoreClause

    let lines = split(system(command), '\n')
  elseif executable('ag')
    let ignoreClause = ''
    for ignorePattern in split(&wildignore, ",")
      let ignoreClause  = ignoreClause . ' --ignore "' . ignorePattern . '"'
    endfor
    let command = "ag --nocolor --nogroup --hidden -g " . firstArg . " " . ignoreClause

    let lines = split(system(command), '\n')
  elseif executable('find')
    let ignoreClause = '-not -path "*/node_modules/*" -not -path "*/.git/*" -not -path "*/bower_components/*"'
    for ignorePattern in split(&wildignore, ",")
      let ignoreClause  = ignoreClause . ' -not -path "' . ignorePattern . '"'
    endfor
    let command = "find . -path '*" . firstArg . "*' -type f " . ignoreClause

    let lines = split(system(command), '\n')
  else
    let lines = globpath('.', '**/*' . firstArg . '*', 0, 1)
  endif

  let lines = WithinPwd(lines)
  let lines = RelativePath(lines)
  return lines
endfunction
function! FindComplete (ArgLead, CmdLine, CursorPos)
  return ListComplete(FindLines(Maybe(a:ArgLead)), Maybe(a:ArgLead), Maybe(a:CmdLine), a:CursorPos)
endfunction
function! FindQuickfixOrGotoFile (arg)
  call QuickfixOrGotoFile(FindLines(a:arg), a:arg)
endfunction
command! -nargs=* -complete=customlist,FindComplete QuicklyFind call FindQuickfixOrGotoFile(<q-args>)


" --------------------------------------------------------------
"  :QuicklyAny
" --------------------------------------------------------------
function! AnyLines (ArgLead)
  let lines = GetMatches(MostRecentlyModifiedLines(a:ArgLead, 5), a:ArgLead)
  let lines = Dedup(extend(lines, GetMatches(BufferLines(), a:ArgLead)))
  let lines = Dedup(extend(lines, GetMatches(MruLines(), a:ArgLead)))
  let lines = Dedup(extend(lines, GetMatches(WhatChangedLines(), a:ArgLead)))

  if len(lines) == 0
    let lines = extend(lines, FindLines(a:ArgLead))
  endif

  let lines = WithinPwd(lines)
  let lines = RelativePath(lines)
  return lines
endfunction

function! AnyComplete (ArgLead, CmdLine, CursorPos)
  return ListComplete(AnyLines(a:ArgLead), a:ArgLead, a:CmdLine, a:CursorPos)
endfunction
function! AnyQuickfixOrGotoFile (arg)
  call QuickfixOrGotoFile(AnyLines(a:arg), a:arg)
endfunction
command! -nargs=* -complete=customlist,AnyComplete QuicklyAny call AnyQuickfixOrGotoFile(<q-args>)

" --------------------------------------------------------------
"  Default Key Mappings
" --------------------------------------------------------------
if g:quickly_enable_default_key_mappings == 1
  nnoremap <leader><leader>c :QuicklyBufferDelete<space>
  nnoremap <leader>b :QuicklyBuffer<space>
  nnoremap <leader>o :QuicklyMru<space>
  nnoremap <leader>m :QuicklyMostRecentlyModified<space>
  nnoremap <leader>f :QuicklyFind<space>
  nnoremap <leader>p :QuicklyAny<space>
  nnoremap <leader>W :QuicklyWhatChanged<space>
  nnoremap <c-p> :QuicklyAny<space>
endif
