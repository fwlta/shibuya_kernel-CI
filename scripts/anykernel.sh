### AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers

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
'; }

boot_attributes() {
set_perm_recursive 0 0 755 644 $RAMDISK/*;
set_perm_recursive 0 0 750 750 $RAMDISK/init* $RAMDISK/sbin;
}

BLOCK=boot;
IS_SLOT_DEVICE=auto;
RAMDISK_COMPRESSION=auto;
PATCH_VBMETA_FLAG=auto;

. tools/ak3-core.sh;

HAS_RESUKI=0;
HAS_NOKSU=0;

[ -f "$AKHOME/Image.moto.resuki" ] && HAS_RESUKI=1;
[ -f "$AKHOME/Image.moto.noksu" ] && HAS_NOKSU=1;

TOTAL=$((HAS_RESUKI + HAS_NOKSU));
SELECTED_IMAGE="";

flush_keys() { sleep 0.15; }

if [ "$TOTAL" -gt 1 ]; then
  ui_print "select variant";
  ui_print "vol+ next | vol- confirm";
  OPTION=1;

  print_menu() {
    I=0;
    [ "$HAS_NOKSU" = "1" ] && { I=$((I+1)); [ "$OPTION" = "$I" ] && ui_print "> NoKSU" || ui_print "  NoKSU"; }
    [ "$HAS_RESUKI" = "1" ] && { I=$((I+1)); [ "$OPTION" = "$I" ] && ui_print "> ReSukiSU" || ui_print "  ReSukiSU"; }
  }

  print_menu;
  flush_keys;

  while true; do
    input=$(getevent -qlc 1 2>/dev/null);
    case "$input" in
      *KEY_VOLUMEUP*DOWN*)
        OPTION=$(( OPTION % TOTAL + 1 ));
        print_menu;
        flush_keys
        ;;
      *KEY_VOLUMEDOWN*DOWN*)
        flush_keys;
        break
        ;;
    esac
  done

  I=0;
  [ "$HAS_NOKSU" = "1" ] && { I=$((I+1)); [ "$OPTION" = "$I" ] && SELECTED_IMAGE="Image.moto.noksu"; }
  [ "$HAS_RESUKI" = "1" ] && { I=$((I+1)); [ "$OPTION" = "$I" ] && SELECTED_IMAGE="Image.moto.resuki"; }

elif [ "$HAS_NOKSU" = "1" ]; then SELECTED_IMAGE="Image.moto.noksu";
elif [ "$HAS_RESUKI" = "1" ]; then SELECTED_IMAGE="Image.moto.resuki";
elif [ -f "$AKHOME/Image" ]; then :;
else
  ui_print "error: kernel image not found";
  exit 1;
fi

if [ -n "$SELECTED_IMAGE" ]; then
  ui_print "variant: $(basename "$SELECTED_IMAGE" | sed 's/^Image\.moto\.//')";
  mv -f "$AKHOME/$SELECTED_IMAGE" "$AKHOME/Image";
  rm -f "$AKHOME"/Image.moto.*;
fi

[ -f "$AKHOME/Image" ] || { ui_print "error: image preparation failed"; exit 1; }

if [ -L "/dev/block/bootdevice/by-name/init_boot_a" ] || \
   [ -L "/dev/block/by-name/init_boot_a" ]; then
  ui_print "target: init_boot";
  split_boot;
  flash_boot;
else
  ui_print "target: boot";
  dump_boot;
  write_boot;
fi

ui_print "installation complete";
