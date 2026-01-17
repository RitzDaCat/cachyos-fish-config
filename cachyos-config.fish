## 1. Initial Source
# Source cachyos-fish-config (ensure path exists to avoid errors)
if test -f /usr/share/cachyos-fish-config/conf.d/done.fish
    source /usr/share/cachyos-fish-config/conf.d/done.fish
end

## 2. Global Settings
# Use global (-g) instead of universal (-U) for static config to reduce I/O
set -g __done_min_cmd_duration 10000
set -g __done_notification_urgency_level low

# Environment Variables
set -gx MANROFFOPT "-c"
set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"

# Welcome Message
function fish_greeting
    fastfetch
end

## 3. Path Management
# Using a loop to keep the config DRY (Don't Repeat Yourself)
for bin_path in ~/.local/bin ~/Applications/depot_tools
    if test -d $bin_path
        if not contains -- $bin_path $PATH
            set -p PATH $bin_path
        end
    end
end

## 4. Enhanced Functions
# History expansion (!! and !$)
function __history_previous_command
    switch (commandline -t)
        case "!"
            commandline -t $history[1]; commandline -f repaint
        case "*"
            commandline -i !
    end
end

function __history_previous_command_arguments
    switch (commandline -t)
        case "!"
            commandline -t ""
            commandline -f history-token-search-backward
        case "*"
            commandline -i '$'
    end
end

# Keybindings
if [ "$fish_key_bindings" = fish_vi_key_bindings ]
    bind -Minsert ! __history_previous_command
    bind -Minsert '$' __history_previous_command_arguments
else
    bind ! __history_previous_command
    bind '$' __history_previous_command_arguments
end

# Optimized Backup
function backup --argument filename
    cp -v $filename $filename.(date +%Y%m%d_%H%M%S).bak
end

# Optimized Copy with string manipulation
function copy
    set -l count (count $argv)
    if test "$count" -eq 2; and test -d "$argv[1]"
        set -l from (string trim -r -c / $argv[1])
        set -l to $argv[2]
        command cp -r $from $to
    else
        command cp $argv
    end
end

## 5. Abbreviations & Aliases
# Abbreviations expand upon pressing 'Space', preventing AI stalling
# and ensuring the real command is recorded in history.

# Search & File logic (The "Anti-Stall" fix)
abbr -a grep 'grep --color=auto'
abbr -a find 'find'

# Modern Replacements
alias ls='eza -al --color=always --group-directories-first --icons'
alias la='eza -a --color=always --group-directories-first --icons'
alias ll='eza -l --color=always --group-directories-first --icons'
alias lt='eza -aT --color=always --group-directories-first --icons'

# Navigation
abbr -a .. 'cd ..'
abbr -a ... 'cd ../..'
abbr -a .... 'cd ../../..'

# Maintenance & System
abbr -a update 'sudo pacman -Syu'
abbr -a grubup 'sudo grub-mkconfig -o /boot/grub/grub.cfg'
abbr -a fixpacman 'sudo rm /var/lib/pacman/db.lck'

# Conditional Cleanup (Safety fix)
function cleanup
    set -l orphans (pacman -Qtdq)
    if test -n "$orphans"
        sudo pacman -Rns $orphans
    else
        echo "No orphaned packages found."
    end
end

# Hardware & Monitoring
alias psmem='ps auxf | sort -nr -k 4'
alias hinfo='hwinfo --short'
alias jctl="journalctl -p 3 -xb"

# Package analysis
alias big="expac -H M '%m\t%n' | sort -h | nl"
alias rip="expac --timefmt='%Y-%m-%d %T' '%l\t%n %v' | sort | tail -200 | nl"

## 6. Shell Integration
# Apply .profile if it exists
if test -f ~/.fish_profile
    source ~/.fish_profile
end
