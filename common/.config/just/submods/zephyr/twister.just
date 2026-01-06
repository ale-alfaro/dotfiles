set unstable := true

# Test plan reporting:
#   Report the composed test plan details and exit (dry-run).
#
#   -E, --save-tests FILENAME
#                         Write a list of tests and platforms to be run to
#                         FILENAME file and stop execution. The resulting file
#                         will have the same content as 'testplan.json'.
#   --list-tests          List of all sub-test functions recursively found in
#                         all --testsuite-root arguments. The output is
#                         flattened and reports detailed sub-test names without
#                         their directories. Note: sub-test names can share the
#                         same test scenario identifier prefix
#                         (section.subsection) even if they are from different
#                         test projects.
#   --test-tree           Output the test plan in a tree form.
#   --list-tags           List all tags occurring in selected tests.

twister_verbose_flags := env('TWISTER_VERBOSE', '-v')
optional_flags := ' -W --no-detailed-test-id --report-dir'
default_flags := f" -i --clobber-output "
twister := which('west') + f" twister {{twister_verbose_flags}} {{default_flags}}"

[group('info')]
[no-cd]
test_info dir:
    {{ twister }} -T {{ dir }} --test-tree
    {{ twister }} -T {{ dir }} --list-tags

[group('run')]
[no-cd]
run test_root platform *args:
    @echo "Running twister test suite at {{ invocation_directory() }} and test_root {{ test_root }}"
    {{ f'{{twister}} --outdir {{test_root}}/twister' }} \
      -p {{ platform }} \
      -T {{ test_root }} \
      {{ args }}

[group('run')]
[no-cd]
run_scenario test_root platform scenario *args:
    {{ f'{{twister}} --outdir {{test_root}}/twister' }} \
      -p {{ platform }} \
      -T {{ test_root }} \
      -s {{ scenario }} \
      {{ args }}

[group('prep')]
[no-cd]
prep-test test_root board: (run board test_root "--prep-artifacts-for-testing")

# native_sim_west_flags := "-b native_sim -- -DCONFIG_UART_NATIVE_PTY_0_ON_STDINOUT=y"
# qemu_west_flags := "-b qemu_x86 -- -DQEMU_PIPE=qemu-fifo"

serial_port := env('SERIAL_PORT', '/dev/ttyACM1')
dut_board := env('BOARD', 'nrf54l15dk/nrf54l15/cpuapp')
hw_flags := f'--west-runner=nrfutil --west-flash=--skip-rebuild --enable-slow --device-testing --device-serial={{serial_port}} '

[group('run')]
[no-cd]
run_hw test_root *args: (run test_root dut_board hw_flags + args)

[group('run')]
[no-cd]
run_sim test_root *args: (run test_root "native_sim" args)

pytest_base_opts := " --strict-markers --strict-config -ra "
pytest_debug_opts := " -v -s --log-cli-level='DEBUG' "
pytest_zephyr_opts := " --twister-harness "
pytest_opts := pytest_base_opts + pytest_debug_opts + pytest_zephyr_opts
pytest := require('uvx') + " pytest"

_pytest_run *args:
    {{ pytest }} {{ pytest_base_opts }} {{ args }}

[group('pytest')]
[no-cd]
pytest_run platform build-dir *args:
    {{ pytest }} {{ pytest_opts }} {{ " --rootdir=pytest " + append(file_stem(build-dir), " --build-dir=") + " " + append(platform, " --device-type=") }} {{ args }}

[group('pytest')]
[no-cd]
pytest_run_hw build-dir *args: (pytest_run "hardware" build-dir args)
