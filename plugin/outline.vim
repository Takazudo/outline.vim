"============================================================================
" outline.vim
" Author:      Takeshi Takatsudo <takazudo@gmail.com>
" Version:     0.4
" LastUpdate:  2009-11-29
" License:    Licensed under the same terms as Vim itself.
" 
" Usage: Exe :Oo (:OutlineOpen) in the commented document.
"        This plugin creates outlineBuf window.
"        Open sample.js and try :Oo
" 
" 	# Keybinds in the outlineBuf
" 
" 	   q        quit the outlineBuf (= :Oc or :OutlineClose)
" 	   r        refresh the outlineBuf (= :Or or :OutlineRefresh)
" 	   <Enter>  associated line in the parentBuf will be focused.
" 	            (= :Oj or :OutlineJump)
" 
" 	# Commands
"
" 	   :Oo (:OutlineOpen)      Open outlineBuf.
" 	   :Oc (:OutlineClose)     Close outlineBuf.
" 	   :Or (:OutlineRefresh)   Refresh outlineBuf.
" 	   :ToO (:ToOutline)       Associated line in the outlineBuf will be focused.
" 	                           This command is effective only in parentBuf.
" 
" 	Check "http://github.com/Takazudo/outline.vim" for newer version.
" 
"============================================================================

" setting
let g:outline_winSize = 30
	"outlineBuf's window width
let g:outline_enableAutoRefresh = 1
	"set 0 if you dont want to refresh outlineBuf automatically
let g:outline_enableAutoFocus = 1
	"set 0 if you dont want to focus the node automatically

"============================================================================

" set g:loaded_outline = 1 to avoid load this script.
if exists('g:loaded_outline')
	finish
else
	let g:loaded_outline = 1
endif

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
fun! g:Outline_toOutline()
	call s:ToOutline()
endfun

" vars to store history
let g:outline_lastBufName = 0
let g:outline_lastBufLineNum = 0


"============================================
" g:Outline_saveLastBuf
"	save last buf and line num to autoFocus.
"
fun! g:Outline_saveLastBuf()
	let g:outline_lastBufName = bufnr('%')
	let g:outline_lastBufLineNum = line('.')
endfun

"============================================
" g:Outline_autoFocus
"	go to assoc node if last buf was parentBuf.
"
fun! g:Outline_autoFocus()
	if !s:IsInOutlineBuf()
		return
	endif
	if g:outline_lastBufName == b:parentBuf
		let line = s:GetAssocLineNum(g:outline_lastBufLineNum)
		execute 'silent normal' . line . 'gg'
	endif
endfun

"============================================
" Init
"	find the related point in the parentBuf.
"
fun! s:Init()

	" commands
	command! OutlineOpen call g:Outline_Open()
	command! OutlineRefresh call g:Outline_Refresh()
	command! OutlineJump call g:Outline_Jump()
	command! OutlineClose call g:Outline_Close()
	command! ToOutline call g:Outline_toOutline()

	" shoftcut commands
	command! Oo OutlineOpen
	command! Or OutlineRefresh
	command! Oj OutlineJump
	command! Oc OutlineClose
	command! ToO ToOutline
	
	if g:outline_enableAutoFocus
		autocmd WinLeave * call g:Outline_saveLastBuf()
	endif

endfun

" init first
call s:Init()

"============================================
" Jump
"	find the related point in the parentBuf.
"
fun! s:Jump()
	
	if !s:FindParentWin()
		return
	endif

	let items = b:outlineItems
	let curLineNum = line('.')

	call s:MoveToParent()

	let parentLineNum = 0
	for item in items
		if item.outlineBufLineNum == curLineNum
			let parentLineNum = item.parentLineNum
		endif
	endfor
	execute 'silent normal' . parentLineNum . 'gg'

endfun

