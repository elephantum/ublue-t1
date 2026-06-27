# Build multiple images

**Status:** Testing

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

- Added matrix strategy in `.github/workflows/build.yml` with three variants: `silverblue-t1`, `bluefin-t1`, `bluefin-dx-t1`
- Each variant builds from its corresponding base image and pushes to `ghcr.io/elephantum/<image_name>`
- Added `IMAGE_NAME` ARG to `Containerfile`, passed to `build.sh` and used in OCI labels
- Separate buildcache per variant

## Testing

1. Push a commit to master and verify three parallel CI jobs run (one per variant)
2. Check that `ghcr.io/elephantum/silverblue-t1:latest`, `ghcr.io/elephantum/bluefin-t1:latest`, and `ghcr.io/elephantum/bluefin-dx-t1:latest` are published
3. Run `just rebase-remote` pointing at one of the new images and confirm it boots

## Notes

(None)
