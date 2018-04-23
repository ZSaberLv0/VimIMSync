let g:VimIMSync_loaded=1

" let g:VimIMSync_repo_head='https://'
" let g:VimIMSync_repo_tail='github.com/YourUserName/yourRepo'
" let g:VimIMSync_user='YourUserName'
" let g:VimIMSync_file='vimim_data_file_path'
if !exists('g:VimIMSync_actionFinishCallback')
    let g:VimIMSync_actionFinishCallback=''
endif
if !exists('g:VimIMSync_uploadWithoutConfirm')
    let g:VimIMSync_uploadWithoutConfirm=1
endif


let s:savedPwd=''
" {
"     'action' : 'add/remove/reset',
"     'key' : 'key',
"     'word' : 'word',
" }
let s:toChange=[]
let s:toChange_saved=[]

function! VimIMSync(word, key, ...)
    if a:0 > 1
        echo 'usage:'
        echo '  call VimIMSync(word, key, [password])'
        return
    endif

    if !VimIMSyncAdd(a:word, a:key)
        return
    endif

    if a:0 == 0
        call VimIMSyncUpload()
    else
        call VimIMSyncUpload(a:1)
    endif
endfunction
command! -nargs=+ IMSync :call VimIMSync(<f-args>)

function! VimIMSyncAdd(word, key)
    if !s:stateCheck()
        return 0
    endif

    let key = substitute(a:key, ' ', '', 'g')
    if len(key) <= 0
        echo 'VimIMSyncAdd: empty key'
        return 0
    endif

    let word = substitute(a:word, ' ', '', 'g')
    if len(word) <= 0
        echo 'VimIMSyncAdd: empty word'
    endif

    call add(s:toChange, {'action' : 'add', 'key' : key, 'word' : word})
    call s:applyLocalOnly()

    return 1
endfunction
command! -nargs=+ IMAdd :call VimIMSyncAdd(<f-args>)

function! VimIMSyncRemove(word, ...)
    if !s:stateCheck()
        return 0
    endif

    let key = ''
    if a:0 > 0
        let key = substitute(a:1, ' ', '', 'g')
    endif

    let word = substitute(a:word, ' ', '', 'g')
    if len(word) <= 0
        echo 'VimIMSyncRemove: empty word'
    endif

    call add(s:toChange, {'action' : 'remove', 'key' : key, 'word' : word})
    call s:applyLocalOnly()

    return 1
endfunction
command! -nargs=+ IMRemove :call VimIMSyncRemove(<f-args>)

function! VimIMSyncReset(word)
    if !s:stateCheck()
        return 0
    endif

    let word = substitute(a:word, ' ', '', 'g')
    if len(word) <= 0
        echo 'VimIMSyncReset: empty word'
    endif

    call add(s:toChange, {'action' : 'reset', 'word' : word})
    call s:applyLocalOnly()

    return 1
endfunction
command! -nargs=1 IMReset :call VimIMSyncReset(<f-args>)

function! VimIMSyncClearLocalState()
    let s:toChange = []
    let s:toChange_saved = []
    call s:reloadFromRemote()
    echo 'VimIMSync: local changes cleared'
    return 1
endfunction
command! -nargs=0 IMClearLocalState :call VimIMSyncClearLocalState(<f-args>)

function! VimIMSyncUpload(...)
    if a:0 > 1
        echo 'usage:'
        echo '  call VimIMSyncUpload([password])'
        return
    endif
    if len(s:toChange) <= 0
        echo 'VimIMSync: nothing to upload'
        return
    endif

    if a:0 >= 1 && len(a:1) > 0
        let s:savedPwd=a:1
    endif
    if len(s:savedPwd) <= 0
        if exists('g:zf_git_user_token') && !empty(g:zf_git_user_token)
            let s:savedPwd = g:zf_git_user_token
        else
            call inputsave()
            let s:savedPwd = input('Enter password: ')
            call inputrestore()
            " prevent password from being saved to viminfo
            set viminfo=
        endif
    endif
    if len(s:savedPwd) <= 0
        echo 'VimIMSync canceled'
        return
    endif

    let s:toChange_saved = s:toChange
    call s:upload()
endfunction
command! -nargs=? IMUpload :call VimIMSyncUpload(<f-args>)