"============================================
" s:Open
"	create outlineBuf.
"
fun! s:Open()
	if s:FindOutlineWin()
		return
	endif
	call s:InitParentBuf()
	let parentBuf = bufnr('%')
	let b:outlineBuf = bufnr(b:outlineBufName, 1)
	execute 'vert leftabove '.g:outline_winSize.'split'
	execute 'buffer ' . b:outlineBuf
	let b:parentBuf = parentBuf
	call s:InitOutlinBuf()
	call s:Refresh()
	call s:MoveToParent()
endfun

	"============================================
	" s:InitParentBuf
	" 	define outlineBuf's name
	"
	fun! s:InitParentBuf()
		if exists('b:outlineBufName')
			return
		endif
		let b:outlineBufName = 'outline_' . bufnr('%')
		autocmd BufWrite <buffer> call g:Outline_Refresh()
	endfun

	"============================================
	" s:InitOutlinBuf
	"
	fun! s:InitOutlinBuf()
		let &buftype = 'nofile'
		setlocal nowrap
		setlocal tabstop=3
			"need to define as filetype setting?
		if g:outline_enableAutoRefresh
			autocmd WinEnter <buffer> call g:Outline_Refresh()
		endif
		if g:outline_enableAutoFocus
			autocmd WinEnter <buffer> call g:Outline_autoFocus()
		endif
		nnoremap <buffer> i <ESC>
		nnoremap <buffer> r :OutlineRefresh<CR>
		nnoremap <buffer> q :OutlineClose<CR>
		nnoremap <buffer> <Enter> :OutlineJump<CR>
	endfun

"============================================
" Refresh
"	start refresh process
"
fun! s:Refresh()
	
	let wasInParentBuf = 0
	let wasInOutlineBuf = 0
	if s:FindOutlineWin()
		let wasInParentBuf = 1
	endif
	if s:FindParentWin()
		let wasInOutlineBuf = 1
	endif

	if !wasInParentBuf && !wasInOutlineBuf
		return
	endif
	
	if wasInParentBuf
		call s:MoveToOutline()
	endif

	call s:UpdateOutlineBuf()

	if wasInParentBuf
		call s:MoveToParent()
	endif

endfun

	"============================================
	" UpdateOutlineBuf
	"	refresh the outlineBuf's text
	"
	fun! s:UpdateOutlineBuf()
		call s:UpdateDict()
		let i = 1
		setlocal modifiable
		silent normal gg"_dG
			"clear buffer. avoid clipboard hijack
		for cur in b:outlineItems
		  call setline(i,cur.indexStr)
		  let i += 1
		endfor
		setlocal nomodifiable
	endfun

	"============================================
	" UpdateDict
	"	refresh dict from parentBuf.
	"
	fun! s:UpdateDict()

		let b:outlineItems = []
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
					let nextStr = substitute(nextStr,' \* ','','g')
					let item.parentLineNum = i+1
					let item.indexStr = nextStr
					let item.outlineBufLineNum = j
					call add(b:outlineItems,item)
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
	if s:IsInOutlineBuf()
		bwipeout
	else
		let buf = s:FindOutlineBuf()
		if !buf
			return
		endif
		exe "bwipeout " . buf
	endif
endfun

"============================================
" ToOutline
"	jump to the associated line in the outlineBuf.
"
fun! s:ToOutline()
	if !s:IsInParentBuf()
		return
	endif
	let parentLineNum = line('.')
	let win = s:FindOutlineWin()
	if !win
		return
	endif
	call s:MoveToOutline()
	let assocLineNum = s:GetAssocLineNum(parentLineNum)
	execute 'silent normal' . assocLineNum . 'gg'
endfun

