/*
@link https://github.com/Tebayaki/AutoHotkeyScripts/blob/main/lib/IME.ahk
@Example
; 获取当前输入法输入模式
f1::ToolTip IME.GetInputMode()
; 切换当前输入法输入模式
f2::IME.SetInputMode(!IME.GetInputMode())
*/
class IME {
    static GetInputMode(hwnd := this.GetFocusedWindow()) {
        if !this.GetOpenStatus(hwnd) {
            return false
        }
        return this.GetConversionMode(hwnd) & 1
    }

    static SetInputMode(mode, hwnd := this.GetFocusedWindow()) {
        if mode {
            this.SetOpenStatus(true, hwnd)
            switch this.GetKeyboardLayout(hwnd) {
                case 0x08040804:
                    this.SetConversionMode(1025, hwnd)
                case 0x04110411:
                    this.SetConversionMode(9, hwnd)
            }
        }
        else {
            this.SetOpenStatus(false, hwnd)
        }
    }

    static ToggleInputMode(hwnd := this.GetFocusedWindow()) {
        this.SetInputMode(!this.GetInputMode(hwnd), hwnd)
    }

    static GetOpenStatus(hwnd := this.GetFocusedWindow()) {
        DllCall("SendMessageTimeoutW", "ptr", DllCall("imm32\ImmGetDefaultIMEWnd", "ptr", hwnd, "ptr"), "uint", 0x283, "ptr", 0x5, "ptr", 0, "uint", 0, "uint", 200, "ptr*", &status := 0)
        return status
    }

    static SetOpenStatus(status, hwnd := this.GetFocusedWindow()) {
        DllCall("SendMessageTimeoutW", "ptr", DllCall("imm32\ImmGetDefaultIMEWnd", "ptr", hwnd, "ptr"), "uint", 0x283, "ptr", 0x6, "ptr", status, "uint", 0, "uint", 200, "ptr*", 0)
    }

    static GetConversionMode(hwnd := this.GetFocusedWindow()) {
        DllCall("SendMessageTimeoutW", "ptr", DllCall("imm32\ImmGetDefaultIMEWnd", "ptr", hwnd, "ptr"), "uint", 0x283, "ptr", 0x1, "ptr", 0, "uint", 0, "uint", 200, "ptr*", &mode := 0)
        return mode
    }

    static SetConversionMode(mode, hwnd := this.GetFocusedWindow()) {
        DllCall("SendMessageTimeoutW", "ptr", DllCall("imm32\ImmGetDefaultIMEWnd", "ptr", hwnd, "ptr"), "uint", 0x283, "ptr", 0x2, "ptr", mode, "uint", 0, "uint", 200, "ptr*", 0)
    }

    static GetKeyboardLayout(hwnd := this.GetFocusedWindow()) {
        return DllCall("GetKeyboardLayout", "uint", DllCall("GetWindowThreadProcessId", "ptr", hwnd, "ptr", 0, "uint"), "ptr")
    }

    static SetKeyboardLayout(hkl, hwnd := this.GetFocusedWindow()) {
        SendMessage(0x50, 1, hkl, hwnd)
    }

    static GetKeyboardLayoutList() {
        if cnt := DllCall("GetKeyboardLayoutList", "int", 0, "ptr", 0) {
            list := []
            buf := Buffer(cnt * A_PtrSize)
            loop DllCall("GetKeyboardLayoutList", "int", cnt, "ptr", buf) {
                list.Push(NumGet(buf, (A_Index - 1) * A_PtrSize, "ptr"))
            }
            return list
        }
    }

    static LoadKeyboardLayout(hkl) {
        return DllCall("LoadKeyboardLayoutW", "str", Format("{:08x}", hkl), "uint", 0x101)
    }

    static UnloadKeyboardLayout(hkl) {
        return DllCall("UnloadKeyboardLayout", "ptr", hkl)
    }

    static GetFocusedWindow() {
        if foreHwnd := WinExist("A") {
            guiThreadInfo := Buffer(A_PtrSize == 8 ? 72 : 48)
            NumPut("uint", guiThreadInfo.Size, guiThreadInfo)
            DllCall("GetGUIThreadInfo", "uint", DllCall("GetWindowThreadProcessId", "ptr", foreHwnd, "ptr", 0, "uint"), "ptr", guiThreadInfo)
            if focusedHwnd := NumGet(guiThreadInfo, A_PtrSize == 8 ? 16 : 12, "ptr") {
                return focusedHwnd
            }
            return foreHwnd
        }
        return 0
    }
}

/**
 * 判断当前输入法状态是否为中文
 * @param {1 | 2 | 3} mode 使用的模式
 * @returns {Boolean} 输入法是否为中文
 * @example
 * ; 微信输入法,微软(拼音/五笔)，搜狗输入法,QQ输入法,冰凌五笔
 * ;   中文时，返回1，英文时返回0
 * ; 讯飞输入法
 * ;   中文时，返回2，英文时返回1
 * ; 百度输入法，手心输入法，谷歌输入法，2345王牌输入法，小鹤音形,小狼毫(rime)
 * ;   中英文都返回1，因此无法判断是不是中文
 */
isCN(mode) {
    if (mode = 2) {
        return IME.GetInputMode()
    }
    return mode = SendMessage(
        0x283,    ; Message : WM_IME_CONTROL
        0x005,    ; wParam  : IMC_GETCONVERSIONMODE
        0,    ; lParam  ： (NoArgs)
        , "ahk_id " DllCall("imm32\ImmGetDefaultIMEWnd", "Uint", WinGetID("A"), "Uint") ; Control ： (Window)
    )
}