#>>> Homebrew initialization
#
OS=$(uname -s)
if [[ $OS == "Darwin" ]]; then
    BREW_PREFIX="opt/homebrew"

    BREW_PATH=""
    if [[ :/Users/alealfaro/.pyenv/shims:/opt/homebrew/opt/llvm/bin:/opt/homebrew/bin:/opt/homebrew/opt/llvm/bin:/usr/local/bin:/System/Cryptexes/App/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Users/alealfaro/go/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin:/opt/X11/bin:/Library/Apple/usr/bin:/Library/TeX/texbin:/Applications/Wireshark.app/Contents/MacOS:/usr/local/go/bin:/Users/alealfaro/.cargo/bin:/Applications/Ghostty.app/Contents/MacOS: != *:/bin:* ]]; then
        BREW_PATH=/bin:
    fi
    if [[ :/Users/alealfaro/.pyenv/shims:/opt/homebrew/opt/llvm/bin:/opt/homebrew/bin:/opt/homebrew/opt/llvm/bin:/usr/local/bin:/System/Cryptexes/App/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Users/alealfaro/go/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin:/opt/X11/bin:/Library/Apple/usr/bin:/Library/TeX/texbin:/Applications/Wireshark.app/Contents/MacOS:/usr/local/go/bin:/Users/alealfaro/.cargo/bin:/Applications/Ghostty.app/Contents/MacOS: != *:/sbin:* ]]; then
        BREW_PATH=/sbin:
    fi
    if [[ :/Users/alealfaro/.pyenv/shims:/opt/homebrew/opt/llvm/bin:/opt/homebrew/bin:/opt/homebrew/opt/llvm/bin:/usr/local/bin:/System/Cryptexes/App/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Users/alealfaro/go/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin:/opt/X11/bin:/Library/Apple/usr/bin:/Library/TeX/texbin:/Applications/Wireshark.app/Contents/MacOS:/usr/local/go/bin:/Users/alealfaro/.cargo/bin:/Applications/Ghostty.app/Contents/MacOS: != *:/usr/local/bin:* ]]; then
        BREW_PATH=/usr/local/bin:
    fi
    if [[ :/Users/alealfaro/.pyenv/shims:/opt/homebrew/opt/llvm/bin:/opt/homebrew/bin:/opt/homebrew/opt/llvm/bin:/usr/local/bin:/System/Cryptexes/App/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Users/alealfaro/go/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin:/opt/X11/bin:/Library/Apple/usr/bin:/Library/TeX/texbin:/Applications/Wireshark.app/Contents/MacOS:/usr/local/go/bin:/Users/alealfaro/.cargo/bin:/Applications/Ghostty.app/Contents/MacOS: != *:/usr/local/sbin:* ]]; then
        BREW_PATH=/usr/local/sbin:
    fi
    if [ ! -z  ]; then
        export PATH=/Users/alealfaro/.pyenv/shims:/opt/homebrew/opt/llvm/bin:/opt/homebrew/bin:/opt/homebrew/opt/llvm/bin:/usr/local/bin:/System/Cryptexes/App/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Users/alealfaro/go/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin:/opt/X11/bin:/Library/Apple/usr/bin:/Library/TeX/texbin:/Applications/Wireshark.app/Contents/MacOS:/usr/local/go/bin:/Users/alealfaro/.cargo/bin:/Applications/Ghostty.app/Contents/MacOS
    fi


#>>> llvm PATH
    export PATH="/opt/homebrew/opt/llvm/bin:$PATH"

    export PATH="/opt/homebrew/bin:$PATH"
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    # source<(keychain --eval --quiet id_ed25519 id_rsa ~/.ssh/id_ed25519)
fi
