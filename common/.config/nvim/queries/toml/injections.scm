; extends

(pair
  (bare_key) @key (#eq? @key "run")
  (string) @injection.content @injection.language

  (#is-mise?)
  (#lua-match? @injection.content "^['\"]%s*#!.*/env%s+%-S%s+uv%s+run%s+%-%-script") ; uv script shebang
  (#set! injection.language "python")
  (#offset! @injection.content 0 3 0 -3) ; rm quotes
)

(pair
  (bare_key) @key (#eq? @key "run")
  (string) @injection.content @injection.language

  (#is-mise?)
  (#lua-match? @injection.content "^['\"]%s*#!.*/env%s+%-S%s+[^%s]+") ; multiline shebang using env -S
  (#not-lua-match? @injection.content "^['\"]%s*#!.*/env%s+%-S%s+uv%s+run%s+%-%-script") ; handled above
  (#gsub! @injection.language "^.*#!/.*/env%s+-S%s+([^%s]+).*" "%1") ; extract lang
  (#offset! @injection.content 0 3 0 -3) ; rm quotes
)

(pair
  (bare_key) @key (#eq? @key "run")
  (string) @injection.content @injection.language

  (#is-mise?)
  (#lua-match? @injection.content "^['\"]%s*#!.*/env%s+[^%s]+") ; multiline shebang using env
  (#gsub! @injection.language "^.*#!/.*/env%s+([^%s]+).*" "%1") ; extract lang
  (#offset! @injection.content 0 3 0 -3) ; rm quotes
)

(pair
  (bare_key) @key (#eq? @key "run")
  (string) @injection.content @injection.language

  (#is-mise?)
  (#lua-match? @injection.content "^['\"]%s*#!/[^%s]+") ; multiline shebang
  (#gsub! @injection.language "^.*#!/.*/([^/%s]+).*" "%1") ; extract lang
  (#offset! @injection.content 0 3 0 -3) ; rm quotes
)

(pair
  (bare_key) @key (#eq? @key "run")
  (string) @injection.content

  (#is-mise?)
  (#lua-match? @injection.content "^['\"]%s*.*") ; multiline
  (#not-lua-match? @injection.content "^['\"]%s*#!") ; no shebang
  (#offset! @injection.content 0 3 0 -3) ; rm quotes
  (#set! injection.language "zsh") ; default to zsh
)

(pair
  (bare_key) @key (#eq? @key "run")
  (string) @injection.content

  (#is-mise?)
  (#not-lua-match? @injection.content "^['\"]{3}") ; not multiline
  (#offset! @injection.content 0 1 0 -1) ; rm quotes
  (#set! injection.language "zsh") ; default to zsh
)
