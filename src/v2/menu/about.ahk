fn_about(*) {
    if (gc.w.aboutGui) {
        gc.w.aboutGui.Destroy()
        gc.w.aboutGui := ""
    }
    aboutGui := Gui("AlwaysOnTop")
    aboutGui.SetFont(fz, "微软雅黑")
    aboutGui.AddText(, "InputTip - 一个输入法状态(中文/英文/大写锁定)提示工具")
    aboutGui.AddLink(, '- 因为实现简单，就是去掉 v1 中方块符号的文字，加上不同的背景颜色')
    aboutGui.AddPicture("w365 h-1", "InputTipSymbol\default\offer.png")
    aboutGui.Show("Hide")
    aboutGui.GetPos(, , &Gui_width)
    aboutGui.Destroy()

    aboutGui := Gui("AlwaysOnTop", "InputTip - v" currentVersion)
    aboutGui.SetFont(fz, "微软雅黑")
    aboutGui.AddText("Center w" Gui_width, "InputTip - 一个输入法状态(中文/英文/大写锁定)实时提示工具")
    tab := aboutGui.AddTab3("-Wrap", ["关于项目", "赞赏支持", "参考项目", "其他项目"])
    tab.UseTab(1)
    aboutGui.AddText("Section", '当前版本: ')
    aboutGui.AddEdit("yp ReadOnly cRed", currentVersion)
    aboutGui.AddText("xs", '开发人员: ')
    aboutGui.AddEdit("yp ReadOnly", 'abgox')
    aboutGui.AddText("xs", 'QQ 账号: ')
    aboutGui.AddEdit("yp ReadOnly", '1151676611')
    aboutGui.AddText("xs", 'QQ 群聊(交流反馈): ')
    aboutGui.AddEdit("yp ReadOnly", '451860327')
    aboutGui.AddText("xs", "-------------------------------------------------------------------------------")
    aboutGui.AddLink("xs", '1. 官网: <a href="https://inputtip.pages.dev">https://inputtip.pages.dev</a>')
    aboutGui.AddLink("xs", '2. Github: <a href="https://github.com/abgox/InputTip">https://github.com/abgox/InputTip</a>')
    aboutGui.AddLink("xs", '3. Gitee: <a href="https://gitee.com/abgox/InputTip">https://gitee.com/abgox/InputTip</a>')
    tab.UseTab(2)
    aboutGui.AddText("Section", "如果 InputTip 对你有所帮助，你也可以出于善意, 向我捐款。`n非常感谢对 InputTip 的支持！希望 InputTip 能一直帮助你！")
    aboutGui.AddPicture("h-1 w" Gui_width / 4 * 3, "InputTipSymbol\default\offer.png")
    tab.UseTab(3)
    aboutGui.AddLink("Section", '1. <a href="https://github.com/aardio/ImTip">ImTip - aardio</a>')
    aboutGui.AddLink("xs", '2. <a href="https://github.com/flyinclouds/KBLAutoSwitch">KBLAutoSwitch - flyinclouds</a>')
    aboutGui.AddLink("xs", '3. <a href="https://github.com/Tebayaki/AutoHotkeyScripts">AutoHotkeyScripts - Tebayaki</a>')
    aboutGui.AddLink("xs", '4. <a href="https://github.com/Autumn-one/RedDot">RedDot - Autumn-one</a>')
    aboutGui.AddLink("xs", '5. <a href="https://github.com/yakunins/language-indicator">language-indicator - yakunins</a>')
    aboutGui.AddLink("xs", '- InputTip v1 是在鼠标附近显示带文字的方块符号')
    aboutGui.AddLink("xs", '- InputTip v2 默认通过不同颜色的鼠标样式来区分')
    aboutGui.AddLink("xs", '- 后来参照了 RedDot 和 language-indicator 的设计')
    aboutGui.AddLink("xs", '- 因为实现很简单，就是去掉 v1 中方块符号的文字，加上不同的背景颜色')

    tab.UseTab(4)
    aboutGui.AddLink("Section w" Gui_width, '1. <a href="https://pscompletions.pages.dev/">PSCompletions</a> : 一个 PowerShell 补全模块，它能让你在 PowerShell 中更简单、更方便地使用命令补全。')
    aboutGui.AddLink("Section w" Gui_width, '2. ...')

    tab.UseTab(0)
    btn := aboutGui.AddButton("Section w" Gui_width + aboutGui.MarginX * 2, "关闭")
    btn.Focus()
    btn.OnEvent("Click", fn_close)
    aboutGui.OnEvent("Close", fn_close)
    fn_close(*) {
        aboutGui.Destroy()
    }
    gc.w.aboutGui := aboutGui
    aboutGui.Show()
}
