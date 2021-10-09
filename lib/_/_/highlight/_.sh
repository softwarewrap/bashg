#!/bin/bash

+ %HELP()
{
   local (.)_Synopsis='Highlight text according to markup'
   :help: --set "$(.)_Synopsis" <<EOF
OPTIONS:
   -o|--out          ^Send output to the console instead of the log

   --render <mode>   ^Render text according to <mode>: <b>color</b>, <b>plain</b>, <b>tags</b> [default: <b>color</b>]
   --no-autobold     ^Do not automatically add bold to color markup
   --no-idiom        ^Do not automatically apply idiom replacements
   --pager <cmd>     ^Specify a pager [default: none]

   --quiet           ^Discard input and return
   --passthru        ^Emit input as is and return
   --template <t>    ^Specify an alternative function to process text

DESCRIPTION:
   Highlight text according to markup and emit according to the options provided.

   The --out option is used to redirect output to the console instead of the log file.

   The default --render <mode> is <b>color</b>. The <b>plain</b> rendering mode result in all highlighting
   being stripped from the text. The <b>tags</b> rendering mode can be used to show the final results of
   parsing, but this mode is typically used only when designing a template.

   Color markup is automatically emboldened unless the --no-autobold option is used.
   Idiom replacement is automatically done unless the --no-idiom option is used.

   The --pager option is used to specify whether the emitted text should be piped
   to the command <cmd>. The <B>$__ help</B> command uses the pager <b>less</b>.

   The --quiet option immediately returns without emitting any text. This is typically used
   if this function is being called from a function that is supressing output and wants this
   function to do the same.

   The --passthru option emits input exactly as it is received. This can be useful for where
   downstream functions need to obtain the unmodified input.

   The --template option is reserved for those wishing to implement and use an alternative
   highlighting function <t>. That function must exist for this option to be used.

   Note: For markup with opening and closing tags, the opening tag may be on
   a different line than the closing tag. Nesting of tags is permitted.

   The following markup is supported:

   COLORS:^<K
      \<R>...\</R>   Red               For color tags, the closing tag
      \<G>...\</G>   Green             is required and cannot be omitted.
      \<B>...\</B>   Blue
      \<C>...\</C>   Cyan
      \<M>...\</M>   Magenta
      \<Y>...\</Y>   Yellow
      \<K>...\</K>   Black
      \<W>...\</W>   White

   MODES:^<K
      \<b>...\</b>   Bold              For mode tags, the closing tag
      \<u>...\</r>   Reverse           is required and cannot be omitted.
      \<u>...\</u>   Underline

   SHORTCUTS:^<K
      ... \^<X      Apply color X before the shortcut to the beginning of line
      ... \^        Shorter shortcut for \^<B - Blue before
      \^>X ...      Apply color X after the shortcut to the end of line
      \^^ ...       Shorter shortcut for \^>B - Blue after

      \<h1>...\</h1> Bold Red          For heading tags, the closing tag is optional.
      \<h2>...\</h2> Bold Blue         If the closing tag is omitted, then
      \<h3>...\</h3> Bold Underline    the highlighting is performed
      \<h4>...\</h4> Bold              until the end of line.

      \<hr>         Draw a horizontal rule comprised of = characters

      Longer shortcuts are processed before shorter forms. For example \^^>G is green right, then blue left.

   IDIOM REPLACEMENTS:^<K
      \--word       \<b>\--word\</b>
      \Note:        \<b>\Note:\</b> irrespective of case, anywhere
      \Notes:       \<b>\Notes:\</b> irrespective of case, anywhere
      LEAD IN:     \<b>LEAD IN:\</b> for upper-case words, numbers, '-', spaces, and '_', beginning in column 1

   ESCAPES:^<K
      \\markup      markup
                   Placing a backslash in front of markup disables markup interpretation.
                   The emitted text does not include the backslash.

EXAMPLES:
   $__ :highlight:%TEST --passthru       ^Show the raw text including markup
   $__ :highlight:%TEST --no-autobold    ^Highlight with normal colors and idiom replacement
   $__ :highlight:%TEST                  ^Highlight with bold colors and idiom replacement
   $__ :highlight:%TEST --pager less     ^Send the output to the <B>less</B> command
   $__ :highlight:%TEST --no-idiom       ^Highlight with bold colors and no idiom replacement
   $__ :highlight:%TEST --render plain   ^Do not highlight: Remove all markup
EOF
}

