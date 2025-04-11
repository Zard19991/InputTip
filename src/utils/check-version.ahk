; InputTip

/**
 * 比对版本号
 * @param new 新版本号
 * @param old 旧版本号
 * @returns {Number}
 * - new > old : 1
 * - new < old : -1
 * - new = old : 0
 */
compareVersion(new, old) {
    newParts := StrSplit(new, ".")
    oldParts := StrSplit(old, ".")
    for i, part1 in newParts {
        try {
            part2 := oldParts[i]
        } catch {
            part2 := 0
        }
        if (part1 > part2) {
            return 1  ; new > old
        } else if (part1 < part2) {
            return -1  ; new < old
        }
    }
    return 0  ; new = old
}

/**
 * 检查版本更新(异步)
 * @param currentVersion 当前版本号
 * @param callback 版本检查完成后的回调函数
 * @param urls 版本检查 URL 列表
 */
checkVersion(currentVersion, callback, urls := [
    "https://gitee.com/abgox/InputTip/raw/main/src/version.txt",
    "https://inputtip.abgox.com/releases/v2/version.txt",
    "https://github.com/abgox/InputTip/raw/main/src/version.txt"
]) {
    currentVersion := StrReplace(currentVersion, "v", "")
    check(1)
    check(index) {
        if (index > urls.Length) {
            return
        }
        url := urls[index]
        try {
            req := ComObject("Msxml2.XMLHTTP")
            req.open("GET", url, true)
            req.onreadystatechange := Ready
            req.send()
            Ready() {
                if (req.readyState != 4) {
                    return
                }
                if (req.status == 200) {
                    newVersion := Trim(StrReplace(StrReplace(StrReplace(req.responseText, "`r", ""), "`n", ""), "v", ""))
                    if (newVersion ~= "^[\d\.]+$") {
                        if (compareVersion(newVersion, currentVersion) > 0) {
                            try {
                                callback(newVersion, url)
                            }
                        }
                        return
                    }
                }
                check(index + 1)
            }
        }
    }
}

/**
 * 检查更新并弹出确认框
 */
