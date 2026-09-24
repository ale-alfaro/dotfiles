# Set up

## First: find out how this workspace is set up

Do not assume. Establish these before writing anything:

```bash
echo "$BSIM_OUT_PATH" "$BSIM_COMPONENTS_PATH"   # both must be set
ls "$BSIM_OUT_PATH/bin/bs_2G4_phy_v1"           # is the simulator built?
west list | grep -iE 'bsim|babblesim'           # are the components cloned?
fd -t f 'compile.sh' tests/bsim                 # which build path is in use
```

- **Not set / not cloned.** The babblesim projects usually sit in a west group
  the Zephyr manifest disables (`group-filter: [-babblesim, ...]`). Enable it
  with `west config manifest.group-filter +babblesim` plus `west update` — and
  the project names must also appear in any `name-allowlist` your manifest as below
  uses, or the group filter has nothing to switch on. Do not run `west update`
  without the user's say-so.

```yaml
projects:
  - name: sdk-zephyr
    path: zephyr
    remote: ncs
    revision: ncs-v3.4.0
    import:
      path-prefix: external
      # By using name-allowlist we can clone only the modules that are
      # strictly needed by the application.
      name-allowlist:
        - babblesim_base
        - babblesim_ext_2G4_device_burst_interferer
        - babblesim_ext_2G4_device_playback
        - babblesim_ext_2G4_libPhyComv1
        - babblesim_ext_2G4_modem_BLE_simple
        - babblesim_ext_2G4_channel_NtNcable
        - babblesim_ext_2G4_phy_v1
        - babblesim_ext_libCryptov1
        - babblesim_ext_2G4_modem_magic
        - bsim
        - ...
```

- **Cloned but no `bin/`.** `make -C "$BSIM_OUT_PATH" everything -j"$(nproc)"`.
  It builds 32-bit, so a bare CI runner also needs `gcc-multilib`.
