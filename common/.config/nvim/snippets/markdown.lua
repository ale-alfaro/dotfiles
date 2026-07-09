local fmt_tp = string.format(
  [[[---
modified: ${CURRENT_YEAR}-${CURRENT_MONTH}-${CURRENT_DATE} ${CURRENT_HOUR}:${CURRENT_MINUTE}
created: ${CURRENT_YEAR}-${CURRENT_MONTH}-${CURRENT_DATE}
aliases:
  - ${1:${TM_FILENAME_BASE}}
type: ${2|permanent,reference,literature,fleeting,other|}
categories:
 - %q
tags:
 - ${4:tags}
---

## $1

$0
]],
  '[[${3|embedded,lang,linux|}]]'
)
return {
  frontmatter = {
    prefix = 'fmt',
    body = vim
      .iter(vim.fn.split(fmt_tp, '\n', false))
      :map(function(l)
        l = vim.fn.trim(l)
        return l
      end)
      :totable(),
    desc = 'Frontmatter',
  },
  tbl = {
    prefix = 'tbl',
    body = [[
| ${1:Col1} | ${2:Col2} |
|-----------|-----------|
| ${3:Val1} | ${4:Val2} |
$0
]],
    desc = 'Markdown Table',
  },
}
