sync vimim's db file with git repo

# usage

* require my fork: [ZSaberLv0/VimIM](https://github.com/ZSaberLv0/VimIM)

    ```
    Plug 'ZSaberLv0/VimIM'
    Plug 'ZSaberLv0/VimIMSync'
    ```

* have these settings

    ```
    let g:VimIMSync_repo_head='https://'
    let g:VimIMSync_repo_tail='github.com/YourUserName/yourRepo'
    let g:VimIMSync_user='YourUserName'
    let g:VimIMSync_file='vimim_data_file_path, such as: plugin/vimim.baidu.txt'
    ```

    * the db file must follow these rules

        * format: `pinyin word1 word2`
        * word with same pinyin must be placed in same line:

            ```
            xian 先 西安
            ```

    * optionally, you may set `g:zf_git_user_token` to push without input your git password

        ```
        let g:zf_git_user_token='your github access token'
        ```

* `call IMSync word pinyin [password]`

    such as `:IMSync 测试 ceshi`

    this would add a word and upload immediately

* or, make multiple changes then upload

    ```
    :IMAdd 测试 ceshi
    :IMAdd 一下 yixia
    :IMRemove 删除
    :IMRemove 删除指定 shanchuzhiding
    :IMReset 重置排序
    :IMUpload password
    ```

# functions

* `call VimIMSync(word, pinyin [, password])` or `IMSync word pinyin [password]`

    IMAdd then IMUpload

* `call VimIMSyncAdd(word, pinyin)` or `IMAdd word pinyin`

    add word if not exist, or move candidate word to top most if exist

    changes only apply to local, you must call VimIMSyncUpload to sync to remote

* `call VimIMSyncRemove(word [, pinyin])` or `IMRemove word [pinyin]`

    remove word, if pinyin specified, remove the one exactly, otherwise, remove all

* `call VimIMSyncReset(word)` or `IMReset word`

    reset candidate word to bottom most

* `call VimIMSyncClearLocalState()` or `IMClearLocalState`

    clear all local changes, and reload from remote

* `call VimIMSyncUpload([password])` or `IMUpload [password]`

    upload to git repo

* `call VimIMSyncUploadRetry([password])` or `IMUploadRetry [password]`

    retry IMUpload

* `call VimIMSyncDownload()` or `IMDownload`

    reload from remote (local changes can be upload later)

* `call VimIMSyncState([maxStateNumToPrint])` or `IMState [maxStateNumToPrint]`

    print current modify state

* `call VimIMSyncFormalizeBuffer()` or `IMFormalizeBuffer`

    formalize and sort current dict file buffer

