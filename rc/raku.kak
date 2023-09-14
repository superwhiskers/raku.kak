# https://raku.org

# detection

hook global BufCreate .*\.(raku|rakumod|rakudoc|rakutest)$ %{
    set-option buffer filetype raku
}

# init

hook global WinSetOption filetype=raku %{
    require-module raku

    set-option window static_words %opt{raku_static_words}
    set-option buffer extra_word_chars '_' '-'

    hook window ModeChange pop:insert:.* -group raku-trim-indent %{ try %{ execute-keys -draft <a-x>s^\h+$<ret>d } }

    hook window InsertChar \n -group raku-insert raku-insert-on-new-line
    hook window InsertChar \n -group raku-indent raku-indent-on-new-line
    hook window InsertChar \{ -group raku-indent raku-indent-on-opening-curly-brace
    hook window InsertChar \} -group raku-indent raku-indent-on-closing-curly-brace

    hook -once -always window WinSetOption filetype=.* %{ remove-hooks window raku-.+ }
}

hook -group raku-highlight global WinSetOption filetype=raku %{
    add-highlighter window/raku ref raku
    hook -once -always window WinSetOption filetype=.* %{ remove-highlighter window/raku }
}

provide-module raku %§

# highlighting

add-highlighter shared/raku regions

add-highlighter shared/raku/code default-region group

# strings
add-highlighter shared/raku/double_string region '"' (?<!\\)(\\\\)*" fill string
add-highlighter shared/raku/single_string region "(?<![a-zA-Z0-9_])'" (?<!\\)(\\\\)*' fill string
add-highlighter shared/raku/heredoc_strings region -match-capture '(?:q|qq|Q):to/([a-zA-Z_\-]+)/' '([a-zA-Z_\-]+)\h*' fill string

# comments
add-highlighter shared/raku/line_comment region "#[^`|=]" $ fill comment
add-highlighter shared/raku/paren_block_comment region -recurse \( "#`\(" \) fill comment
add-highlighter shared/raku/brace_block_comment region -recurse \{ "#`\{" \} fill comment
add-highlighter shared/raku/square_bracket_block_comment region -recurse \[ "#`\[" \] fill comment
add-highlighter shared/raku/angle_bracket_block_comment region -recurse < "#`<" > fill comment

# pod
# ideally we'd have a dedicated highlighter for pod syntax but for the time being, this should work perfectly fine
add-highlighter shared/raku/pod_block region -match-capture "^=begin (([a-zA-Z_])(('|-)[a-zA-Z_]|[a-zA-Z0-9_])*))" "^=end (([a-zA-Z_])(('|-)[a-zA-Z_]|[a-zA-Z0-9_])*))" fill comment
add-highlighter shared/raku/pod region "^=([a-zA-Z_])(('|-)[a-zA-Z_]|[a-zA-Z0-9_])*)" ^$ fill comment

# pod documentation
add-highlighter shared/raku/pod_doc_comment region "#[|=][^(]" $ fill documentation
add-highlighter shared/raku/pod_block_doc_comment region -recurse \( "#[|=]\(" \) fill documentation