"============================================
" parentBuf funcs
"
	"============================================
	" s:IsInParentBuf
	"
	fun! s:IsInParentBuf()
		if exists('b:outlineBuf')
			return 1
		endif
		return 0
	endfun

	"============================================
	" s:FindOutlineBuf
	" 	return outlineBuf or 0
	"
	fun! s:FindOutlineBuf()
		if !s:IsInParentBuf()
			return 0
		endif
		if !bufexists(b:outlineBuf)
			return 0
		endif
		return b:outlineBuf
	endfun

	"============================================
	" s:FindOutlineWin
	" 	returns associated outlineBuf or 0
	"
	fun! s:FindOutlineWin()
		let buf = s:FindOutlineBuf()
		if !buf
			return 0
		endif
		let win = bufwinnr(buf)
		if win == -1
			return 0
		endif
		return win
	endfun

	"============================================
	" s:MoveToOutline
	" 	move to outlineBuf
	"
	fun! s:MoveToOutline()
		let win = s:FindOutlineWin()
		if !win
			return
		endif
		execute win . 'wincmd w'
	endfun

"============================================
" outlineBuf funcs
"
	"============================================
	" s:IsInOutlineBuf
	"
	fun! s:IsInOutlineBuf()
		if !exists('b:parentBuf')
			return 0
		endif
		return 1
	endfun

	"============================================
	" s:FindParentBuf
	" 	return parentBuf or 0
	"
	fun! s:FindParentBuf()
		if !s:IsInOutlineBuf()
			return 0
		endif
		if !bufexists(b:parentBuf)
			return 0
		endif
		return b:parentBuf
	endfun

	"============================================
	" s:FindParentWin
	" 	returns associated outlineBuf or 0
	"
	fun! s:FindParentWin()
		let buf = s:FindParentBuf()
		if !buf
			return 0
		endif
		let win = bufwinnr(buf)
		if win == -1
			return 0
		endif
		return win
	endfun

	"============================================
	" s:MoveToParent
	" 	morve to parentBuf
	"
	fun! s:MoveToParent()
		let win = s:FindParentWin()
		if !win
			return
		endif
		execute win . 'wincmd w'
	endfun

	"============================================
	" s:GetAssocLineNum
	" 	returns associated nodeLineNum from parentBuf's line num
	"
	fun! s:GetAssocLineNum(parentLineNum)
		if !s:IsInOutlineBuf() || empty(b:outlineItems) || a:parentLineNum < b:outlineItems[0].parentLineNum
			return
		endif
		"if parentLineNum < b:outlineItems
		let i = 0
		let assocLineNum = line('$')
		let found = 0
		let prevItem = {}
		for item in b:outlineItems
			if item.parentLineNum > a:parentLineNum && found == 0
				if found == 0
					let assocLineNum = prevItem.outlineBufLineNum
					let found = 1
				endif
			endif
			let prevItem = item
			let i += 1
		endfor
		return assocLineNum
	endfun

"============================================
" s:BufPairInDifferentGuiTab
" 	if parent and outline were in different GUI tab,
" 	bufexists returuns true but bufwinnnr return false.
"
fun! s:BufPairInDifferentGuiTab()
	if s:IsInOutlineBuf()
		if s:FindParentBuf() && !s:FindParentWin()
			return 1
		else
			return 0
		endif
	endif
	if s:IsInParentBuf()
		if s:FindOutlineBuf() && !s:FindOutlineWin()
			return 1
		else
			return 0
		endif
	endif
	return 0
endfun

"============================================
" debug
" 	for dev.
"
"command! MyTest1 call g:OutlineTest1()
"
"fun! g:OutlineTest1()
"
"	echo '######## parent buf fun test ########'
"	echo 'IsInParentBuf():' . s:IsInParentBuf()
"	echo 'FindOutlineBuf():' . s:FindOutlineBuf()
"	echo 'FindOutlineWin():' . s:FindOutlineWin()
"
"	echo '######## outline buf fun test ########'
"	echo 'IsInOutlineBuf():' . s:IsInOutlineBuf()
"	echo 'FindParentBuf():' . s:FindParentBuf()
"	echo 'FindParentWin():' . s:FindParentWin()
"
"	echo '######## outline buf fun test ########'
"	echo 'BufPairInDifferentGuiTab():' . s:BufPairInDifferentGuiTab()
"
"endfun
