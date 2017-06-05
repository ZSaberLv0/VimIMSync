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

    or, add multiple then sync

    ```
    call VimIMSyncAdd('ceshi', '测试')
    call VimIMSyncAdd('yixia', '一下')
    call VimIMSyncUpload('password')
    ```

    this will append the item if not exist,
    or move it to top if already exist

