### AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers

### AnyKernel setup
properties() { '
kernel.string=Shibuya Kernel for Motorola rtwo
do.devicecheck=0
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=rtwo
supported.versions=13-16
supported.patchlevels=
supported.vendorpatchlevels=
'; } # end properties

### AnyKernel install
boot_attributes() {
set_perm_recursive 0 0 755 644 $RAMDISK/*;
set_perm_recursive 0 0 750 750 $RAMDISK/init* $RAMDISK/sbin;
} # end attributes

BLOCK=boot;
IS_SLOT_DEVICE=auto;
RAMDISK_COMPRESSION=auto;
PATCH_VBMETA_FLAG=auto;

. tools/ak3-core.sh;
ui_print " ";
ui_print "  ==============================";
ui_print "           SHIBUYA KERNEL";
ui_print "       motorola rtwo / sm8550";
ui_print "  ==============================";
ui_print " ";

# Detect available images (Moto variants only — no GKI/CLO distinction)
HAS_KSU=0; HAS_RESUKI=0; HAS_NOKSU=0;
[ -f "$AKHOME/Image.moto.ksu" ]   && HAS_KSU=1;
[ -f "$AKHOME/Image.moto.resuki" ]  && HAS_RESUKI=1;
[ -f "$AKHOME/Image.moto.noksu" ] && HAS_NOKSU=1;
TOTAL=$((HAS_KSU + HAS_RESUKI + HAS_NOKSU));

SELECTED_IMAGE="";

flush_keys() { sleep 0.15; }

# AIO: show selection menu
if [ "$TOTAL" -gt 1 ]; then
  ui_print " ";
  ui_print "  select variant";
  ui_print "  vol+ next | vol- confirm";
  OPTION=1;

  print_menu() {
    ui_print " ";
    I=0;
    [ "$HAS_NOKSU" = "1" ] && { I=$((I+1)); [ "$OPTION" = "$I" ] && ui_print "  > NoKSU (Vanilla)" || ui_print "    NoKSU (Vanilla)"; }
    [ "$HAS_KSU"   = "1" ] && { I=$((I+1)); [ "$OPTION" = "$I" ] && ui_print "  > KSU-Next" || ui_print "    KSU-Next"; }
    [ "$HAS_RESUKI"  = "1" ] && { I=$((I+1)); [ "$OPTION" = "$I" ] && ui_print "  > ReSukiSU" || ui_print "    ReSukiSU"; }
  }
  print_menu;
  flush_keys;

  while true; do
    input=$(getevent -qlc 1 2>/dev/null);
    case "$input" in
      *KEY_VOLUMEUP*DOWN*)
        OPTION=$(( OPTION % TOTAL + 1 ));
        print_menu; flush_keys ;;
      *KEY_VOLUMEDOWN*DOWN*)
        flush_keys; break ;;
    esac
  done

  I=0;
  [ "$HAS_NOKSU" = "1" ] && { I=$((I+1)); [ "$OPTION" = "$I" ] && { SELECTED_IMAGE="Image.moto.noksu"; ui_print "  selected: noksu"; }; }
  [ "$HAS_KSU"   = "1" ] && { I=$((I+1)); [ "$OPTION" = "$I" ] && { SELECTED_IMAGE="Image.moto.ksu";   ui_print "  selected: kernelsu-next"; }; }
  [ "$HAS_RESUKI"  = "1" ] && { I=$((I+1)); [ "$OPTION" = "$I" ] && { SELECTED_IMAGE="Image.moto.resuki";  ui_print "  selected: resukisu"; }; }

# Single image: auto-detect
elif [ "$HAS_NOKSU" = "1" ]; then SELECTED_IMAGE="Image.moto.noksu"; ui_print "  variant: noksu";
elif [ "$HAS_KSU"   = "1" ]; then SELECTED_IMAGE="Image.moto.ksu";   ui_print "  variant: kernelsu-next";
elif [ "$HAS_RESUKI"  = "1" ]; then SELECTED_IMAGE="Image.moto.resuki";  ui_print "  variant: resukisu";
elif [ -f "$AKHOME/Image" ]; then
  ui_print "  variant: standard";
else
  ui_print "  error: kernel image not found";
  exit 1;
fi

# Swap selected to Image
if [ -n "$SELECTED_IMAGE" ]; then
  mv -f "$AKHOME/$SELECTED_IMAGE" "$AKHOME/Image";
  rm -f "$AKHOME/Image.moto.ksu" "$AKHOME/Image.moto.resuki" "$AKHOME/Image.moto.noksu";
fi

[ -f "$AKHOME/Image" ] || { ui_print "  error: image preparation failed"; exit 1; }

# Flash — auto-detect init_boot vs boot
if [ -L "/dev/block/bootdevice/by-name/init_boot_a" ] || \
   [ -L "/dev/block/by-name/init_boot_a" ]; then
  ui_print "  target: init_boot";
  split_boot; flash_boot;
else
  ui_print "  target: boot";
  dump_boot; write_boot;
fi
ui_print " ";
ui_print "  installation complete";
ui_print "  ==============================";
## end boot install
