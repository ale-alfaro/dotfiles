## Getting Help in Vim

**Help Tags are located here**

```
$VIMRUNTIME/doc/tags
```

To access it in Neovim you can use an Ex cmd:

```
:e $VIMRUNTIME/doc/tags
```

## Writing Help in Vim

From the `*helphelp*`

```vimdoc
Writing help files					*help-writing*

For ease of use, a Vim help file for a plugin should follow the format of the
standard Vim help files, except for the first line.  If you are writing a new
help file it's best to copy one of the existing files and use it as a
template.

The first line in a help file should have the following format: >

	*plugin_name.txt*	{short description of the plugin}

The first field is a help tag where ":help plugin_name" will jump to.  The
remainder of the line, after a Tab, describes the plugin purpose in a short
way.  This will show up in the "LOCAL ADDITIONS" section of the main help
file.  Check there that it shows up properly: |local-additions|.

If you want to add a version number or last modification date, put it in the
second line, right aligned.

At the bottom of the help file, place a Vim modeline to set the 'textwidth'
and 'tabstop' options and the 'filetype' to "help".  Never set a global option
in such a modeline, that can have undesired consequences.


TAGS

To define a help tag, place the name between asterisks ("*tag-name*").  The
tag-name should be different from all the Vim help tag names and ideally
should begin with the name of the Vim plugin.  The tag name is usually right
aligned on a line.

When referring to an existing help tag and to create a hot-link, place the
name between two bars ("|") eg. |help-writing|.

When referring to a Vim option in the help file, place the option name between
two single quotes, eg. 'statusline'

When referring to any other technical term or symbol, such as a filename or
function parameter, surround it in backticks, eg. `~/.path/to/init.vim`. This
renders it as "inline" code (as opposed to a "codeblock" |help-codeblock|).


HIGHLIGHTING

To define a column heading, use a tilde character at the end of the line,
preceded by a space. This will highlight the column heading in a different
color.  E.g.

Column heading ~

To separate sections in a help file, place a series of '=' characters in a
line starting from the first column.  The section separator line is
highlighted differently.

							      *help-codeblock*
To quote a block of ex-commands verbatim, place a greater than (>) character
at the end of the line before the block and a less than (<) character as the
first non-blank on a line following the block.  Any line starting in column 1
also implicitly stops the block of ex-commands before it.  E.g. >
	function Example_Func()
	  echo "Example"
	endfunction
<
To enable syntax highlighting for a block of code, place a language name
annotation (e.g. "vim") after a greater than (>) character.  E.g. >vim
	function Example_Func()
	  echo "Example"
	endfunction
<
						*help-notation*
The following are highlighted differently in a Vim help file:
  - a special key name expressed either in <> notation as in <PageDown>, or
    as a Ctrl character as in CTRL-X
  - anything between {braces}, e.g. {lhs} and {rhs}

The word "Note", "Notes" and similar automagically receive distinctive
highlighting.  So do these:
	Todo	something to do
	Error	something wrong

You can find the details in $VIMRUNTIME/syntax/help.vim


FILETYPE COMPLETION					*ft-help-omni*

To get completion for help tags when writing a tag reference, you can use the
|i_CTRL-X_CTRL-O| command.


 `vim:tw=78:ts=8:noet:ft=help:norl:`
```

`api-ui-events  
api  
autocmd  
change  
channel  
cmdline  
credits  
deprecated  
dev  
dev_arch  
dev_style  
dev_test  
dev_theme  
dev_tools  
dev_vimpatch  
diagnostic  
diff  
digraph  
editing  
faq  
filetype  
fold  
ft_ada  
ft_hare  
ft_ps1  
ft_raku  
ft_rust  
ft_sql  
gui  
health  
help  
helphelp  
if_perl  
if_pyth  
if_ruby  
indent  
index  
insert  
intro  
job_control  
l10n-arabic  
l10n-hebrew  
l10n-russian  
l10n-vietnamese.txt  
lsp  
lua-bit  
lua-guide  
lua-plugin  
lua  
luaref  
luvref  
map  
mbyte  
message  
mlang  
motion  
news-0         .9  
news-0         .10.txt  
news-0         .11.txt  
news  
nvim  
options  
pack  
pattern  
pi_gzip  
pi_msgpack  
pi_paren  
pi_spec  
pi_tar  
pi_tutor  
pi_zip  
plugins  
provider  
quickfix  
quickref  
recover  
remote  
remote_plugin  
repeat  
rileft  
scroll  
sign  
spell  
starting  
support  
syntax  
tabpage  
tags  
tagsrch  
terminal  
tips  
treesitter  
tui  
uganda  
undo  
userfunc  
usr_01  
usr_02  
usr_03  
usr_04  
usr_05  
usr_06  
usr_07  
usr_08  
usr_09  
usr_10  
usr_11  
usr_12  
usr_20  
usr_21  
usr_22  
usr_23  
usr_24  
usr_25  
usr_26  
usr_27  
usr_28  
usr_29  
usr_30  
usr_31  
usr_32  
usr_40  
usr_41  
usr_42  
usr_43  
usr_44  
usr_45  
usr_toc  
various  
vi_diff  
vim_diff  
vimeval  
vimfn  
visual  
vvars  
windows`
