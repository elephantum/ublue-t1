# Sound does not work in browser (YouTube)

**Status:** Done

## Root cause

The Cirrus CS8409 HDA codec in MBP14,3 is not supported by the in-tree `snd_hda_intel` driver.
The community driver `snd_hda_macbookpro` (https://github.com/davidjo/snd_hda_macbookpro)
provides the necessary codec support.

## Fixes applied

Added an `audio-builder` stage to the Containerfile that:
1. Clones `https://github.com/davidjo/snd_hda_macbookpro` (master branch)
2. Builds the `snd_hda_macbookpro` kernel module via DKMS
3. Copies the resulting `.ko` file(s) into the final image under `/usr/lib/modules/<kernel>/extra/`
4. Runs `depmod` to register the module

Also added `/etc/modules-load.d/mbp14-audio.conf` to auto-load `snd_hda_macbookpro` at boot.

## Testing

1. Rebase to the new image
2. Check module is loaded: `lsmod | grep snd_hda_macbookpro`
3. Verify audio device appears: `aplay -l`
4. Play audio in Firefox/YouTube

## Notes

Fix confirmed working. Key issue was module precedence: both in-tree `kernel/sound/hda/codecs/cirrus/snd-hda-codec-cs8409.ko.xz` and our patched `extra/snd-hda-codec-cs8409.ko.xz` existed, and depmod was resolving to the in-tree version. Solution: delete the in-tree module so `depmod` prioritizes the custom driver from `extra/`. This is now done in the Containerfile.