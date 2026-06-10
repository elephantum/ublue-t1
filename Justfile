set shell := ["bash", "-euo", "pipefail", "-c"]

image_name := "mbp14-3-bluefin"
default_tag := "local"
build_tag_file := ".just-build-tag"
base_image := "ghcr.io/ublue-os/bluefin-dx:latest"

build target_image=image_name:
        build_tag="$(date +%Y%m%d%H%M%S%N)"; sudo podman build --build-arg BASE_IMAGE={{base_image}} --tag localhost/{{target_image}}:${build_tag} --tag localhost/{{target_image}}:{{default_tag}} .; printf '%s\n' "${build_tag}" > "{{build_tag_file}}"

list-images:
    sudo podman images | grep "mbp14-3-bluefin\|REPOSITORY"

rebase-local target_image=image_name:
    if [[ ! -f "{{build_tag_file}}" ]]; then echo "No recorded build tag found. Run 'just build' first."; exit 1; fi; sudo rpm-ostree rebase ostree-unverified-image:containers-storage:localhost/{{target_image}}:$(<"{{build_tag_file}}")

rollback:
    sudo rpm-ostree rollback

status:
    rpm-ostree status
