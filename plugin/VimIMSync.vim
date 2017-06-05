let g:VimIMSync_loaded=1

" let g:VimIMSync_repo_head='https://'
" let g:VimIMSync_repo_tail='github.com/YourUserName/yourRepo'
" let g:VimIMSync_user='YourUserName'
" let g:VimIMSync_file='vimim_data_file_path'


let s:VimIMSync_pwd=''
let s:VimIMSync_list=[]
let s:VimIMSync_list_saved=[]

function! VimIMSync(key, word, ...)
    if a:0 > 1
        echo 'usage:'
        echo '  call VimIMSync(key, word, [password])'
        return
    endif

    let result = VimIMSyncAdd(a:key, a:word)
    if result != 0
        return
    endif

    if a:0 == 0
        call VimIMSyncUpload()
    else
        call VimIMSyncUpload(a:1)
    endif
endfunction

function! VimIMSyncAdd(key, word)
    if !exists('g:VimIMSync_repo_head')
        echo 'g:VimIMSync_repo_head not set'
        return 1
    endif
    if !exists('g:VimIMSync_repo_tail')
        echo 'g:VimIMSync_repo_tail not set'
        return 1
    endif
    if !exists('g:VimIMSync_user')
        echo 'g:VimIMSync_user not set'
        return 1
    endif
    if !exists('g:VimIMSync_file')
        echo 'g:VimIMSync_file not set'
        return 1
    endif

    let key = substitute(a:key, ' ', '', 'g')
    if len(key) <= 0
        echo 'VimIMSyncAdd: empty key'
        return 1
    endif

    let word = substitute(a:word, ' ', '', 'g')
    if len(word) <= 0
        echo 'VimIMSyncAdd: empty word'
    endif

    call add(s:VimIMSync_list, {'key' : key, 'word' : word})

    return 0
endfunction

function! VimIMSyncUpload(...)
    if a:0 > 1
        echo 'usage:'
        echo '  call VimIMSyncUpload([password])'
        return
    endif
    if len(s:VimIMSync_list) <= 0
        echo 'VimIMSync: nothing to upload'
        return
    endif

    if a:0 >= 1 && len(a:1) > 0
        let s:VimIMSync_pwd=a:1
    endif
    if len(s:VimIMSync_pwd) <= 0
        call inputsave()
        let s:VimIMSync_pwd = input('Enter password: ')
        call inputrestore()
        " prevent password from being saved to viminfo
        set viminfo=
    endif
    if len(s:VimIMSync_pwd) <= 0
        echo 'VimIMSync canceled'
        return
    endif

    let s:VimIMSync_list_saved = s:VimIMSync_list
    call s:upload()
endfunction

function! VimIMSyncUploadRetry()
    let s:VimIMSync_list = s:VimIMSync_list_saved
    call VimIMSyncUpload()
endfunction

function! s:upload()
    redraw!
    echo 'updating...'
    let tmp_path = $HOME . '/_VimIMSync_tmp_'
    let dummy = system('rm -rf "' . tmp_path . '"')
    let dummy = system('git clone --depth=1 ' . g:VimIMSync_repo_head . g:VimIMSync_repo_tail . ' "' . tmp_path . '"')
    let dstFile = tmp_path . '/' . g:VimIMSync_file
    if !filewritable(dstFile)
        redraw!
        echo 'unable to write file: "' . dstFile . '"'
        let dummy = system('rm -rf "' . tmp_path . '"')
        return
    endif

    call s:merge(dstFile)

    let dummy = system('git -C "' . tmp_path . '" config user.email "' . g:zf_git_user_email . '"')
    let dummy = system('git -C "' . tmp_path . '" config user.name "' . g:zf_git_user_name . '"')
    let dummy = system('git -C "' . tmp_path . '" config push.default "simple"')
    let dummy = system('git -C "' . tmp_path . '" commit -a -m "update by VimIMSync"')
    redraw!
    echo 'pushing...'
    let dummy = system('git -C "' . tmp_path . '" push ' . g:VimIMSync_repo_head . g:VimIMSync_user . ':' . s:VimIMSync_pwd . '@' . g:VimIMSync_repo_tail)
    redraw!
    " strip password
    let dummy = substitute(dummy, ':[^:]*@', '@', 'g')
    echo dummy

    let dummy = system('rm -rf "' . tmp_path . '"')
    let s:VimIMSync_list=[]

    call s:reload()
endfunction

function! s:merge(path)
    enew
    execute 'edit ' . a:path

    for item in s:VimIMSync_list
        let exist=0
        for iLine in range(1, line('$') + 1)
            let line = getline(iLine)
            if match(line, '^' . item['key'] . ' ') >= 0
                if match(line, '\<' . item['word'] . '\>') >= 0
                    let line = substitute(line,
                                \ '^' . item['key'] . '\(.*\) ' . item['word'] . '\>',
                                \ item['key'] . ' ' . item['word'] . '\1',
                                \ '')
                else
                    let line = substitute(line,
                                \ '^' . item['key'] . '\>',
                                \ item['key'] . ' ' . item['word'],
                                \ '')
                endif
                call setline(iLine, line)
                let exist=1
                break
            endif
        endfor
        if exist == 0
            call setline(line('$') + 1, item['key'] . ' ' . item['word'])
        endif
    endfor

    update
    bd
endfunction

function! s:reload()
    let dstPath = globpath(&rtp, g:VimIMSync_file)
    if len(dstPath) <= 0
        return
    endif
    let t = substitute(g:VimIMSync_file, '\\', '/', 'g')
    let dstPath = substitute(dstPath, '\\', '/', 'g')
    let dstPath = substitute(dstPath, t, '', 'g')
    let dummy = system('git -C "' . dstPath . '" pull')
    silent! call VimIMReload()
endfunction


function! VimIMSyncUploadCheck(...)
    if len(s:VimIMSync_list) <= 0
        return
    endif

    redraw!
    echo 'VimIMSync: you have changes not upload yet, upload now?'
    echo 'choose: (y/n) '
    let choose = getchar()
    if choose != char2nr('y')
        redraw!
        return
    endif

    if a:0 > 0
        call VimIMSyncUpload(a:1)
    else
        call VimIMSyncUpload()
    endif
endfunction

augroup VimIMSyncAutoUpload
    autocmd!
    autocmd VimLeavePre *
                \ call VimIMSyncUploadCheck()
augroup END

