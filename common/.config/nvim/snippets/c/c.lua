local hdr_tp = [[
/**
 * @attention
 * SIBEL INC ("SIBEL HEALTH") CONFIDENTIAL
 *
 * Copyright 2018-${TM_CURRENTYEAR} [Sibel Inc.],
 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * SIBEL INC. The intellectual and technical concepts contained herein are
 * proprietary to SIBEL INC and may be covered by U.S. and Foreign Patents,
 * patents in process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from SIBEL
 * INC. Access to the source code contained herein is hereby forbidden to anyone
 * except current SIBEL INC employees, managers or contractors who have executed
 * Confidentiality and Non-disclosure agreements explicitly covering such
 * access. The copyright notice above does not evidence any actual or intended
 * publication or disclosure of this source code, which includes information
 * that is confidential and/or proprietary, and is a trade secret of SIBEL INC.
 *
 * ANY REPRODUCTION, MODIFICATION, DISTRIBUTION, PUBLIC PERFORMANCE, OR PUBLIC
 * DISPLAY OF OR THROUGH USE OF THIS SOURCE CODE WITHOUT THE EXPRESS WRITTEN
 * CONSENT OF COMPANY IS STRICTLY PROHIBITED, AND IN VIOLATION OF APPLICABLE
 * LAWS AND INTERNATIONAL TREATIES. THE RECEIPT OR POSSESSION OF THIS SOURCE
 * CODE AND/OR RELATED INFORMATION DOES NOT CONVEY OR IMPLY ANY RIGHTS TO
 * REPRODUCE, DISCLOSE OR DISTRIBUTE ITS CONTENTS, OR TO MANUFACTURE, USE, OR
 * SELL ANYTHING THAT IT MAY DESCRIBE, IN WHOLE OR IN PART.
 */

/**
 *  @file ${TM_FILENAME_BASE}.h
 *  @brief This module does
 *
 *  This is the header file for the definition of ${TM_FILENAME_BASE}
 */
#ifndef ${HEADER_FILE_GUARD}
#define ${HEADER_FILE_GUARD}

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C"{
#endif


void ${TM_FILENAME_BASE}_init(void);

#ifdef __cplusplus
} // extern "C"
#endif

#endif /* ${HEADER_FILE_GUARD} */
]]

local src_tp = [[
/**
* @attention
* SIBEL INC ("SIBEL HEALTH") CONFIDENTIAL
*
* Copyright 2018-${CURRENT_YEAR} [Sibel Inc.], All Rights Reserved.
*
* NOTICE: All information contained herein is, and remains the property of SIBEL
* INC. The intellectual and technical concepts contained herein are proprietary
* to SIBEL INC and may be covered by U.S. and Foreign Patents, patents in
* process, and are protected by trade secret or copyright law. Dissemination of
* this information or reproduction of this material is strictly forbidden unless
* prior written permission is obtained from SIBEL INC. Access to the source code
* contained herein is hereby forbidden to anyone except current SIBEL INC
* employees, managers or contractors who have executed Confidentiality and
* Non-disclosure agreements explicitly covering such access.
* The copyright notice above does not evidence any actual or intended
* publication or disclosure of this source code, which includes information that
* is confidential and/or proprietary, and is a trade secret of SIBEL INC.
*
* ANY REPRODUCTION, MODIFICATION, DISTRIBUTION, PUBLIC PERFORMANCE, OR PUBLIC
* DISPLAY OF OR THROUGH USE OF THIS SOURCE CODE WITHOUT THE EXPRESS WRITTEN
* CONSENT OF COMPANY IS STRICTLY PROHIBITED, AND IN VIOLATION OF APPLICABLE
* LAWS AND INTERNATIONAL TREATIES. THE RECEIPT OR POSSESSION OF THIS SOURCE
* CODE AND/OR RELATED INFORMATION DOES NOT CONVEY OR IMPLY ANY RIGHTS TO
* REPRODUCE, DISCLOSE OR DISTRIBUTE ITS CONTENTS, OR TO MANUFACTURE, USE, OR
* SELL ANYTHING THAT IT MAY DESCRIBE, IN WHOLE OR IN PART.
*/

/**
*  @file ${TM_FILENAME_BASE}.c
*  @brief This is a source file
*/
#include <zephyr/kernel.h>
#include <zephyr/sys/util.h>
#include <zephyr/sys/_check.h>

#include "${TM_FILENAME_BASE}.h"

/**
* @brief This function is used to initialize the ${TM_FILENAME_BASE}
* @param a An argument
* @return Nothing
* @code
* 	${TM_FILENAME_BASE}_init();
* @endcode
*
* @see ${TM_FILENAME_BASE}_init
*/
void ${TM_FILENAME_BASE}_init(int a);

]]
return {
  src = {
    prefix = 'src',
    body = vim
      .iter(vim.fn.split(src_tp, '\n', false))
      :map(function(l)
        l = vim.fn.trim(l)
        return l
      end)
      :totable(),
    desc = 'C Source file',
  },
  hdr = {
    prefix = 'hdr',
    body = vim
      .iter(vim.fn.split(hdr_tp, '\n', false))
      :map(function(l)
        l = vim.fn.trim(l)
        return l
      end)
      :totable(),
    desc = 'C Header file',
  },
}
