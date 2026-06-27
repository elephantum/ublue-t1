# Build multiple images

**Status:** Backlog

## Description

Build multiple image variants from the same codebase:
- Based on vanilla Silverblue
- Based on Bluefin
- Based on Bluefin-dx

We want built images to have form: {base-image-name}-t1

We want build to happen in parallel in GH Actions

We want [Show full build number in GRUB](grub-full-build-number.md) to be done
as well, so that it is obvious which image is loading

## Root cause

Currently only building a single image. Need to support multiple base images for
different use cases.

## Fixes applied

(Pending)

## Testing

(Pending)

## Notes

(None)
