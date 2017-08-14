# Helper scripts for manually converting options to Kconfig in U-Boot

This repo contains a bunch of semi-raw scripts I crafted in process
of converting `CONFIG_BOOTARGS` option to `Kconfig`. In simpler cases it is
enough to just run `tools/moveconfig.py` for automatic transition.

**WARNING**: those scripts must be used with caution, as sometimes they give
incorrect results (because of their simplicity).

## Other tools

In addition to those scripts, one can find useful my another tool called
[find-ifdefs](https://gitlab.com/joeskb7/find-ifdefs).

Also, to check the final value of config option, you can use hack patch from
Tom Rini [here](https://patchwork.ozlabs.org/patch/790476/).

## Manual converting flow (simplified)

1. Run `gen-configs.sh all`
2. Run `find-target.sh` for header from `include/configs/` you are interested in
3. Run `find-configs.sh` for found target
4. Fix found files from `configs/` and related header
5. Repeat above items for all headers you need to convert
6. `git commit` your patch
7. Run `gen-defconfigs.sh head` and replace configs/ with generated defconfigs

## Manual converting flow (detailed)

For example we want to migrate `CONFIG_USB_GADGET_VBUS_DRAW` option to Kconfig.

1. Add some option to corresponding Kconfig (`drivers/usb/gadget/Kconfig`)
2. Generate .config files from defconfig files:
```bash
$ ./gen-configs.sh
```
3. Find all headers with option of interest:
```bash
$ grep -sIrHn USB_GADGET_VBUS_DRAW include/configs/*
```
4. For each found header:
  4.1 `./find-target.sh am335x_evm.h`
  4.2 For each found target:
    4.2.1 `./find-configs.sh TARGET_AM335X_EVM`
    4.2.2 For each found config:
          Add corresponding config option to corresponding defconfig;
          e.g. add `CONFIG_USB_GADGET_VBUS_DRAW=2` to the end of
          `configs/am335x_boneblack_defconfig`, etc.
  4.3 Remove option from header
    4.3.1 Pay attention to `#ifdefs`
  4.4 Be sure to handle common header files properly (they are usually included
      in other files, but pay attention to `#ifdefs`)
5. For `sunxi-common.h` use next method:
```bash
$ grep-all configs_generated/ 'USB_MUSB_GADGET=y' 'SUNXI=y' | \
    sed 's/configs_generated/configs/g'
```
5. Once all options moved to defconfigs, recreate them using:
```bash
$ ./gen-defconfigs.sh
```
   to keep correct order of options.
  5.1 Explore changes using `kdiff3` (for 2 directories)
      (disable "Show Files only in A" or "... only in B" for convenience)
  5.2 Replace old defconfigs with new ones
6. Check everything using buildman tool
7. Send a patch

## Using buildman to check transition

To check if the option was converted correctly, it's very convenient to use
`tools/buildman` tool.

You can run it for some boards like this:
```bash
$ ./tools/buildman/buildman -b master --force-build -SCdvel board1 board2
```

where board1, board2 -- boards from `configs/` (without `_defconfig` suffix).

Or for the whole architecture:
```bash
$ ./tools/buildman/buildman -b master -T 2 --force-build -SCdvel arm
```

To check results, just run:
```bash
$ ./tools/buildman/buildman -b master -sSdBevK
```

## Authors

* **Sam Protsenko**

## License

This project is licensed under the GPLv2.
