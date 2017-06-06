sync vimim's db file with git repo

# usage

* require my fork: [ZSaberLv0/VimIM](https://github.com/ZSaberLv0/VimIM)
* `let g:VimIMSync_repo_head='https://'`
* `let g:VimIMSync_repo_tail='github.com/YourUserName/yourRepo'`
* `let g:VimIMSync_user='YourUserName'`
* `let g:VimIMSync_file='vimim_data_file_path'`

    such as `plugin/vimim.baidu.txt`

* `call VimIMSync(key, word [, password])`

    such as `call VimIMSync('ceshi', '测试')`

    or, make multiple changes then upload

    ```
    call VimIMSyncAdd('ceshi', '测试')
    call VimIMSyncAdd('yixia', '一下')
    call VimIMSyncRemove('删除')
    call VimIMSyncReset('重置排序')
    call VimIMSyncUpload('password')
    ```

# functions

* `call VimIMSync(key, word [, password])` or `IMSync key word [password]`

    IMSAdd then IMSUpload

* `call VimIMSyncAdd(key, word)` or `IMSAdd key word`

    add word if not exist, or move candidate word to top most if exist

* `call VimIMSyncRemove(word)` or `IMSRemove word`

    remove word

* `call VimIMSyncReset(word)` or `IMSReset word`

    reset candidate word to bottom most

* `call VimIMSyncUpload([password])` or `IMSUpload [password]`

    upload to git repo

* `call VimIMSyncUploadRetry([password])` or `IMSUploadRetry [password]`

    retry IMSUpload

* `call VimIMSyncState([maxStateNumToPrint])` or `IMSState [maxStateNumToPrint]`

    print current modify state

