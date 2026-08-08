return {
  {
    prefix = 'inc',
    body = [[#include <zephyr/kernel.h>
#include <zephyr/sys/util.h>

$0

#include <zephyr/logging/log.h>
LOG_MODULE_REGISTER(${1:module_str}, CONFIG_${2:MODULE}_LOG_LEVEL);
]],
    desc = 'Includes',
  },
  {
    prefix = 'hdr',
    body = [[
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

#endif /* ${HEADER_FILE_GUARD} */]],
    desc = 'C Header file',
  },
  {
    prefix = 'logr',
    body = [[#include <zephyr/logging/log.h>
LOG_MODULE_REGISTER(${1:module_str}, CONFIG_${2:MODULE}_LOG_LEVEL);]],
    desc = 'Register log module',
  },
  {
    prefix = 'logd',
    body = [[#include <zephyr/logging/log.h>
LOG_MODULE_DECLARE(${1:module_str});]],
    desc = 'Register log module',
  },
}
