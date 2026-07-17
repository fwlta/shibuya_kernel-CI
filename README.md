# Shibuya Kernel

Custom Linux 5.15.202 kernel for the Motorola Edge 40 Pro (`rtwo`).

```text
5.15.xxx:shibuya:<hash>
```

The suffix identifies the exact kernel source commit used by each build.

## Variants

- KSU-Next
- ReSukiSU
- NoKSU

## Compatibility

- Motorola Edge 40 Pro (`rtwo`) only
- Android 13 through 16
- AOSP and LineageOS-based ROMs are recommended

## Downloads

This repository exists to run the Shibuya Kernel build workflows through GitHub Actions. Build artifacts and Releases are generated automatically by the CI.

> [!WARNING]
> An automated build is not a boot test. A Release may contain an untested kernel that does not boot or work correctly. Flashing anything published here is entirely at your own risk.

This repository does not provide flashing instructions or device support. The [Actions](https://github.com/fwlta/shibuya_kernel-CI/actions) page is the intended interface for running and inspecting builds.

## Source

- [Kernel source](https://github.com/fwlta/android_kernel_motorola_sm8550)
- [Automated builds](https://github.com/fwlta/shibuya_kernel-CI/actions)

## Credits

- Yuriko ([superuseryu](https://github.com/superuseryu)) for AnyKernel3 and project help
- KernelSU-Next and ReSukiSU contributors
