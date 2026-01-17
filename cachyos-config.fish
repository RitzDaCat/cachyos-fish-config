## 1. Path Optimization (Portable)
# fish_add_path is idempotent and handles existence checks internally.
# Using '~' ensures it expands to the home directory of the current user.
fish_add_path -m ~/.local/bin ~/Applications/depot_tools ~/Develop/flutter/bin

## 2. Tool-Call Hardening (Anti-Stall)
# Prevents CLI tools from hanging on interactive prompts during AI calls.
set -gx FLUTTER_NO_ANALYTICS 1
set -gx PUB_ENVIRONMENT flutter_cli:fish_ai

# Dynamic Chrome/Browser detection for Flutter web/testing
if test -z "$CHROME_EXECUTABLE"
    for browser in google-chrome-stable google-chrome chromium brave-bin brave
        if type -q $browser
            set -gx CHROME_EXECUTABLE (type -p $browser)
            break
        end
    end
end

## 3. Global Environment & Pager
# Using -gx (Global Export) keeps these in memory rather than writing to disk.
set -gx MANROFFOPT "-c"
if type -q bat
    set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"
end

# Optimization for 'done' plugin (CachyOS Default)
set -g __done_min_cmd_duration 10000
set -g __done_notification_urgency_level low

## 4. High-Speed Abbreviations (Universal)
# These replace the function-lookup overhead of 'alias'

# Navigation
abbr -a .. 'cd ..'
abbr -a ... 'cd ../..'
abbr -a .... 'cd ../../..'

# Modern Replacements (eza)
if type -q eza
    abbr -a ls 'eza -al --color=always --group-directories-first --icons'
    abbr -a la 'eza -a --color=always --group-directories-first --icons'
    abbr -a ll 'eza -l --color=always --group-directories-first --icons'
    abbr -a lt 'eza -aT --color=always --group-directories-first --icons'
end

# Development (Flutter)
if type -q flutter
    abbr -a fld 'flutter doctor'
    abbr -a flr 'flutter run'
    abbr -a flg 'flutter pub get'
    abbr -a flc 'flutter clean'
end

# System Management (Arch/CachyOS)
abbr -a update 'sudo pacman -Syu'
abbr -a grubup 'sudo grub-mkconfig -o /boot/grub/grub.cfg'
abbr -a fixpacman 'sudo rm /var/lib/pacman/db.lck'
[ -f /usr/bin/cachyos-rate-mirrors ] && abbr -a mirror 'sudo cachyos-rate-mirrors'

# Cleanup Logic (Hardened against empty arguments)
function cleanup
    set -l orphans (pacman -Qtdq)
    if test -n "$orphans"
        sudo pacman -Rns $orphans
    else
        echo "No orphaned packages found."
    end
end

# Search (The Anti-Stall Fix)
abbr -a grep 'grep --color=auto'
abbr -a jctl 'journalctl -p 3 -xb'

## 5. Optimized Native Functions (Zero-Fork)
# Uses Fish-native C++ string manipulation to avoid subshells.
function copy
    if test (count $argv) -eq 2; and test -d "$argv[1]"
        command cp -r (string trim -r -c / $argv[1]) $argv[2]
    else
        command cp $argv
    end
end

function backup --argument filename
    cp -v $filename $filename.(date +%Y%m%d_%H%M%S).bak
end

## 6. Interactive-Only Features
# Ensures non-interactive scripts/AI calls don't load heavy UI elements.
if status is-interactive

    # Static or Fastfetch Greeting
    function fish_greeting
        if type -q fastfetch
            fastfetch
        else
            echo -e (set_color blue)"Welcome to Fish "(set_color yellow)(fish --version)(set_color normal)
        end
    end

    # Bang-Bang History Expansion (!! and !$)
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

    # Bindings (Supports both Default and Vi-mode)
    bind ! __history_previous_command
    bind '$' __history_previous_command_arguments
    if [ "$fish_key_bindings" = fish_vi_key_bindings ]
        bind -Minsert ! __history_previous_command
        bind -Minsert '$' __history_previous_command_arguments
    end
end

## 7. Plugin & Profile Sourcing
# Checks file existence before sourcing to prevent startup errors.
[ -f /usr/share/cachyos-fish-config/conf.d/done.fish ] && source /usr/share/cachyos-fish-config/conf.d/done.fish
[ -f ~/.fish_profile ] && source ~/.fish_profile