evaluate-commands %sh{
    keywords="use require import unit no need
              if is else elsif unless with orwith without once
              let my our state temp has constant
              for loop repeat while until gather given
              supply react race hyper lazy quietly
              take take-rw do when next last redo return return-rw
              start default exit make continue break goto leave
              proceed succeed whenever emit done
              BEGIN CHECK INIT FIRST ENTER LEAVE KEEP
              UNDO NEXT LAST PRE POST END CATCH CONTROL
              DOC QUIT CLOSE COMPOSE
              die fail try warn
              multi proto only
              macro sub submethod method module class role package enum grammar slang subset
              regex rule token
              does as but trusts of returns handles whree augment supersede
              signature context also shape prec irs ofs ors export deep binary unary reparsed
              rw parsed cached readonly defequiv will ref copy inline tighter looser equiv
              assoc required DEPRECATED raw repr dynamic hidden-from-backtrace nodal pure
              implementation-detail
              plan done-testing bail-out todo skip skip-rest diag subtest pass flunk ok nok
              cmp-ok is-deeply isnt is-approx like unlike use-ok isa-ok does-ok can-ok dies-ok
              lives-ok eval-dies-ok eval-lives-ok throws-like fails-like"
    meta="MONKEY-GUTS MONKEY-SEE-NO-EVAL MONKEY-TYPING MONKEY dynamic-scope experimental fatal
          internals invocant isms lib newline nqp parameters precompilation soft strict trace
          variables worries"
    builtins="EVAL EVALFILE mkdir chdir chmod indir print put say note prompt open slurp spurt
              run shell unpolar printf sprintf flat unique repeated squish emit undefine pop
              shift push append exit done lastcall"
    operators="div xx x mod also leg cmp before after eq ne le lt not
               gt ge eqv ff fff and andthen or xor orelse extra lcm gcd o
               unicmp notandthen minmax"
    types="int int1 int2 int4 int8 int16 int32 int64
           rat rat1 rat2 rat4 rat8 rat16 rat32 rat64
           buf buf1 buf2 buf4 buf8 buf16 buf32 buf64
           uint uint1 uint2 uint4 uint8 uint16 uint32 bit bool
           uint64 utf8 utf16 utf32 bag set mix complex
           num num32 num64 long longlong Pointer size_t str void
           ulong ulonglong ssize_t atomicint
           Object Any Junction Whatever Capture Match
           Signature Proxy Matcher Package Module Class
           Grammar Scalar Array Hash KeyHash KeySet KeyBag
           Pair List Seq Range Set Bag Map Mapping Void Undef
           Failure Exception Code Block Routine Sub Macro
           Method Submethod Regex Str Blob Char Byte Parcel
           Codepoint Grapheme StrPos StrLen Version Num
           Complex Bit True False Order Same Less More
           Increasing Decreasing Ordered Callable AnyChar
           Positional Associative Ordering KeyExtractor
           Comparator OrderingPair IO KitchenSink Role
           Int Rat Buf UInt Abstraction Numeric Real
           Nil Mu SeekFromBeginning SeekFromEnd SeekFromCurrent"

    join() { sep=$2; eval set -- $1; IFS="$sep"; echo "$*"; }

    printf %s\\n "declare-option str-list raku_static_words $(join "${keywords} ${meta} ${builtins} ${operators} ${types}" ' ')"

    printf %s "
        add-highlighter shared/raku/code/ regex \b($(join "${keywords}" '|'))\b 0:keyword
        add-highlighter shared/raku/code/ regex \b($(join "${meta}" '|'))\b 0:meta
        add-highlighter shared/raku/code/ regex \b($(join "${builtins}" '|'))\b 0:builtin
        add-highlighter shared/raku/code/ regex \b($(join "${operators}" '|'))\b 0:operator
        add-highlighter shared/raku/code/ regex \b($(join "${types}" '|'))\b 0:type
    "
}

add-highlighter shared/raku/code/ regex \b(v6(\.[a-z](\.PREVIEW)?)?)\b 0:meta
add-highlighter shared/raku/code/ regex ([\$@%&](\*|\.|!|<|\^|:|=|~|\?)?([a-zA-Z_])(('|-)[a-zA-Z_]|[a-zA-Z0-9_])*)\b 0:variable
add-highlighter shared/raku/code/ regex \b(True|False)\b 0:value
add-highlighter shared/raku/code/ regex \b(?:[0-9][_0-9]*(?:\.[0-9][_0-9]*|(?:\.[0-9][_0-9]*)?e[\+\-][_0-9]+)|(?:0x[_0-9a-fA-F]+|0o[_0-7]+|0b[_01]+|[0-9][_0-9]*))\b 0:value

# commands

define-command -hidden raku-insert-on-new-line %~
    evaluate-commands -draft -itersel %=
        # copy # comments prefix and following white spaces
        try %{ execute-keys -draft <semicolon><c-s>k<a-x> s ^\h*\K#\h* <ret> y<c-o>P<esc> }
    =
~

define-command -hidden raku-indent-on-new-line %~
    evaluate-commands -draft -itersel %=
        # preserve previous line indent
        try %{ execute-keys -draft <semicolon>K<a-&> }
        # indent after lines ending with { or (
        try %[ execute-keys -draft k<a-x> <a-k> [{(]\h*$ <ret> j<a-gt> ]
        # cleanup trailing white spaces on the previous line
        try %{ execute-keys -draft k<a-x> s \h+$ <ret>d }
        # align to opening paren of previous line
        try %{ execute-keys -draft [( <a-k> \A\([^\n]+\n[^\n]*\n?\z <ret> s \A\(\h*.|.\z <ret> '<a-;>' & }
        # indent after a switch's case/default statements
        try %[ execute-keys -draft k<a-x> <a-k> ^\h*(case|default).*:$ <ret> j<a-gt> ]
        # indent after if|else|while|for
        try %[ execute-keys -draft <semicolon><a-F>)MB <a-k> \A(if|else|while|for)\h*\(.*\)\h*\n\h*\n?\z <ret> s \A|.\z <ret> 1<a-&>1<a-space><a-gt> ]
        # deindent closing brace(s) when after cursor
        try %[ execute-keys -draft <a-x> <a-k> ^\h*[})] <ret> gh / [})] <ret> m <a-S> 1<a-&> ]
    =
~

define-command -hidden raku-indent-on-opening-curly-brace %[
    # align indent with opening paren when { is entered on a new line after the closing paren
    try %[ execute-keys -draft -itersel h<a-F>)M <a-k> \A\(.*\)\h*\n\h*\{) <ret> s \A|.\z <ret> 1<a-&> ]
]

define-command -hidden raku-indent-on-closing-curly-brace %[
    # align to opening curly brace when alone on a line
    try %[ execute-keys -itersel -draft <a-h><a-k>^\h+\}$<ret>hms\A|.\z<ret>1<a-&> ]
]

§
