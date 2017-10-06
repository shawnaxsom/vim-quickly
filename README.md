vim-quickly
===========

Quickly jump to files. Cozy up to :find, :buffer, and :oldfiles.

Vim-Quickly is designed as a minimal yet powerful solution for jumping to files quickly. It combines the ease-of-use of solutions like [CtrlP](https://github.com/kien/ctrlp.vim) and [FZF](https://github.com/junegunn/fzf.vim), while staying minimal like :find, :buffer, :oldfiles, and :bdelete.


Motivation
----------

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


Usage
-----

The all-in-one jump command is:

```vim
  :QuicklyAny SOME FILE PATTERNS<TAB>
```

_QuicklyAny_ will search Buffers, then MRU, and then fall back to a slower :!find <term> command if nothing was found yet.

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


Mappings
--------

Default mappings are:

    nnoremap <leader><leader>c :QuicklyBufferDelete<space>
    nnoremap <leader>b :QuicklyBuffer<space>
    nnoremap <leader>o :QuicklyMru<space>
    nnoremap <leader>f :QuicklyFind<space>
    nnoremap <leader>p :QuicklyAny<space>
    nnoremap <c-p> :QuicklyAny<space>

Default mappings can be disabled with:

    let g:quickly_disable_default_key_mappings = 1


Reusability
-----------

All of the commands use a few simple, reusable methods. Feel free to contribute, or add some of your own commands to your .vimrc or init.vim.

Look at the quickly.vim file for the commands:

    ~/.vim/bundle/vim-quickly/plugin/quickly.vim


