#!/usr/bin/env bash
# Split shell-style words without expansion, command substitution, globbing, or eval.
# Results are returned in the global EXTRA_ARGS array. Empty quoted words survive.
parse_cmake_args() {
    local input="$1" state=plain word="" active=0 char next i
    EXTRA_ARGS=()
    for ((i=0; i<${#input}; i++)); do
        char="${input:i:1}"
        case "$state" in
            single)
                if [[ "$char" == "'" ]]; then state=plain; else word+="$char"; fi
                ;;
            double)
                case "$char" in
                    '"') state=plain ;;
                    '\')
                        ((i+=1))
                        if ((i >= ${#input})); then echo "[ERROR] Trailing escape in cmake-args" >&2; return 1; fi
                        next="${input:i:1}"
                        case "$next" in
                            '$'|'`'|'"'|'\') word+="$next" ;;
                            $'\n') ;;
                            *) word+="\\$next" ;;
                        esac
                        ;;
                    *) word+="$char" ;;
                esac
                ;;
            plain)
                case "$char" in
                    "'") state=single; active=1 ;;
                    '"') state=double; active=1 ;;
                    '\')
                        ((i+=1))
                        if ((i >= ${#input})); then echo "[ERROR] Trailing escape in cmake-args" >&2; return 1; fi
                        next="${input:i:1}"
                        if [[ "$next" != $'\n' ]]; then word+="$next"; active=1; fi
                        ;;
                    ' '|$'\t'|$'\n'|$'\r')
                        if ((active)); then EXTRA_ARGS+=("$word"); word=""; active=0; fi
                        ;;
                    *) word+="$char"; active=1 ;;
                esac
                ;;
        esac
    done
    if [[ "$state" != plain ]]; then echo "[ERROR] Unclosed quote in cmake-args" >&2; return 1; fi
    if ((active)); then EXTRA_ARGS+=("$word"); fi
    return 0
}
