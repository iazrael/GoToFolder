-- Go2Shell Finder Toolbar Script
-- 将此脚本拖到 Finder 工具栏即可使用

on run
    tell application "Finder"
        -- 获取当前窗口路径
        if (count of windows) > 0 then
            set currentPath to POSIX path of (target of front window as alias)
        else
            set currentPath to POSIX path of (path to desktop folder as alias)
        end if
    end tell

    -- 打开终端并 cd 到该路径
    tell application "Terminal"
        activate
        do script "cd \"" & currentPath & "\""
    end tell
end run