function! VimIMSyncUploadRetry(...)
    if a:0 >= 1 && len(a:1) > 0
        let s:savedPwd=a:1
    endif
    let s:toChange = s:toChange_saved
    call VimIMSyncUpload()
endfunction
command! -nargs=? IMUploadRetry :call VimIMSyncUploadRetry(<f-args>)

function! VimIMSyncDownload()
    call s:reloadFromRemote()
endfunction
command! -nargs=0 IMDownload :call VimIMSyncDownload(<f-args>)

function! VimIMSyncState(...)
    if len(s:toChange) <= 0
        redraw!
        echo 'VimIMSync: nothing to upload'
        return
    endif
    if a:0 > 0
        let iMax = a:1
    else
        let iMax = -1
    endif

    redraw!
    echo 'VimIMSync: you have ' . len(s:toChange) . ' changes to upload:'
    let iItem = 0
    for item in s:toChange
        if item['action'] == 'add'
            echo '    <add>      ' . item['word'] . "\t" . item['key']
        elseif item['action'] == 'remove'
            echo '    <remove>   ' . item['word'] . "\t" . item['key']
        elseif item['action'] == 'reset'
            echo '    <reset>    ' . item['word']
        else
            echo item
        endif

        let iItem += 1
        if iMax >= 0 && iItem >= iMax
            if iItem < len(s:toChange)
                echo '    ...'
            endif
            break
        endif
    endfor
    echo ' '
    echo 'upload now? (y/n) '
    let choose = getchar()
    if choose != char2nr('y')
        redraw!
        return
    endif

    call VimIMSyncUpload()
endfunction
command! -nargs=? IMState :call VimIMSyncState(<f-args>)

function! VimIMSyncFormalizeBuffer()
    let dict={}
    for iLine in range(1, line('$') + 1)
        let line = getline(iLine)
        let word = split(line, ' ')
        if len(word) <= 0
            continue
        endif

        let key = word[0]
        call remove(word, 0)

        if exists('dict[key]')
            call extend(dict[key], word)
        else
            let dict[key] = word
        endif
    endfor

    normal! ggdG

    let iLine = 1
    for key in keys(dict)
        if len(key) <= 0 || len(dict[key]) <= 0
            continue
        endif

        let line = key
        for word in dict[key]
            let line .= ' '
            let line .= word
        endfor

        call setline(iLine, line)
        let iLine += 1
    endfor

    sort
    update
endfunction
command! -nargs=0 IMFormalizeBuffer :call VimIMSyncFormalizeBuffer(<f-args>)

function! s:stateCheck()
    if !exists('g:VimIMSync_repo_head')
        echo 'g:VimIMSync_repo_head not set'
        return 0
    endif
    if !exists('g:VimIMSync_repo_tail')
        echo 'g:VimIMSync_repo_tail not set'
        return 0
    endif
    if !exists('g:VimIMSync_user')
        echo 'g:VimIMSync_user not set'
        return 0
    endif
    if !exists('g:VimIMSync_file')
        echo 'g:VimIMSync_file not set'
        return 0
    endif
    return 1
endfunction

function! s:upload()
    redraw!
    echo 'updating...'
    let tmp_path = $HOME . '/_VimIMSync_tmp_'
    call s:rm(tmp_path)
    call system('git clone --depth=1 ' . g:VimIMSync_repo_head . g:VimIMSync_repo_tail . ' "' . tmp_path . '"')
    let dstFile = tmp_path . '/' . g:VimIMSync_file
    if !filewritable(dstFile)
        redraw!
        echo 'unable to write file: "' . dstFile . '"'
        call s:rm(tmp_path)
        return
    endif

    execute 'tabedit ' . dstFile
    call s:apply()
    sort
    update
    bd

    call system('git -C "' . tmp_path . '" config user.email "' . g:zf_git_user_email . '"')
    call system('git -C "' . tmp_path . '" config user.name "' . g:zf_git_user_name . '"')
    call system('git -C "' . tmp_path . '" config push.default "simple"')
    call system('git -C "' . tmp_path . '" commit -a -m "update by VimIMSync"')
    redraw!
    echo 'pushing...'
    let result = system('git -C "' . tmp_path . '" push ' . g:VimIMSync_repo_head . g:VimIMSync_user . ':' . s:savedPwd . '@' . g:VimIMSync_repo_tail)
    redraw!
    " strip password
    let result = substitute(result, ':[^:]*@', '@', 'g')
    echo result

    call s:rm(tmp_path)
    let s:toChange=[]

    call s:reloadFromRemote()
    call s:notifyCallback()
