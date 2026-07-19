# shibuya kernel ci

automated builds for shibuya kernel on motorola rtwo.

## device

- codename: `rtwo`
- platform: qualcomm sm8550 / snapdragon 8 gen 2
- kernel version: 5.15.202
- source branch: `lineage-23.2`

## configuration

- zyc clang 23
- thinlto
- localversion: `5.15.202:shibuya-purity/<commit>`
- anykernel3 packages

## variants

- kernelsu-next
- kernelsu-next with susfs
- resukisu
- resukisu with susfs
- noksu

builds can be packaged separately or in a single aio zip.

## releases

stable builds are published as regular github releases. testing builds are published as prereleases.

the actions page can be used to select the variant, package format, and build type.

## compatibility

this ci targets motorola `rtwo`. rom and root integration can vary between builds.

the kernel image does not replace vendor modules shipped by the installed rom.

## repositories

- source: https://github.com/fwlta/android_kernel_motorola_sm8550
- ci: https://github.com/fwlta/shibuya_kernel-CI/actions

## warning

automated builds are not boot-tested. keep a known-good boot image before flashing a new build.