checkUpdate(init := 0, once := 0, force := 0, silent := silentUpdate) {
    if (checkUpdateDelay || force) {
        updateTitle := "InputTip - " (A_IsCompiled ? "exe 版本(编译运行方案)" : "zip 版本(项目源代码运行方案)")
        if (once) {
            _checkUpdate()
            return
        }
        if (init) {
            checkUpdateTimer()
        }
        SetTimer(checkUpdateTimer, checkUpdateDelay * 1000 * 60)
        checkUpdateTimer() {
            if (!checkUpdateDelay) {
                SetTimer(checkUpdateTimer, 0)
                return
            }
            if (gc.init) {
                return
            }
            _checkUpdate()
        }
        _checkUpdate() {
            if (A_IsCompiled) {
                checkVersion(currentVersion, updateConfirm)
                updateConfirm(newVersion, url) {
                    if (gc.w.updateGui || compareVersion(newVersion, currentVersion) <= 0) {
                        return
                    }

                    /**
                     * 下载并替换新版本
                     * @returns {1 | 0} 是否完成
                     */
                    updateNewVersion() {
                        releases := [
                            "https://gitee.com/abgox/InputTip/releases/download/v" newVersion "/InputTip.exe",
                            "https://github.com/abgox/InputTip/releases/download/v" newVersion "/InputTip.exe"
                        ]
                        done := false

                        downloading(*) {
                            g := createGuiOpt("InputTip - " currentVersion " > " newVersion)
                            g.AddText("cRed", "InputTip 新版本 " newVersion " 下载中...")
                            g.AddText(, "--------------------------------------------------")
                            g.AddText("xs", "官网:")
                            g.AddLink("yp", '<a href="https://inputtip.abgox.com">https://inputtip.abgox.com</a>')
                            g.AddText("xs", "Github:")
                            g.AddLink("yp", '<a href="https://github.com/abgox/InputTip">https://github.com/abgox/InputTip</a>')
                            g.AddText("xs", "Gitee: :")
                            g.AddLink("yp", '<a href="https://gitee.com/abgox/InputTip">https://gitee.com/abgox/InputTip</a>')
                            g.AddLink("xs", '版本更新日志:   <a href="https://inputtip.abgox.com/v2/changelog">官网</a>   <a href="https://github.com/abgox/InputTip/blob/main/src/CHANGELOG.md">Github</a>   <a href="https://gitee.com/abgox/InputTip/blob/main/src/CHANGELOG.md">Gitee</a>')
                            if (!silent) {
                                g.Show()
                            }
                            g.OnEvent("Close", downloading)
                            return g
                        }
                        downloadingGui := downloading()

                        for v in releases {
                            try {
                                out := A_ScriptDir "/InputTipSymbol/default/abgox-InputTip-new-version.exe"
                                Download(v, out)
                                ; 尝试获取版本号，成功获取则表示下载没有问题
                                done := compareVersion(FileGetVersion(out), currentVersion) > 0
                                break
                            }
                        }
                        downloadingGui.Destroy()

                        if (done) {
                            if (enableJABSupport) {
                                killJAB(1, A_IsCompiled)
                            }
                            try {
                                FileInstall("utils/app-update/target/release/app-update.exe", A_ScriptDir "/InputTipSymbol/default/abgox-InputTip-update-version.exe", 1)
                                writeIni("clickUpdate", !silent)
                                Run(A_ScriptDir "/InputTipSymbol/default/abgox-InputTip-update-version.exe " '"' A_ScriptName '" "' A_ScriptFullPath '" ' keyCount, , "Hide")
                                ExitApp()
                            } catch {
                                done := false
                            }
                        }
                        return done
                    }

                    if (silent) {
                        A_TrayMenu.Insert("开机自启动", "准备静默更新......", _do)
                        A_TrayMenu.Insert("开机自启动", "正在等待电脑空闲......", _do)
                        _do(*) {
                        }
                        A_TrayMenu.Insert("开机自启动")
                        SetTimer(updateNewVersionTimer, 10000)
                        updateNewVersionTimer() {
                            ; 3 分钟内没有鼠标和键盘操作，视为电脑休闲时间，则自动更新
                            if (A_TimeIdle > 1000 * 60 * 3) {
                                updateNewVersion()
                                SetTimer(, 0)
                            }
                        }
                        return
                    }

                    createGui(updateGui).Show()
                    updateGui(info) {
                        g := createGuiOpt(updateTitle)
                        g.AddText(, "InputTip 有版本更新: ")
                        g.AddText("yp cff5050", currentVersion)
                        g.AddText("yp", ">")
                        g.AddText("yp cRed", newVersion)
                        g.AddText("xs", "--------------------------------------------------------------------------")
                        g.AddLink("xs", '项目仓库地址:   <a href="https://github.com/abgox/InputTip">Github</a>   <a href="https://gitee.com/abgox/InputTip">Gitee</a>')
                        g.AddLink("xs", '版本更新日志:   <a href="https://inputtip.abgox.com/v2/changelog">官网</a>   <a href="https://github.com/abgox/InputTip/blob/main/src/CHANGELOG.md">Github</a>   <a href="https://gitee.com/abgox/InputTip/blob/main/src/CHANGELOG.md">Gitee</a>')

                        if (info.i) {
                            return g
                        }
                        w := info.w
                        bw := w - g.MarginX * 2

                        y := g.AddButton("xs w" bw / 2, "确认更新")
                        y.Focus()
                        y.OnEvent("Click", e_yes)
                        e_yes(*) {
                            fn_close()
                            if (!updateNewVersion()) {
                                createGui(errGui).Show()
                                errGui(info) {
                                    g := createGuiOpt("InputTip - 新版本下载错误")
                                    g.AddText("cRed", "InputTip 新版本下载错误!")
                                    g.AddText("xs cRed", "请手动下载最新版本的 InputTip.exe 文件并替换。")
                                    g.AddText(, "--------------------------------------------------")
                                    g.AddText("xs", "官网:")
                                    g.AddLink("yp", '<a href="https://inputtip.abgox.com">https://inputtip.abgox.com</a>')
                                    g.AddText("xs", "Github:")
                                    g.AddLink("yp", '<a href="https://github.com/abgox/InputTip">https://github.com/abgox/InputTip</a>')
                                    g.AddText("xs", "Gitee: :")
                                    g.AddLink("yp", '<a href="https://gitee.com/abgox/InputTip">https://gitee.com/abgox/InputTip</a>')

                                    if (info.i) {
                                        return g
                                    }
                                    w := info.w
                                    bw := w - g.MarginX * 2

                                    y := g.AddButton("xs w" bw, "我知道了")
                                    y.Focus()
                                    y.OnEvent("Click", yes)
                                    g.OnEvent("Close", yes)
                                    yes(*) {
                                        g.Destroy()
                                        try {
                                            FileDelete(A_AppData "/abgox-InputTip-new-version.exe")
                                        }
                                    }
                                    return g
                                }
                            }
                        }
                        g.AddButton("yp w" bw / 2, "取消更新").OnEvent("Click", fn_close)
                        g.AddButton("xs w" bw / 2, "关闭更新检查").OnEvent("Click", e_no)
                        g.AddButton("yp w" bw / 2, "启用静默更新").OnEvent("Click", e_silent)
                        e_no(*) {
                            fn_close()
                            SetTimer(checkUpdateTimer, 0)
                            ignoreUpdateTip()
                        }
                        e_silent(*) {
                            fn_close()
                            writeIni("silentUpdate", 1)
                            global silentUpdate := 1
                        }
                        g.OnEvent("Close", fn_close)
                        fn_close(*) {
                            g.Destroy()
                            gc.w.updateGui := ""
                        }
                        gc.w.updateGui := g
                        return g
                    }
                }
            } else {
                checkVersion(currentVersion, updatePrompt)
                updatePrompt(newVersion, url) {
                    if (gc.w.updateGui || compareVersion(newVersion, currentVersion) <= 0) {
                        return
                    }
                    if (silent) {
                        A_TrayMenu.Insert("开机自启动", "准备静默更新......", _do)
                        A_TrayMenu.Insert("开机自启动", "正在等待电脑空闲......", _do)
                        _do(*) {
                        }
                        A_TrayMenu.Insert("开机自启动")
                        SetTimer(updateNewVersionTimer, 10000)
                        updateNewVersionTimer() {
                            ; 3 分钟内没有鼠标和键盘操作，视为电脑休闲时间，则自动更新
                            if (A_TimeIdle > 1000 * 60 * 3) {
                                getRepoCode(newVersion, silent)
                                SetTimer(, 0)
                            }
                        }
                        return
                    }
                    createGui(fn).Show()
                    fn(info) {
                        g := createGuiOpt(updateTitle)
                        g.AddText(, "InputTip 有新版本了:")
                        g.AddText("yp cff5050", "v" currentVersion)
                        g.AddText("yp ", ">")
                        g.AddText("yp cRed", "v" newVersion)
                        g.AddText("xs", "--------------------------------------------------------------------------")
                        g.AddLink("xs", '使用 <a href="https://git-scm.com/">git</a> :')
                        g.AddText("yp cRed", "git clone")
                        g.AddText("yp", "克隆仓库, 然后通过")
                        g.AddText("yp cRed", "git pull")
                        g.AddText("yp", "更新")
                        g.AddLink("xs", '不用 <a href="https://git-scm.com/">git</a> :')
                        g.AddLink("yp", '使用下方的「确认更新」按钮进行更新')
                        g.AddText("xs", "--------------------------------------------------------------------------")
                        g.AddLink("xs", '项目仓库地址:   <a href="https://github.com/abgox/InputTip">Github</a>   <a href="https://gitee.com/abgox/InputTip">Gitee</a>')
                        g.AddLink("xs", '版本更新日志:   <a href="https://inputtip.abgox.com/v2/changelog">官网</a>   <a href="https://github.com/abgox/InputTip/blob/main/src/CHANGELOG.md">Github</a>   <a href="https://gitee.com/abgox/InputTip/blob/main/src/CHANGELOG.md">Gitee</a>')

                        if (info.i) {
                            return g
                        }
                        w := info.w
                        bw := w - g.MarginX * 2

                        y := g.AddButton("w" bw / 2, "确认更新")
                        y.Focus()
                        y.OnEvent("Click", e_yes)
                        e_yes(*) {
                            fn_close()
                            getRepoCode(newVersion, 0)
                        }
                        g.AddButton("yp w" bw / 2, "取消更新").OnEvent("Click", fn_close)
                        g.AddButton("xs w" bw / 2, "关闭更新检查").OnEvent("Click", e_no)
                        g.AddButton("yp w" bw / 2, "启用静默更新").OnEvent("Click", e_silent)
                        e_no(*) {
                            fn_close()
                            SetTimer(checkUpdateTimer, 0)
                            ignoreUpdateTip()
                        }
                        e_silent(*) {
                            fn_close()
                            writeIni("silentUpdate", 1)
                            global silentUpdate := 1
                        }
                        g.OnEvent("Close", fn_close)
                        fn_close(*) {
                            g.Destroy()
                            gc.w.updateGui := ""
                        }
                        gc.w.updateGui := g
                        return g
                    }
                }
            }
        }
    }
}


