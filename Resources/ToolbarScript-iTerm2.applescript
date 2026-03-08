-- Go2Shell Finder Toolbar Script for iTerm2
-- 将此脚本拖到 Finder 工具栏即可使用

on run
    tell application "Finder"
        if (count of windows) > 0 then
            set currentPath to POSIX path of (target of front window as alias)
        else
            set currentPath to POSIX path of (path to desktop folder as alias)
        end if
    end tell

    tell application "iTerm"
        activate
        set newWindow to (create window with default profile)
        tell current session of newWindow
            write text "cd \"" & currentPath & "\""
        end tell
    end tell
end run
