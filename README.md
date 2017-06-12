sync vimim's db file with git repo

# usage

* require my fork: [ZSaberLv0/VimIM](https://github.com/ZSaberLv0/VimIM)
* `let g:VimIMSync_repo_head='https://'`
* `let g:VimIMSync_repo_tail='github.com/YourUserName/yourRepo'`
* `let g:VimIMSync_user='YourUserName'`
* `let g:VimIMSync_file='vimim_data_file_path'`

    such as `plugin/vimim.baidu.txt`

* `call VimIMSync(word, key [, password])`

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

* `call VimIMSync(word, key [, password])` or `IMSync word key [password]`

    IMAdd then IMUpload

* `call VimIMSyncAdd(word, key)` or `IMAdd word key`

    add word if not exist, or move candidate word to top most if exist

    changes only apply to local, you must call VimIMSyncUpload to sync to remote

* `call VimIMSyncRemove(word [, key])` or `IMRemove word [key]`

    remove word, if key specified, remove the one exactly, otherwise, remove all

* `call VimIMSyncReset(word)` or `IMReset word`

    reset candidate word to bottom most

* `call VimIMSyncClear()` or `IMClear`

    clear all local changes

* `call VimIMSyncUpload([password])` or `IMUpload [password]`

    upload to git repo

* `call VimIMSyncUploadRetry([password])` or `IMUploadRetry [password]`

    retry IMUpload

* `call VimIMSyncState([maxStateNumToPrint])` or `IMState [maxStateNumToPrint]`

    print current modify state

