"============================================================================
" outline.vim
" Author:      Takeshi Takatsudo <takazudo@gmail.com>
" Version:     0.3
" LastUpdate:  2009-11-28
" License:    Licensed under the same terms as Vim itself.
" 
" Usage: Exe :Oo (:OutlineOpen) in the commented document.
"        outline.vim will creates outlineBuf window.
"        Try :Oo in the sample.css or sample.js.
" 
" 			/**
" 			 * treeNode1
" 			 */
" 			something here something here
" 			something here something here
" 
" 				/**
" 				 * treeNode1-1
" 				 */
" 				something here something here
" 				something here something here
" 
" 
" 	# Commands and Keybinds in the outlineBuf
" 
" 	   q        quit the outlineBuf (= :Oc or :OutlineClose)
" 	   r        refresh the outlineBuf (= :Or or :OutlineRefresh)
" 	   <Enter>  associated line in the parentBuf will be focused.
" 	            (= :Oj or :OutlineJump)
" 
" 	# Commands in the parentBuf
"
" 	   :Oo (:OutlineOpen)      start outline.
" 	   :Oc (:OutlineClose)     same command in the outlineBuf.
" 	   :Or (:OutlineRefresh)   same command in the outlineBuf.
" 	   :ToO (:ToOutline)       Associated line in the outlineBuf
" 	                           will be focused.
" 
" 	see http://github.com/Takazudo/outline.vim
" 	for newer version.
" 
"============================================================================

" avoid load this script.
if exists('g:loaded_outline')
	finish
endif

" commands
command! OutlineOpen call g:Outline_Open()
command! OutlineRefresh call g:Outline_Refresh()
command! OutlineJump call g:Outline_Jump()
command! OutlineClose call g:Outline_Close()
command! ToOutline call g:Outline_to()

" shoftcut commands
command! Oo OutlineOpen
command! Or OutlineRefresh
command! Oj OutlineJump
command! Oc OutlineClose
command! ToO ToOutline

" setting
let g:outline_winSize = '30'
	"outlineBuf's window width
let g:outline_winEnterRefresh = '1'
	"set 0 if you dont want to refresh outlineBuf automatically

" command interface
fun! g:Outline_Open()
	call s:Open()
endfun
fun! g:Outline_Refresh()
	call s:Refresh()
endfun
fun! g:Outline_Jump()
	call s:Jump()
endfun
fun! g:Outline_Close()
	call s:Close()
endfun
fun! g:Outline_to()
	call s:ToOutline()
endfun

"============================================
" BindOutlineBufKeys
"	set keybind in outlineBuf.
"
fun! s:BindOutlineBufKeys()
	nnoremap <buffer> i <ESC>
	nnoremap <buffer> r :OutlineRefresh<CR>
	nnoremap <buffer> q :OutlineClose<CR>
	nnoremap <buffer> <Enter> :OutlineJump<CR>
endfun

"============================================
" Jump
"	find the related point in the parentBuf.
"
fun! s:Jump()
	let items = b:items
	let curLineNum = line('.')
	let targetWin = bufwinnr(b:parentBuf)
	execute targetWin . 'wincmd w'
	let parentLineNum = 0
	for item in items
		if item.outlineBufLineNum == curLineNum
			let parentLineNum = item.parentLineNum
		endif
	endfor
	execute 'silent normal' . parentLineNum . 'gg'
endfun

"============================================
" Open
"	executed in parentBuf.
"	create the outline buf.
"
fun! s:Open()
	let curBuf = bufnr('%')
	autocmd BufWrite <buffer> call g:Outline_Refresh()
	if !exists('b:outlineBufName')
		"define outlineBufname
		let b:outlineBufName = 'outline_' . curBuf
	endif
	if !bufexists(b:outlineBufName)
		"create buf if the outlineBuf doesnot exist
		let b:outlineBuf = bufnr(b:outlineBufName, 1)
	endif
	let w = bufwinnr(b:outlineBuf)
	if w == -1
		"window seems not to be opened yet
		execute 'vert leftabove '.g:outline_winSize.'split'
		execute 'buffer ' . b:outlineBuf
		let b:parentBuf = curBuf
		let &buftype = 'nofile'
		setlocal nowrap
		"match Comment /./
		"setlocal tabstop=3
		if g:outline_winEnterRefresh == 1
			autocmd WinEnter <buffer> call g:Outline_Refresh()
		endif
	else
		"window detected. focus it.
		execute w . 'wincmd w'
	endif
	call s:Refresh()
	call s:BindOutlineBufKeys()
