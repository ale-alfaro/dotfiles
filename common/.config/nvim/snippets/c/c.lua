return {
  {
    prefix = 'inc',
    body = [=[
/**
 * Copyright (c) 2026 Sibel Health
 *
 * SPDX-License-Identifier:
 *
 * @brief ${1:my_module}
 */

#include <zephyr/kernel.h>
#include <zephyr/zbus/zbus.h>

    /* Register log module */
#include <zephyr/logging/log.h>
LOG_MODULE_REGISTER($1);
]=],
    desc = 'Includes',
  },
  {
    prefix = 'hdr',
    body = [[

/*
 * Copyright (c) 2026 Sibel Inc.
 * SPDX-License-Identifier: LicenseRef-Sibel-Confidential
 */
#ifndef ${HEADER_FILE_GUARD}
#define ${HEADER_FILE_GUARD}

#include <zephyr/kernel.h>
#include ${1:<zephyr/sys/util.h>} 

#ifdef __cplusplus
extern "C"{
#endif

${0}

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif /* ${HEADER_FILE_GUARD} */]],
    desc = 'Zephyr Header file',
  },
  {
    prefix = 'init',
    body = [[
static int $1_init(void)
{
  int err;

  LOG_DBG("$1_init");

  return 0;
}

/* Initialize module at SYS_INIT() */
SYS_INIT($1_init, APPLICATION, CONFIG_APPLICATION_INIT_PRIORITY);
]],
  },
  {
    prefix = 'thr',
    body = [[
static void $1_thread(void)
{
	int err;
	while (true) {
	}
}

K_THREAD_DEFINE($1_tid, CONFIG_APP_$2_THREAD_STACK_SIZE,
		$1_thread, NULL, NULL, NULL,
		K_LOWEST_APPLICATION_THREAD_PRIO, 0, 0);
]],
  },
}