+ %STARTUP()
{
   local -g _COLS
   :tput:set _COLS cols
}

+ ()
{
   local (.)_Options
   (.)_Options=$(getopt -o 'o' -l 'out,render:,no-autobold,no-idiom,pager:,quiet,passthru,template:' -n "${FUNCNAME[0]}" -- "$@") || return
   eval set -- "$(.)_Options"

   local (-)_Render='color'
   local (-)_AutoBold=true
   local (-)_ReplaceIdioms=true
   local -a (-)_MoreCommand=( 'cat' )

   local (.)_Quiet=false
   local (.)_Passthru=false
   local (.)_Template="(-):Man"
   local (.)_Stdout=false

   while true ; do
      case "$1" in
      -o|--out)      (.)_Stdout=true; shift;;

      --render)      (-)_Render="$2"; shift 2;;
      --no-autobold) (-)_AutoBold=false; shift;;
      --no-idiom)    (-)_ReplaceIdioms=false; shift;;
      --pager)       (-)_MoreCommand=( $2 ); shift 2;;   # Word splitting due to unquoted $2 is intentional

      --quiet)       (.)_Quiet=true; shift;;
      --passthru)    (.)_Passthru=true; shift;;
      --template)    (.)_Template="$2"; shift 2;;
      --)            shift; break;;
      *)             break;;
      esac
   done

   # If there is no stdin, then assume that this function is being passed command-line strings
   if ! :test:is_pipe; then
      exec <<<"$@"
   fi

   if $(.)_Quiet; then
      # No output requested
      return 0
   fi

   if $(.)_Passthru; then
      # Emit unmodified input and return
      cat
      return
   fi

   # If there are no colors available, then render as plain text
   if ! ${(+:launcher)_Config[HasColor]}; then
      (-)_Render='plain'
   fi

   # Call the template
   if :test:has_func "$(.)_Template"; then
      if $(.)_Stdout; then
         "$(.)_Template" >&4
      else
         "$(.)_Template"
      fi
   else
      :highlight: <<<"<R>[highlight]</R> Unrecognized template: <B>$(.)_Template</B>"
      return 1
   fi
}