; 忽略更新的弹窗提示
ignoreUpdateTip() {
    global checkUpdateDelay := 0
    writeIni("checkUpdateDelay", 0)

    createGui(doneGui).Show()
    doneGui(info) {
        g := createGuiOpt("InputTip - 成功关闭更新检查")
        g.AddText(, "InputTip 的")
        g.AddText("yp cRed", "版本更新检查")
        g.AddText("yp", "已关闭")
        g.AddText("xs", "现在 InputTip 不会再检查版本更新，除非重新设置更新检查间隔")
        g.AddText("xs", "设置方式:「托盘菜单」=>「设置更新检查」")

        g.AddText("cGray", "如果在使用过程中有任何问题，先检查当前是否为最新版本`n如果更新到最新版本，问题依然存在，可以进行反馈`n「托盘菜单」的「关于」中有代码仓库、腾讯频道等反馈渠道")

        if (info.i) {
            return g
        }

        w := info.w
        bw := w - g.MarginX * 2

        g.AddButton("w" bw, "我知道了").OnEvent("Click", yes)
        yes(*) {
            g.Destroy()
        }
        return g
    }
}

; 下载最新的源代码文件
getRepoCode(newVersion, silent := silentUpdate) {
    done := 1

    try {
        FileDelete("files.ini")
    }
    for u in baseUrl {
        out := "files.ini"
        try {
            Download(u "src/files.ini", out)
            break
        }
    }

    try {
        files := StrSplit(IniRead("files.ini", "files"), "`n")
        tip := ""
        downloading(*) {
            if (newVersion) {
                g := createGuiOpt("InputTip - 版本更新中 " currentVersion " > " newVersion)
                g.AddText("cRed", "InputTip 新版本 " newVersion " 下载中...")
            } else {
                g := createGuiOpt("InputTip - 正在获取最新的源代码...")
            }
            g.AddText(, "正在下载和校验文件: ")
            tip := g.AddText("xs cRed", "                                                            ")

            g.AddText("xs", "------------------------------------------------------------")
            g.AddText("xs", "官网:")
            g.AddLink("yp", '<a href="https://inputtip.abgox.com">https://inputtip.abgox.com</a>')
            g.AddText("xs", "Github:")
            g.AddLink("yp", '<a href="https://github.com/abgox/InputTip">https://github.com/abgox/InputTip</a>')
            g.AddText("xs", "Gitee: :")
            g.AddLink("yp", '<a href="https://gitee.com/abgox/InputTip">https://gitee.com/abgox/InputTip</a>')
            g.AddLink("xs", '版本更新日志:   <a href="https://inputtip.abgox.com/v2/changelog">官网</a>   <a href="https://github.com/abgox/InputTip/blob/main/src/CHANGELOG.md">Github</a>   <a href="https://gitee.com/abgox/InputTip/blob/main/src/CHANGELOG.md">Gitee</a>')
            if (!silent) {
                g.Show()
            }
            g.OnEvent("Close", downloading)
            return g
        }
        downloadingGui := downloading()

        doneFileList := []
        fileCount := files.Length
        for i, kv in files {
            p := StrSplit(kv, "=")
            for u in baseUrl {
                tip.Text := i '/' fileCount " : " p[1]
                out := p[2] ".new"
                if (InStr(out, "/")) {
                    dir := RegExReplace(out, "/[^/]*$", "")
                } else {
                    dir := ""
                }
                try {
                    if (dir) {
                        if (!DirExist(dir)) {
                            DirCreate(dir)
                        }
                    }
                    Download(u p[1], out)
                    break
                }
            }
            if (FileExist(out)) {
                doneFileList.Push(out)
                if (InStr(out, ".ahk")) {
                    try {
                        if (!InStr(FileOpen(out, "r").ReadLine(), "InputTip")) {
                            done := 0
                            break
                        }
                    } catch {
                        done := 0
                        break
                    }
                }
            } else {
                done := 0
                break
            }
        }

        downloadingGui.Destroy()

        if (done) {
            for v in doneFileList {
                FileMove(v, RegExReplace(v, "\.new$", ""), 1)
            }
            if (newVersion) {
                FileAppend("", A_ScriptDir "/InputTipSymbol/default/abgox-InputTip-update-version-done.txt")
                writeIni("clickUpdate", !silent)
            }
            fn_restart()
        }
    } catch {
        done := 0
        try {
            downloadingGui.Destroy()
        }
    }

    if (!done) {
        try {
            for v in doneFileList {
                FileDelete(v)
            }
        }

        if (silent) {
            return
        }
        createGui(errGui).Show()
        errGui(info) {
            if (newVersion) {
                g := createGuiOpt("InputTip - 新版本下载错误")
                g.AddText("cRed", "InputTip 新版本下载错误!")
            } else {
                g := createGuiOpt("InputTip - 获取失败")
                g.AddText("cRed", "最新的源代码获取失败!")
            }

            g.AddText("cRed", "请手动下载最新版本的 InputTip.Zip 并解压替换。")
            g.AddText(, "--------------------------------------------------")
            g.AddText("xs", "官网:")
            g.AddLink("yp", '<a href="https://inputtip.abgox.com">https://inputtip.abgox.com</a>')
            g.AddText("xs", "Github:")
            g.AddLink("yp", '<a href="https://github.com/abgox/InputTip">https://github.com/abgox/InputTip</a>')
            g.AddText("xs", "Gitee: :")
            g.AddLink("yp", '<a href="https://gitee.com/abgox/InputTip">https://gitee.com/abgox/InputTip</a>')

            if (info.i) {
                return g
            }
            w := info.w
            bw := w - g.MarginX * 2

            y := g.AddButton("xs w" bw, "我知道了")
            y.Focus()
            y.OnEvent("Click", yes)
            g.OnEvent("Close", yes)
            yes(*) {
                g.Destroy()
            }
            return g
        }
    }
}


