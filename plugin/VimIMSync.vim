let g:VimIMSync_loaded=1

" let g:VimIMSync_repo_head='https://'
" let g:VimIMSync_repo_tail='github.com/YourUserName/yourRepo'
" let g:VimIMSync_file='vimim_data_file_path'
" let g:VimIMSync_git_user_name='YourUserName'
" let g:VimIMSync_git_user_email='YourEmail'
" let g:VimIMSync_git_user_token='your password or access token'
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

function! s:git_user_email()
    return get(g:, 'VimIMSync_git_user_email', get(g:, 'zf_git_user_email', ''))
endfunction
function! s:git_user_name()
    return get(g:, 'VimIMSync_git_user_name', get(g:, 'zf_git_user_name', ''))
endfunction
function! s:git_user_token()
    return get(g:, 'VimIMSync_git_user_token', get(g:, 'zf_git_user_token', ''))
endfunction

function! VimIMSync(word, key, ...)
    if a:0 > 1
        echo '[VimIMSync] usage:'
        echo '[VimIMSync]   call VimIMSync(word, key, [password])'
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
        echo '[VimIMSync] VimIMSyncAdd: empty key'
        return 0
    endif

    let word = substitute(a:word, ' ', '', 'g')
    if len(word) <= 0
        echo '[VimIMSync] VimIMSyncAdd: empty word'
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
        echo '[VimIMSync] VimIMSyncRemove: empty word'
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
        echo '[VimIMSync] VimIMSyncReset: empty word'
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
    echo '[VimIMSync] local changes cleared'
    return 1
endfunction
command! -nargs=0 IMClearLocalState :call VimIMSyncClearLocalState(<f-args>)

function! VimIMSyncUpload(...)
    if a:0 > 1
        echo '[VimIMSync] usage:'
        echo '[VimIMSync]   call VimIMSyncUpload([password])'
        return
    endif
    if len(s:toChange) <= 0
        echo '[VimIMSync] nothing to upload'
        return
    endif

    if a:0 >= 1 && len(a:1) > 0
        let s:savedPwd=a:1
    endif
    if len(s:savedPwd) <= 0
        let s:savedPwd = s:git_user_token()
        if empty(s:savedPwd)
            call inputsave()
            let s:savedPwd = inputsecret('Enter password: ')
            call inputrestore()
        endif
    endif
    if len(s:savedPwd) <= 0
        echo '[VimIMSync] upload canceled'
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
        echo '[VimIMSync] nothing to upload'
        return
    endif
    if a:0 > 0
        let iMax = a:1
    else
        let iMax = -1
    endif

    redraw!
    echo '[VimIMSync] you have ' . len(s:toChange) . ' changes to upload:'
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
        let existWord = {}
        for word in dict[key]
            if exists("existWord['" . word . "']")
                continue
            endif
            let existWord[word] = 1
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
    if !exists('g:VimIMSync_file')
        echo 'g:VimIMSync_file not set'
        return 0
    endif
    if empty(s:git_user_email())
        echo 'g:VimIMSync_git_user_email not set'
        return 0
    endif
    if empty(s:git_user_name())
        echo 'g:VimIMSync_git_user_name not set'
        return 0
    endif
    return 1
endfunction

function! s:upload()
    redraw!
    echo '[VimIMSync] updating...'
    let tmp_path = $HOME . '/_VimIMSync_tmp_'
    call s:rm(tmp_path)
    call system('git clone --depth=1 ' . g:VimIMSync_repo_head . g:VimIMSync_repo_tail . ' "' . tmp_path . '"')
    let dstFile = tmp_path . '/' . g:VimIMSync_file
    if !filewritable(dstFile)
        redraw!
        echo '[VimIMSync] update failed, retry? (y/n)'
        call s:rm(tmp_path)
        let cmd=getchar()
        if cmd != char2nr("n")
            call s:upload()
        else
            redraw!
            echo '[VimIMSync] upload canceled'
        endif
        return
    endif

    execute 'tabedit ' . dstFile
    call s:apply()
    sort
    update
    bd

    call system('git -C "' . tmp_path . '" config user.email "' . s:git_user_email() . '"')
    call system('git -C "' . tmp_path . '" config user.name "' . s:git_user_name() . '"')
    call system('git -C "' . tmp_path . '" config push.default "simple"')
    call system('git -C "' . tmp_path . '" commit -a -m "update by VimIMSync"')
    redraw!
    echo '[VimIMSync] pushing...'
    let result = system('git -C "' . tmp_path . '" push ' . g:VimIMSync_repo_head . s:git_user_name() . ':' . s:savedPwd . '@' . g:VimIMSync_repo_tail . ' HEAD')
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
    call system('git -C "' . dstPath . '" reset --hard origin/master')
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
                \ if g:VimIMSync_uploadWithoutConfirm && !empty(s:git_user_token())|
                \     call VimIMSyncUpload()|
                \ else|
                \     call VimIMSyncState(5)|
                \ endif
augroup END