# Highlight man template
- Man()
{
   ### DEFINITIONS
   # Markers
   local B=$'\x01'                                       # Begin color marker
   local M=$'\x02'                                       # Middle color marker
   local E=$'\x03'                                       # End color marker

   local b=$'\x04'                                       # Begin mode marker
   local e=$'\x05'                                       # End mode marker

   local s=$'\x10'                                       # Standout begin marker
   local n=$'\x11'                                       # Normal (Standout end) marker

   local T=$'\x12'                                       # Tag escapes marker
   local N=$'\x13'                                       # Newline

   # Convenience/Commonly-used
   local o="[^$s$n]*"                                    # Regex for string not containing standout
   local L="\(^\|\($N\)\([^$N]*[^\]\)\)"                 # Leading to desired match: use \1, do not use \2 and \3
   local F="\([^$N]*\)"                                  # Following desired match preceded by anchor: use \1

   # Assume that colors and modes are not available
   local _RED= _GREEN= _BLUE= _CYAN= _MAGENTA= _YELLOW= _BLACK= _WHITE=
   local _BOLD= _BOLD_OFF= _REVERSE= _REVERSE_OFF= _UNDERLINE= _UNDERLINE_OFF= _RESET=
   local _HRULE='====================================='  # Assume width of 37 for dumb terminals

   if ${(+:launcher)_Config[HasColor]} && tput setaf 1 &>/dev/null; then
      # Colors
      :tput:set _RED setaf 1
      :tput:set _RED setaf 1                             # R   Red
      :tput:set _GREEN setaf 2                           # G   Green
      :tput:set _BLUE setaf 4                            # B   Blue
      :tput:set _CYAN setaf 6                            # C   Cyan
      :tput:set _MAGENTA setaf 5                         # M   Magenta
      :tput:set _YELLOW setaf 3                          # Y   Yellow
      :tput:set _BLACK setaf 0                           # K   Black
      :tput:set _WHITE setaf 7                           # W   White

      # Modes
      # Some are not available via tput, see: https://en.wikipedia.org/wiki/ANSI_escape_code#CSI_codes
      :tput:set _BOLD bold                               # Bold ON
      :tput:set _BOLD_OFF -- $'\e[22m'                   # Bold OFF, see above link
      :tput:set _REVERSE smso                            # Reverse ON
      :tput:set _REVERSE_OFF rmso                        # Reverse OFF
      :tput:set _UNDERLINE smul                          # Underline ON
      :tput:set _UNDERLINE_OFF rmul                      # Underline OFF
      :tput:set _RESET sgr0                              # Reset all colors and modes

      _HRULE="$( printf '%*s' $_COLS | tr ' ' '=' )"
   fi
   ###

   ### RENDERING
   # Rendering Colors
   local -a RenderColors=(
      "s|${B}R|$_RED|g"                                  # R   Red
      "s|${B}G|$_GREEN|g"                                # G   Green
      "s|${B}B|$_BLUE|g"                                 # B   Blue
      "s|${B}C|$_CYAN|g"                                 # C   Cyan
      "s|${B}M|$_MAGENTA|g"                              # M   Magenta
      "s|${B}Y|$_YELLOW|g"                               # Y   Yellow
      "s|${B}K|$_BLACK|g"                                # K   Black
      "s|${B}W|$_WHITE|g"                                # W   White
      "s|[RGBCMYKW]$E|$_BLACK|g"                         # End and reset back to black
   )

   local -a RenderColorsAsTags=(
      "s|${B}R|$_BOLD$_RED{R$_RESET|g"                   # R   as {R
      "s|${B}G|$_BOLD$_RED{G$_RESET|g"                   # G   as {G
      "s|${B}B|$_BOLD$_RED{B$_RESET|g"                   # B   as {B
      "s|${B}C|$_BOLD$_RED{C$_RESET|g"                   # C   as {C
      "s|${B}M|$_BOLD$_RED{M$_RESET|g"                   # M   as {M
      "s|${B}Y|$_BOLD$_RED{Y$_RESET|g"                   # Y   as {Y
      "s|${B}K|$_BOLD$_RED{K$_RESET|g"                   # K   as {K
      "s|${B}W|$_BOLD$_RED{W$_RESET|g"                   # W   as {W
      "s|\([RGBCMYKW]\)$E|$_BOLD$_RED\1$_RESET}|g"       # End as X} for color X
   )

   local -a RenderColorsAsNoColor=(
      "s|${B}[RGBCMYKW]||g"                              # Remove color begin marker
      "s|[RGBCMYKW]$E||g"                                # Remove color end marker
   )

   # Rendering Modes
   local -a RenderModes=(
      "s|$s$n||g"                                        # Remove empty BOLD ON/OFF
      "s|$s|$_BOLD|g"                                    # Render standout as Bold
      "s|${b}b|$_BOLD|g"                                 # Render {b as Bold where { is the begin mode marker
      "s|${b}r|$_REVERSE|g"                              # Render {r as Reverse where { is the begin mode marker
      "s|${b}u|$_UNDERLINE|g"                            # Render {u as Underline where { is the begin mode marker

      "s|$n|$_BOLD_OFF|g"                                # Render normal as Bold OFF
      "s|b$e|$_BOLD_OFF|g"                               # Render b} as Bold OFF where } is the end mode marker
      "s|r$e|$_REVERSE_OFF|g"                            # Render r} as Reverse OFF where } is the end mode marker
      "s|u$e|$_UNDERLINE_OFF|g"                          # Render u} as Underline OFF where } is the end mode marker
   )

   local -a RenderModesAsTags=(
      "s|$s$n||g"                                        # Remove empty BOLD ON/OFF
      "s|$s|$_BLUE$_BOLD<b$_RESET|g"                     # Render as <b for standout
      "s|$b\([bru]\)|$_BLUE$_BOLD<\1$_RESET|g"           # Render as <X for begin mode X
      "s|\([bru]\)$e|$_BLUE$_BOLD\1>$_RESET|g"           # Render as X> for end mode X
      "s|$n|$_BLUE${_BOLD}b>$_RESET|g"                   # Render as b> for standend
   )

   local -a RenderModesAsNoColor=(
      "s|$s$n||g"                                        # Remove empty BOLD ON/OFF
      "s|$s||g"                                          # Remove standout
      "s|$b\([bru]\)||g"                                 # Remove begin mode
      "s|\([bru]\)$e||g"                                 # Remove end mode
      "s|$n||g"                                          # Remove standend
   )

   # Rendering Escapes
   local -a RenderEscapes=(
      "s|${T}rl\(.\)$T|^<\1|g"                           # Render \^<X for color X as ^<C
      "s|${T}rr\(.\)$T|^>\1|g"                           # Render \^>X for color X as ^>C
      "s|${T}cbr$T|^^|g"                                 # Render \^^ as ^^
      "s|${T}cbl$T|^|g"                                  # Render \^ as ^
      "s|${T}g\([^$T]*\)$T|<$_UNDERLINE\1$_UNDERLINE_OFF>|g"   # Render \<tag> as <tag> with tag underlined
      "s|${T}s\(.\)$T|\\\\\1|g"                          # Render \s for string char s as \s
      "s|${T}opt\([^$T]*\)$T|--\1|g"                     # Render \--word as --word
      "s|${T}lead\([^$T]*\)$T|\1|g"                      # Render \LEAD IN: as LEAD IN:
   )

   local -a RenderEscapesAsNoColor=(
      "s|${T}rl\(.\)$T|^<\1|g"                           # Render \^<X for color X as ^<C
      "s|${T}rr\(.\)$T|^>\1|g"                           # Render \^>X for color X as ^>C
      "s|${T}cbr$T|^^|g"                                 # Render \^^ as ^^
      "s|${T}cbl$T|^|g"                                  # Render \^ as ^
      "s|${T}g\([^$T]*\)$T|<\1>|g"                       # Render \<tag> as <tag>
      "s|${T}s\(.\)$T|\\\\\1|g"                          # Render \s for string char s as \s
      "s|${T}opt\([^$T]*\)$T|--\1|g"                     # Render \--word as --word
      "s|${T}lead\([^$T]*\)$T|\1|g"                      # Render \LEAD IN: as LEAD IN:
   )
   ###

   # Prior to normalization, replace shortcut idioms with the long-form equivalents
   local -a IdiomReplacement=(
      # Do First: Change encoding for escaped sequences to make substitutions later easier
      "s|\\\\^<\([RGBCMYKWbru]\)|${T}rl\1$T|g"                 # Escape \^<X for color X with tag rl (render left)
      "s|\\\\^>\([RGBCMYKWbru]\)|${T}rr\1$T|g"                 # Escape \^<X for color X with tag rr (render right)
      "s|\\\\^^|${T}cbr$T|g"                                   # Escape \^^ with Tag cbr (carat color blue to the right)
      "s|\\\\^|${T}cbl$T|g"                                    # Escape \^ with Tag cbl (carat color blue to the left)
      "s|\\\\<\(/\{0,1\}[a-zA-Z_][a-zA-Z0-9_]*\)>|${T}g\1$T|g" # Escape \<tag> with Tag t (general word tag)

      # Do Second: Preserve special escapes given as \\\s and \t and \n
      "s|\\\\\\\\\([a-z]\)|${T}s\1$T|g"                  # Escape \s for string char s with marker Tag s (string char)

      # Do Third: Convert tab and newline references
      "s|\\\\t|\t|g"                                     # Render escaped tab as tab
      "s|\\\\n|$N|g"                                     # Render escaped newline as newline

      # The = is used as a delimiter as | is used for group alternation \(...\|...\) in some sed constructs below
      "s=$L^<\([RGBCMYKWbru]\)=\2<\4>\3</\4>=g"          # ^<X for color X Before is specified color or mode
      "s=$L^>\([RGBCMYKWbru]\)$F=\2\3<\4>\5</\4>=g"      # ^>X for color X After is specified color or mode

      # Horizontal rule
      "s/\s*<hr>\s*/<hr>/g"                              # Remove spaces before/after a <hr>

      ":before_hrule"                                    # Normalize: ... <hr> to: ...\n <hr>
      "s/\(^\|$N\)\([^$N]\+\)<hr>/\1\2$N<hr>/g"
      "t before_hrule"

      ":after_hrule"                                     # Normalize: <hr> ... to: <hr> \n ...
      "s/\(^\|$N\)<hr>\([^$N]\+\)/\1<hr>$N\2/g"
      "t after_hrule"

      "s/\(^\|$N\)<hr>/\1$_HRULE/g"                      # Apply <hr> conversion

      # Headings
      "s=<h1>$F</h1>=<b><R>\U\1\E</R></b>=g"             # h1 red uppercased, long form
      "s=<h1>$F=<b><R>\U\1\E</R></b>=g"                  # h1 red uppercased, short form
      "s=<h2>$F</h2>=<b><B>\1</B></b>=g"                 # h2 blue, long form
      "s=<h2>$F=<b><B>\1</B></b>=g"                      # h2 blue, short form
      "s=<h3>$F</h3>=<b><u>\1</u></b>=g"                 # h3 green, long form
      "s=<h3>$F=<b><u>\1</u></b>=g"                      # h3 green, short form
      "s=<h4>$F</h4>=<b>\1</b>=g"                        # h4 green, long form
      "s=<h4>$F=<b>\1</b>=g"                             # h4 green, short form

      "s=$L^^$F=\2\3<B>\4</B>=g"                         # ^^  After is blue
      "s=$L^=\2<B>\3</B>=g"                              # ^   Before is blue
   )

   # Replacement Idioms
   if $(-)_ReplaceIdioms; then
      IdiomReplacement+=(
         # Auto-bold options beginning with --
         "s=\\\\--\([a-zA-Z0-9-]*\)=${T}opt\1$T=g"
         "s=--[a-zA-Z0-9-]*=<b>&</b>=g"

         # Auto-bolding of leading notes: Note: is bold, NOTE: is red/bold
         "s=\(^\|[^\\]\)\([nN][oO][tT][eE][sS]\{0,1\}:\)=\1<b>\2</b>=g"
         "s=\\\\\([nN][oO][tT][eE][sS]\{0,1\}:\)=\1=g"

         # Auto-bolding of uppercase words beginning in column 1
         "s=\(^\|$N\)\\\\\([0-9.]\+\s*\)\?\([A-Z0-9_][-A-Z0-9_ ]*:\)=\1${T}lead\2\3$T=g"
         "s=\(^\|$N\)\([0-9.]\+\s*\)\?\([A-Z0-9_][-A-Z0-9_ ]*:\)=\1<b>\2\3</b>=g"
      )
   fi

   # Normalization: Replace idioms with marker-encoded equivalents
   local -a Normalization=(
      # Mode Normalization
      "s|<\([bru]\)>|$b\1|g"                             # Begin mode
      "s|</\([bru]\)>|\1$e|g"                            # End mode

      # Color Normalization
      "s|<\([RGBCMYKW]\)>|$B\1|g"                        # Begin color
      "s|</\([RGBCMYKW]\)>|\1$E|g"                       # End color

      # Deprecated Color Normalization (no longer used in any code, but kept here for backward compatibility)
      "s|<red>|${B}R|g"       "s|</red>|R$E|g"
      "s|<green>|${B}G|g"     "s|</green>|G$E|g"
      "s|<blue>|${B}B|g"      "s|</blue>|B$E|g"
      "s|<cyan>|${B}C|g"      "s|</cyan>|C$E|g"
      "s|<magenta>|${B}M|g"   "s|</magenta>|M$E|g"
      "s|<yellow>|${B}Y|g"    "s|</yellow>|Y$E|g"
      "s|<black>|${B}K|g"     "s|</black>|K$E|g"

      # Automatic underlining for <variable> words
      "s=\(^\|[^\\]\)<\([a-zA-Z0-9_-]\+\)>=\1<${b}u\2u$e>=g"
      "s|\\\\<\([a-zA-Z0-9_-]\+\)>|<\1>|g"               # Remove the escape
   )

   local -a ColorFlattening=(
      # Nested Replacement of Colors
      #  {   R    w         {  G     w         G }  w         R }|{ R w R : G w G : R w R }
      #      1    2            3     4              5
      ":colors"
      "s|$B\(.\)\([^$B$E]*\)$B\(.\)\([^$B$E]*\).$E\([^$B$E]*\).$E|$B\1\2\1$M\3\4\3$M\1\5\1$E|g"
      "t colors"
      "s|$M|$E$B|g"                                      # Remove the nesting middle splits

      # Normalize bold sequences for easier handling
      "s|${b}b|$s|g"                                     # Convert to short form for standout
      "s|b$e|$n|g"                                       # Convert to short form for normal

      # Remove Inner Bold Pairs
      # <b {X <b b> <b b> >b X} to: <b {X >b X}
      ":removecolorboldpairs"
      "s|\($B.[^$E$s]*\)$s\([^$E$n]*\)$n|\1\2|g"
      "t removecolorboldpairs"

      # If there is an End Bold inside a color block, then move it to before the color block
      # <b {X >b X} to:  <b b> {X X}
      "s|\($B.[^$E$n]*\)\($n\)|\2\1|g"

      # Remove any remaining bold markers inside a color block
      ":removeinnerbold"
      "s|\($B.[^$s$n$E]*\)[$s$n]\([^$E]*.$E\)|\1\2|g"
      "t removeinnerbold"
   )

   # If the ColorType is bold, then add bold to all color markers
   if $(-)_AutoBold; then
      ColorFlattening+=(
      # Replace color markers with bold surround
      # {X X} to <b {X X} b>
      "s|$B[^$E]*$E|$s&$n|g"
      )
   fi

   ColorFlattening+=(
      # Remove unnecessary End Bold/Begin Bold sequences
      # b> <b sequences are removed
      "s|$s$n||g"
      "s|$n$s||g"

      # Remove nested bold markers
      # <b <b b> b> to: <b b>
      ":removenestedbold"
      "s|\($s[^$s$n]*\)$s\([^$s$n]*\)$n\([^$s$n]*$n\)|\1\2\3|g"
      "t removenestedbold"
   )

   ### RULES CREATION
   # Start with rules that are applied irrespective of the rendering mode
   local -a Rules=(
      "${IdiomReplacement[@]}"
      "${Normalization[@]}"
      "${ColorFlattening[@]}"
   )

   # Add rules for a specific rendering mode
   case "$(-)_Render" in
   no-color|plain)
      # Remove Markup
      Rules+=(
         "${RenderEscapesAsNoColor[@]}"
         "${RenderColorsAsNoColor[@]}"
         "${RenderModesAsNoColor[@]}"
      )
      ;;
   tags)
      # Render Markup with a Compact and Colored Notation
      Rules+=(
         "${RenderEscapes[@]}"
         "${RenderColorsAsTags[@]}"
         "${RenderModesAsTags[@]}"
      )
      ;;
   color|*)
      # Render Markup with Default Appearance
      Rules+=(
         "${RenderEscapes[@]}"
         "${RenderColors[@]}"
         "${RenderModes[@]}"
      )
      ;;
   esac

   local I
   tr '\n' "$N" |
   expand |
   LC_ALL=C sed "$( printf '%s\n' "${Rules[@]}" )" |
   tr "$N" '\n' |
   "${(-)_MoreCommand[@]}"
}