/**
 * 当更新完成时弹出提示框
 */
checkUpdateDone() {
    oldVersion := readIni("version", currentVersion, "UserInfo")
    flagFile := A_AppData "/.abgox-InputTip-update-version-done.txt"
    flagFile2 := A_ScriptDir "/InputTipSymbol/default/abgox-InputTip-update-version-done.txt"
    if (compareVersion(currentVersion, oldVersion) > 0 || FileExist(flagFile) || FileExist(flagFile2)) {
        try {
            ignoreUpdate := IniRead("InputTip.ini", "Config-v2", "ignoreUpdate")
            _ := ignoreUpdate ? 0 : 1440
            writeIni("checkUpdateDelay", _)
            IniDelete("InputTip.ini", "Config-v2", "ignoreUpdate")
        }

        try {
            _ := IniRead("InputTip.ini", "InputMethod", "statusModeEN")
            writeIni("statusMode", _, "InputMethod")
            writeIni("conversionMode", readIni("conversionModeEN", "", "InputMethod"), "InputMethod")
            writeIni("evenStatusMode", readIni("evenStatusModeEN", "", "InputMethod"), "InputMethod")
            writeIni("evenConversionMode", readIni("evenConversionModeEN", "", "InputMethod"), "InputMethod")
            IniDelete("InputTip.ini", "InputMethod", "statusModeEN")
            IniDelete("InputTip.ini", "InputMethod", "conversionModeEN")
            IniDelete("InputTip.ini", "InputMethod", "evenStatusModeEN")
            IniDelete("InputTip.ini", "InputMethod", "evenConversionModeEN")
        } catch {
            mode := readIni("mode", 1, "InputMethod")
            switch mode {
                case 2:
                    writeIni("mode", 1, "InputMethod")
                case 3:
                    ; 讯飞输入法
                    writeIni("evenStatusMode", "0", "InputMethod")
                    writeIni("mode", 0, "InputMethod")
                case 4:
                    ; 手心输入法
                    writeIni("conversionMode", ":1:", "InputMethod")
                    writeIni("mode", 0, "InputMethod")
            }
            border_type := readIni('border_type', 1)
            if (border_type = 4) {
                writeIni('border_type', 0)
            }
        }

        modeRules := []
        for v in ["statusMode", "conversionMode"] {
            try {
                _ := IniRead("InputTip.ini", "InputMethod", v)
                modeRules.Push(StrReplace(RegExReplace(_, "(^:)|(:$)", ""), ":", "/"))
                IniDelete("InputTip.ini", "InputMethod", v)
            }
        }
        for i, v in ["evenStatusMode", "evenConversionMode"] {
            try {
                _ := IniRead("InputTip.ini", "InputMethod", v)
                if (_ != "") {
                    modeRules[i] := _ ? "evenNum" : "oddNum"
                }
                IniDelete("InputTip.ini", "InputMethod", v)
            }
        }
        if (modeRules.Length) {
            baseStatus := readIni("baseStatus", 0, "InputMethod")
            modeRules.Push(baseStatus)
            writeIni("baseStatus", !baseStatus, "InputMethod")
            try {
                IniDelete("InputTip.ini", "InputMethod", "baseStatus")
            }
            writeIni("modeRule", arrJoin(modeRules, "*"), "InputMethod")
        }

        try {
            IniRead("InputTip.ini", "Config-v2", "textSymbol_CN_color")
        } catch {
            writeIni("textSymbol_CN_color", readIni("CN_color", "red"))
            writeIni("textSymbol_EN_color", readIni("EN_color", "blue"))
            writeIni("textSymbol_Caps_color", readIni("Caps_color", "green"))
            writeIni("textSymbol_transparent", readIni('transparent', 222))
            writeIni("textSymbol_offset_x", readIni('offset_x', 10))
            writeIni("textSymbol_offset_y", readIni('offset_y', -30))
            writeIni("textSymbol_border_type", readIni('border_type', 1))
        }

        ; 配置项更名
        replaceConfig := [
            ["JetBrains_list", "cursor_mode_JAB"],
            ["enableJetBrainsSupport", "enableJABSupport"],
        ]
        for v in replaceConfig {
            try {
                _ := IniRead("InputTip.ini", "Config-v2", v[1])
                writeIni(v[2], _)
                IniDelete("InputTip.ini", "Config-v2", v[1])
            }
        }

        if (silentUpdate && !readIni("clickUpdate", 0)) {
            SetTimer(handlePostUpdate, -500)
            return
        }

        handlePostUpdate() {
            for v in [flagFile, flagFile2, A_AppData "/abgox-InputTip-update-version.exe", A_ScriptDir "/InputTipSymbol/default/abgox-InputTip-update-version.exe"] {
                try {
                    FileDelete(v)
                }
            }
            writeIni("version", currentVersion, "UserInfo")
            writeIni("clickUpdate", 0)
        }

        createGui(doneGui).Show()
        doneGui(info) {
            g := Gui("AlwaysOnTop", "InputTip - 版本更新完成")
            g.SetFont("s14", "Microsoft YaHei")
            g.AddText(, "版本更新完成，当前版本: ")
            g.AddText("yp cRed", currentVersion)
            g.AddText("xs", "-------------------------------------------")
            g.AddText("xs", "建议查看更新日志，了解最新变化")
            g.AddLink("xs", '版本更新日志:   <a href="https://inputtip.abgox.com/v2/changelog">官网</a>   <a href="https://github.com/abgox/InputTip/blob/main/src/CHANGELOG.md">Github</a>   <a href="https://gitee.com/abgox/InputTip/blob/main/src/CHANGELOG.md">Gitee</a>')

            if (info.i) {
                return g
            }
            w := info.w
            bw := w - g.MarginX * 2

            y := g.AddButton("xs w" bw, "我知道了")
            y.Focus()
            g.OnEvent("Close", yes)
            y.OnEvent("Click", yes)
            yes(*) {
                g.Destroy()
                handlePostUpdate()
            }
            return g
        }
    }
}
