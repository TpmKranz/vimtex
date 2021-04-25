set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

let g:vimtex_cache_root = '.'
let g:vimtex_cache_persistent = 0

let s:tex_filename = expand('<sfile>:r') . '.tex'
let s:bcf_filename = expand('<sfile>:r') . '.bcf'
let s:bibs_and_counts = [
      \ [ 'test_globbe*.bib', 3],
      \ [ 'test_globbed_?.bib', 2],
      \ [ 'test_globbed_{1,2}.bib', 2],
      \ ]
function! PrepareTexFile(bib)
  call writefile([
        \ '\documentclass{minimal}',
        \ '\usepackage{biblatex}',
        \ '\addbibresource{' . a:bib . '}',
        \ '\begin{document}',
        \ 'Hello World!',
        \ '\end{document}',
        \], s:tex_filename)
endfunction

function! PrepareBcfFile(bib)
  call writefile([ '<bcf:datasource type="file" datatype="bibtex" glob="false">'
        \ . a:bib . '</bcf:datasource>'], s:bcf_filename)
endfunction

function! RunTest(count)
  let s:candidates = vimtex#test#completion('\cite{', '')
  call vimtex#test#assert_equal(a:count, len(s:candidates))
endfunction

function! CleanUp()
  if filereadable(s:tex_filename) | call delete(s:tex_filename) | endif
  if filereadable(s:bcf_filename) | call delete(s:bcf_filename) | endif
endfunction 


call CleanUp()

for [s:bib, s:count] in s:bibs_and_counts
  call PrepareTexFile(s:bib)
  silent execute 'edit' s:tex_filename
  if empty($INMAKE) | finish | endif

  " Without a bcf file, this runs files_manual:
  call vimtex#test#assert(!filereadable(s:bcf_filename))
  call RunTest(s:count)

  call PrepareBcfFile(s:bib)
  " With a bcf file, this runs the biblatex-specific logic:
  call vimtex#test#assert(filereadable(s:bcf_filename))
  call RunTest(s:count)

  bwipeout!
  call CleanUp()
endfor

quit!
