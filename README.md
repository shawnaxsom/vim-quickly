# vim-quickly

Quickly jump to files. Cozy up to :find, :buffer, and :oldfiles.

Vim-Quickly is designed as a minimal yet powerful solution for jumping to files quickly. It combines the ease-of-use of solutions like [CtrlP](https://github.com/kien/ctrlp.vim) and [FZF](https://github.com/junegunn/fzf.vim), while staying minimal like :find, :buffer, :oldfiles, and :bdelete.


# Motivation

I used to be a die-hard [CtrlP](https://github.com/kien/ctrlp.vim) user. Then [romainl](https://www.reddit.com/user/-romainl-/) finally got through to me. While I disagree with the brash sentiment that plugins are a bad thing, there is something to be said for minimalism and for at least trying out what Vim provides.

What I found with built-in file-jumping capabilities was promising, but unfulfilling:

```vim
:filter /.js/ browse oldfiles
:browse oldfiles
:map <leader>b :ls<CR>:b<space>
:find **/*
```

While I loved the speed and minimalism, what was missing for me was:

* Allowing fallback when no results are found.
* Loading results in the Quickfix window if multiple results are found.
* Allowing multiple search terms in any order.
* Don't use fuzzy matching, since it often results in many false positives.
* Match each term on full path, without having to use |starstar|.
* Extensible, with functions composable and reusable for any file lists.


# Usage

The all-in-one jump command is:

```vim
  :QuicklyAny SOME FILE PATTERNS<TAB>
```

_QuicklyAny_ will search Buffers, then MRU, and then fall back to standard file search if no matches are found.

QuicklyAny (and QuicklyFind) will use ag, rg, or find, if those commands exist on the system. Otherwise, the built-in (but slower) globpath() is used.

The file patterns can be in any order. Search is NOT fuzzy (for faster performance and less false positives). File patterns can match file name or path.


You can also use the individual mappings:

```vim
  :QuicklyBuffer SOME FILE PATTERNS<TAB>
  :QuicklyMru SOME FILE PATTERNS<TAB>
  :QuicklyFind SOME FILE PATTERNS<TAB>
```

And finally, to keep those buffers tidy, a convenience command is added to delete buffers:


```vim
  :QuicklyBufferDelete SOME FILE PATTERNS<TAB>
```


## Example
Given the following files:

    ~/projects/web/src/routes/todos/list/edit.js
    ~/projects/web/src/routes/todos/list/view.js

Make sure you are in the working directory:

```vim
  :cd ~/projects/web/
```

You can quickly jump to the edit file like so:

```vim
  :QuicklyFind edit todo route<TAB>
```

Or for multiple matches, it will populate the quickfix window:

```vim
  :QuicklyFind todo route<TAB>
  :cnext
  :cprev
  :cclose
  :copen
  :map ]c :cnext<CR>
  :map [c :cprev<CR>
```

After exiting Vim, if you want to revisit the file (assuming :oldfiles is set up correctly utilizing your ShaDa or viminfo file)

```vim
  :QuicklyMru edit todo route<TAB>
```

Or, if you use mksession, vim-workspace, vim-obsession, or the like, the buffer might still be loaded to jump to as well:

```vim
  :QuicklyBuffer edit todo route<TAB>
```

And, lets say you move on to a new task, and todo routes are no longer relevant to you:

```vim
  :QuicklyBufferDelete todo route
```


Best of all, you can combine the Buffer / MRU / Find commands with QuicklyAny

```vim
  :QuicklyAny edit todo route<TAB>
```

QuicklyAny will stop at Buffer or MRU results if any results are found, to avoid the slower Find command.


# Mappings

Default mappings are:

    nnoremap <leader><leader>c :QuicklyBufferDelete<space>
    nnoremap <leader>b :QuicklyBuffer<space>
    nnoremap <leader>o :QuicklyMru<space>
    nnoremap <leader>f :QuicklyFind<space>
    nnoremap <leader>p :QuicklyAny<space>
    nnoremap <c-p> :QuicklyAny<space>

Default mappings can be disabled with:

    let g:quickly_enable_default_key_mappings = 0


# Configuration

```vim
    " Jump to first result on pressing <Enter>, even with multiple matches.
    let g:quickly_always_jump_to_first_result = 1

    " Open |quickfix| window when there are multiple matches.
    let g:quickly_open_quickfix_window = 1

    " Enable default key mappings. See |quickly-mappings|.
    let g:quickly_enable_default_key_mappings = 1
```


# Tips

* Look at :help vim-quickly. I am keeping that up-to-date the best I can. More details are provided there.
* Set up your wildignore settings. Vim-Quickly will respect wildignore to ignore paths to files you are never interested in.
* Change your ShaDa or viminfo settings. QuicklyMru (and therefore MRU within QuicklyAny) both use :oldfiles, which is limited in history length based on ShaDa (for Neovim) or viminfo (for Vim).

# Reusability

All of the commands use a few simple, reusable methods. Feel free to contribute, or add some of your own commands to your .vimrc or init.vim.

Look at the quickly.vim file for the commands:

    ~/.vim/bundle/vim-quickly/plugin/quickly.vim

There you will find the main commands, along with useful, simple helper functions.

* ListComplete - Runs after pressing <Tab>, provide it an array of filepaths and arguments to filter with
* QuickfixOrGotoFile - Runs after pressing <Enter>, provide it an array similarly, and it will edit single results, or populate the quickfix window.

Below is an example of a custom command.

Try it out!

Lets assume you are a dork with a markdown file of habits you are working on in your $HOME, that will jump you to that file.

```bash
$ touch ~/habits.scratch.md
```

Then:

1. Add the code below to your .vimrc or init.vim.
2. :source ~/.vimrc or :source ~/.config/nvim/init.vim
3. Try: :QuicklyFavoriteFiles habit md<TAB>
4. Try: <leader>F habit md<TAB>


```vim
function! FavoriteFilesLines ()
  " List of my favoritest files in the world.
  return ['~/codi/codi.js', '~/habits.scratch.md']
endfunction
function! FavoriteFilesComplete (ArgLead, CmdLine, CursorPos)
  return ListComplete(FavoriteFilesLines(), a:ArgLead, a:CmdLine, a:CursorPos)
endfunction
function! FavoriteFilesQuickfixOrGotoFile (arg)
  call QuickfixOrGotoFile(FavoriteFilesLines(), a:arg)
endfunction
command! -nargs=* -complete=customlist,FavoriteFilesComplete QuicklyFavoriteFiles call FavoriteFilesQuickfixOrGotoFile(<q-args>)
nnoremap <leader>F :QuicklyFavoriteFiles<space>
```

Even better, we can use the results of system commands.

Here is an example of showing files recently modified in GitHub from any author. You could always modify the parameters as you like, limiting to just your user. Or you could use input() to prompt for the time range.

```vim
function! WhatChangedLines ()
  return split(system("git whatchanged --oneline --name-only --since='1 month ago' --pretty=format:"), "\n")
endfunction
function! WhatChangedComplete (ArgLead, CmdLine, CursorPos)
  return ListComplete(WhatChangedLines(), a:ArgLead, a:CmdLine, a:CursorPos)
endfunction
function! WhatChangedQuickfixOrGotoFile (arg)
  call QuickfixOrGotoFile(WhatChangedLines(), a:arg)
endfunction
command! -nargs=* -complete=customlist,WhatChangedComplete QuicklyWhatChanged call WhatChangedQuickfixOrGotoFile(<q-args>)
nnoremap <leader>W :QuicklyWhatChanged<space>
```

You could then even go on to change :QuicklyAny to also use WhatChanged as another last resort before falling back to the slower QuicklyFind (the one that searches all filenames in your PWD)

```vim
" Override AnyLines, so that :QuicklyAny will use :QuicklyWhatChanged as a last fallback, before resorting to slow directory search.
function! AnyLines (ArgLead)
  let lines = GetMatches(BufferLines(), a:ArgLead)
  let lines = Dedup(extend(lines, GetMatches(MruLines(), a:ArgLead)))
  let lines = Dedup(extend(lines, GetMatches(WhatChangedLines(), a:ArgLead)))

  if len(lines) == 0
    let lines = extend(lines, FilesLines(a:ArgLead))
  endif
  return lines
endfunction
```