endfun

"============================================
" Refresh
"	refresh the outlineBuf's text
"
fun! s:Refresh()

	let inParentBuf = 0
		"var to detect in parentBuf or not first.

	if exists('b:outlineBufName')
		"this is the parentBuf
		if bufexists(b:outlineBufName)
			"outlineBuf detected. focus the outlineBuf
			let win = bufwinnr(b:outlineBuf)
			"outlineBuf detected. focus the outlineBuf
			if win == -1
				return
					"outlineBuf detected. but it seems to be in other GUI tab
			else
				execute win . 'wincmd w'
			endif
			let inParentBuf = 1
		else
			"no outlineBuf detected. stop this.
			return
		endif
	elseif exists('b:parentBuf')
		"this is the outlineBuf. continue this process.
	else
		"outlineBuf was not found. just return.
		return
	endif

	"update dict then refresh buffer.
	call s:UpdateDict()
	let i = 1
	setlocal modifiable
	silent normal gg"_dG
		"clear buffer. avoid clipboard hijack
	for cur in b:items
	  call setline(i,cur.indexStr)
	  let i += 1
	endfor
	setlocal nomodifiable

	"if was is parentBuf, return there
	if inParentBuf
		execute bufwinnr(b:parentBuf) . 'wincmd w'
	endif

endfun

"============================================
" UpdateDict
"	refresh dict from parentBuf.
"
fun! s:UpdateDict()

	let b:items = []
	let lines = getbufline(b:parentBuf,0,'$')
	let l = len(lines)
	let i = 0
	let j = 1
	
	while i<l
		let curStr = get(lines,i)
		let curMatched = match(curStr,'^\t*\/\*\*')
			" does this line start with '/**' ?
		if curMatched != -1
			let nextNum = i+1
			let nextStr = get(lines,nextNum)
			let nextMatched = match(nextStr,'^\t* \* .\+$')
				" does next line start with ' * sometext' ?
			if nextMatched != -1
				let item = {}
				"let nextStr = substitute(nextStr,'\t','-  ','g')
				let nextStr = substitute(nextStr,' \* ','','g')
				let item.parentLineNum = i+1
				let item.indexStr = nextStr
				let item.outlineBufLineNum = j
				call add(b:items,item)
					" each item is like this
					" {
					"     parentLineNum: 30,
					"     indexStr: someTextForIndexTitle,
					"     outlineBufLineNum: 3
					" }
				let j += 1
			endif
		endif
		let i += 1
	endwhile

endfun

"============================================
" Close
"	close the outline.
"
fun! s:Close()
	if exists('b:parentBuf')
		bwipeout
	elseif exists('b:outlineBufName') && bufexists(b:outlineBuf)
		exe "bwipeout " . b:outlineBuf
	endif
endfun

"============================================
" ToOutline
"	jump to the associated line in the outlineBuf.
"
fun! s:ToOutline()
	if exists('b:parentBuf')
		"do nothing if outlineBuf
		return
	endif
	if !exists('b:outlineBuf')
		"do nothing if no outlineBuf
		return
	endif
	let curLineNum = line('.')
	let w = bufwinnr(b:outlineBuf)
	if w == -1
		"return if no outlineBuf
		return
	endif
	execute w . 'wincmd w'
	let i = 0
	let outlineBufLineNum = line('$')
	let found = 0
	let prevItem = {}
	"find the line in the outlineBuf
	for item in b:items
		if item.parentLineNum > curLineNum && found == 0
			if found == 0
				let outlineBufLineNum = prevItem.outlineBufLineNum
				let found = 1
			endif
		endif
		let prevItem = item
		let i += 1
	endfor
	execute 'silent normal' . outlineBufLineNum . 'gg'
endfun

