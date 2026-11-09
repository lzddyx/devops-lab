#!/usr/bin/env python3
"""Validate pinned local image metadata across classic/containerd Docker stores."""
import json
import sys


def verify(metadata, reference, config_digest):
    manifest_digest = reference.rsplit("@", 1)[1]
    if metadata.get("Os") != "linux" or metadata.get("Architecture") != "arm64":
        raise ValueError("Expected linux/arm64 runtime")
    if reference not in (metadata.get("RepoDigests") or []):
        raise ValueError("Pinned official repository digest is missing")
    # Classic Docker uses the config digest as Id. Containerd-backed Docker can
    # use the pulled target descriptor (here, the pinned ARM64 manifest) instead.
    if metadata.get("Id") not in {config_digest, manifest_digest}:
        raise ValueError("Image ID is neither the verified config nor manifest digest")
    descriptor = metadata.get("Descriptor")
    if descriptor is not None and (not isinstance(descriptor, dict) or descriptor.get("digest") != manifest_digest):
        raise ValueError("Stored image descriptor differs from the pinned manifest")


def main():
    try:
        if len(sys.argv) != 3:
            raise ValueError("Expected pinned reference and verified config digest")
        metadata = json.load(sys.stdin)
        verify(metadata, sys.argv[1], sys.argv[2])
    except (ValueError, KeyError, TypeError, AttributeError) as exc:
        print(f"STOP: Base image verification failed: {exc}", file=sys.stderr)
        if isinstance(locals().get("metadata"), dict):
            safe = {k: metadata.get(k) for k in ("Id", "RepoDigests", "Os", "Architecture", "Descriptor")}
            print(json.dumps(safe, sort_keys=True), file=sys.stderr)
        return 1
    print("Verified official runtime: linux/arm64; pinned repository digest and image identity match.")
    print("Image ID: " + metadata["Id"])
    return 0


if __name__ == "__main__":
    sys.exit(main())
