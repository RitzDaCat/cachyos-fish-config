# Cachyos Fish Config

###Ritz Changes 
Variable Scope: From Universal (-U) to Global (-g)

In your original config, you used set -U for the done plugin settings.

    Original: set -U __done_min_cmd_duration 10000

    Modification: set -g __done_min_cmd_duration 10000

    Reasoning: Universal variables are stored on disk (~/.config/fish/fish_variables) and persist even if you delete your config file. Setting them with -U inside a config.fish causes the shell to rewrite that disk file every time you open a terminal. By using -g (Global), we keep the settings in memory for that session only, reducing unnecessary disk I/O and preventing potential synchronization issues across multiple open terminals.

2. Alias vs. Abbreviation (abbr)

This is the primary fix for the AI "stalling" you experienced.

    Original: alias grep='grep --color=auto'

    Modification: abbr -a grep 'grep --color=auto'

    Reasoning: An alias in Fish creates a hidden function. When an AI or a script sends a complex command with wildcards (*), the shell parser has to resolve that function name while simultaneously expanding the wildcard. An abbr expands instantly upon the spacebar or enter key being pressed. This "pre-expands" the command, giving the AI and the Fish parser a literal string to work with, which bypasses the logic-loop that causes stalling.

3. Native String Manipulation

We replaced external piping with Fish built-ins.

    Original: set from (echo $argv[1] | trim-right /)

    Modification: set -l from (string trim -r -c / $argv[1])

    Reasoning: In the original version, Fish had to:

        Spawn a subshell for echo.

        Create a pipe.

        Spawn an external process for trim-right. The modified version uses string, which is a compiled C++ library inside the Fish binary itself. According to official Fish documentation, internal string operations are significantly faster and more memory-efficient than piping to external binaries (fishshell.com, 2024).

4. Logical Guarding (The "Safety Fix")

We transitioned the cleanup alias into a robust function.

    Original: alias cleanup='sudo pacman -Rns (pacman -Qtdq)'

    Modification: ```fish function cleanup set -l orphans (pacman -Qtdq) if test -n "$orphans" sudo pacman -Rns $orphans end end

    Reasoning: In the original alias, if you ran cleanup when no orphans existed, pacman -Qtdq would return an empty string. The resulting command executed would be sudo pacman -Rns, which is an invalid command that returns an error. The new logic checks if the variable $orphans is non-empty (test -n) before attempting to run the deletion, ensuring a "silent success" instead of a "noisy failure."

5. Path Normalization Loop

Instead of repeated if blocks for every new directory, we used a collection-based approach.

    Modification: for bin_path in ~/.local/bin ~/Applications/depot_tools ... end

    Reasoning: This follows the DRY (Don't Repeat Yourself) principle of software engineering. It reduces the "surface area" for bugs; if you need to change how you validate paths (e.g., checking for permissions as well as existence), you only have to change the code in one place rather than three or four.