+ %TEST()
{
   local -a Tests=(
      "normal <R>red <G>green <B>blue</B> green</G> red</R> normal"
      "normal <r><R>red <G>green <B>blue</B></r> green</G> red</R> normal"
      "normal <u><R>red <G>green <B>blue</B></u> green</G> red</R> normal"
      "normal <C>cyan <M>magenta <Y>yellow <K>black</K> yellow</Y> magenta</M> cyan</C> normal"
      "normal <r><C>cyan <M>magenta <Y>yellow <K>black</K></r> yellow</Y> magenta</M> cyan</C> normal"
      "normal <u><C>cyan <M>magenta <Y>yellow <K>black</K></u> yellow</Y> magenta</M> cyan</C> normal"

      "\nRed to marker^<R, but not after"
      "Green to marker^<G, but not after"
      "Blue to marker^<B, but not after"
      "Cyan to marker^<C, but not after"
      "Magenta to marker^<M, but not after"
      "Yellow to marker^<Y, but not after"
      "Black to marker^<K, but not after"
      "Shortcut blue to marker^, but not after"
      "Bold to marker^<b, but not after"
      "Reverse to marker^<r, but not after"
      "Underscore to marker^<u, but not after"

      "\nNothing before,^>R but Red to end of line"
      "Nothing before, ^>Gbut Green to end of line"
      "Nothing before, ^>Bbut Blue to end of line"
      "Nothing before, ^>Cbut Cyan to end of line"
      "Nothing before, ^>Mbut Magenta to end of line"
      "Nothing before, ^>Ybut Yellow to end of line"
      "Nothing before, ^>Kbut Black to end of line"
      "Nothing before, ^^but blue to end of line"
      "Nothing before, ^>bbut bold to end of line"
      "Nothing before, ^>rbut reverse to end of line"
      "Nothing before, ^>ubut underscore to end of line"

      "\nESCAPES:"
      "Escape before marker \^<b \^<r \^<u \^<R \^<G \^<B \^<C \^<M \^<Y \^<K renders without escape"
      "Escape after marker \^>b \^>r \^>u \^>R \^>G \^>B \^>C \^>M \^>Y \^>K renders without escape"
      "Escape after \^^ renders without escape"
      "Escape before \^ renders without escape"
      "normal \<C>cyan \<M>magenta \<Y>yellow \<K>black\</K> yellow\</Y> magenta\</M> cyan\</C> normal"
      "normal \<r>\<blue>blue \<red>red \<green>green\</green>\</r> red\</red> blue\</blue> normal"
      "normal \<u>\<blue>blue \<red>red \<green>green\</green>\</u> red\</red> blue\</blue> normal"
      "This has \\\n\\\n newline escapes and \\\t\\\t tab escapes"

      "\n<hr>"

      "\n<h1>This is a h1 heading</h1>"
      "<h1>This is a h1 heading without an explicit close"

      "<h2>This is a h2 heading</h2>"
      "<h2>This is a h2 heading without an explicit close"

      "<h3>This is a h3 heading</h3>"
      "<h3>This is a h3 heading without an explicit close"

      "<h4>This is a h4 heading</h4>"
      "<h4>This is a h4 heading without an explicit close"

      "\n<r><G>[PASS]</G></r> <r><R>[FAIL]</R></r> <r><Y>[ALERT]</Y></r>"

      "\nOPTIONS: automatic emboldening"
      "Note: Automatic emboldening of notes"
      "   Notes: including both <B>singular</B> and <G>plural</G> with case conversion to 'Note[s]:'"
      "   but only if the Note is followed by a colon. NOTE: it is."
      "--automatic-boldening-of-long-options but --not of -short options"

      "\nUse <variable> and mode <mode-number> for <9> times"
      "<variable> at the beginning, <middle>, and <end>"
      "\<variable> with escapes at the beginning, \<middle>, and \<end>"
      "A \<Y> variable that is otherwise markup is underlined when escaped"

      "\n<R>Multiline</R> <b>Beginning here"
      "and extending <R>across <u>multiple"
      "lines <b>with bold text</b> and </u>still</R> going"
      "until the end</b> at which point"
      "the <R>highlighting</R> is off"
   )

   printf '%s\n' "${Tests[@]}" | (+): "$@"
}
