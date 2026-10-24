return {
    {
        prefix = 'techie',
        body = [=[[---
modified: ${CURRENT_YEAR}-${CURRENT_MONTH}-${CURRENT_DATE} ${CURRENT_HOUR}:${CURRENT_MINUTE}
created: ${CURRENT_YEAR}-${CURRENT_MONTH}-${CURRENT_DATE}
aliases:
  - ${1:${TM_FILENAME_BASE}}
type: ${2|permanent,reference,literature,fleeting,other|}
categories:
 - "[[${3:category]]" 
tags:
 - ${4:tags}
---

## $1

$0
]]=],
        desc = 'Frontmatter',
    },
    {
        prefix = 'tbl',
        body = [[
| ${1:Col1} | ${2:Col2} |
|-----------|-----------|
| ${3:Val1} | ${4:Val2} |
$0
]],
        desc = 'Markdown Table',
    },
    {
        prefix = 'blog',
        desc = 'new entry',
        body = [[---
title: ${1:${TM_FILENAME_BASE}}
created: ${CURRENT_YEAR}-${CURRENT_MONTH}-${CURRENT_DATE}
last: ${CURRENT_YEAR}-${CURRENT_MONTH}-${CURRENT_DATE}
publish: false
---

## $1

$0
    ]],
    },
}