endfunction

function! s:applyLocalOnly()
    let dstPath = globpath(&rtp, g:VimIMSync_file)
    if len(dstPath) <= 0
        return
    endif

    execute 'tabedit ' . dstPath
    call s:apply()
    sort
    update
    bd
    call s:reloadVimim()
    call s:notifyCallback()
endfunction

function! s:notifyCallback()
    if exists('g:VimIMSync_actionFinishCallback') && !empty(g:VimIMSync_actionFinishCallback)
        execute 'call ' . g:VimIMSync_actionFinishCallback . '()'
    endif
endfunction

function! s:apply()
    for item in s:toChange
        if item['action'] == 'add'
            call s:applyAdd(item['word'], item['key'])
        elseif item['action'] == 'remove'
            call s:applyRemove(item['word'], item['key'])
        elseif item['action'] == 'reset'
            call s:applyReset(item['word'])
        endif
    endfor

    " fix search highlight
    silent! normal! n
    redraw!
endfunction
function! s:applyAdd(word, key)
    let exist=0
    for iLine in range(1, line('$') + 1)
        let line = getline(iLine)
        if match(line, '^' . a:key . ' ') >= 0
            if match(line, '\<' . a:word . '\>') >= 0
                let line = substitute(line,
                            \ '^' . a:key . '\(.*\) ' . a:word . '\>',
                            \ a:key . ' ' . a:word . '\1',
                            \ '')
            else
                let line = substitute(line,
                            \ '^' . a:key . '\>',
                            \ a:key . ' ' . a:word,
                            \ '')
            endif
            call setline(iLine, line)
            let exist=1
            break
        endif
    endfor
    if exist == 0
        call setline(line('$') + 1, a:key . ' ' . a:word)
    endif
endfunction
function! s:applyRemove(word, key)
    if len(a:key) > 0
        execute 'silent! %s/\%(' . a:key . '\>.*\)\@<= ' . a:word . '\>//g'
    else
        execute 'silent! %s/ ' . a:word . '\>//g'
    endif
    execute 'silent! g/^[a-z]\+$/d'
endfunction
function! s:applyReset(word)
    execute 'silent! %s/^\(.*\)\( ' . a:word . '\)\( .*\)$/\1\3\2/g'
endfunction

function! s:reloadFromRemote()
    let dstPath = globpath(&rtp, g:VimIMSync_file)
    if len(dstPath) <= 0
        return
    endif
    let t = substitute(g:VimIMSync_file, '\\', '/', 'g')
    let dstPath = substitute(dstPath, '\\', '/', 'g')
    let dstPath = substitute(dstPath, t, '', 'g')
    call system('git -C "' . dstPath . '" checkout .')
    call system('git -C "' . dstPath . '" pull')
    call s:reloadVimim()
endfunction
function! s:reloadVimim()
    silent! call VimIMReload()
    " toggle vimim twice to make vimim active
    execute "normal! i\<C-R>=g:Vimim_chinese()\<CR>\<Esc>l"
    execute "normal! i\<C-R>=g:Vimim_chinese()\<CR>\<Esc>l"
    redraw!
endfunction

function! s:rm(f)
    if(has('win32') || has('win64') || has('win95') || has('win16'))
        call system('del /f/s/q "' . substitute(a:f, '/', '\\', 'g') . '"')
        call system('rmdir /s/q "' . substitute(a:f, '/', '\\', 'g') . '"')
    else
        call system('rm -rf "' . a:f. '"')
    endif
endfunction

augroup VimIMSyncAutoUpload
    autocmd!
    autocmd VimLeavePre *
                \ if g:VimIMSync_uploadWithoutConfirm && exists('g:zf_git_user_token') && !empty(g:zf_git_user_token)|
                \     call VimIMSyncUpload()|
                \ else|
                \     call VimIMSyncState(5)|
                \ endif
augroup END

