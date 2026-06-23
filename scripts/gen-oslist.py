#!/usr/bin/env python3
"""Generate a Raspberry Pi Imager os-list.json for the latest Hub OS release.
Usage: gen-oslist.py <extract_sha256> <extract_size> <download_sha256> <download_size>
The image URL is the permanent 'latest release' asset, so the manifest never bakes a version."""
import sys, json, datetime
es, esz, ds, dsz = sys.argv[1], int(sys.argv[2]), sys.argv[3], int(sys.argv[4])
print(json.dumps({"os_list": [{
    "name": "Alby Hub",
    "description": "Self-custodial Lightning wallet on your Pi. No full node, no manual install.",
    "url": "https://github.com/getAlby/hub-os/releases/latest/download/HubOS-arm64.img.xz",
    "icon": "https://getalby.com/favicon.ico",
    "release_date": datetime.date.today().isoformat(),
    "init_format": "cloud-init",
    "extract_size": esz,
    "extract_sha256": es,
    "image_download_size": dsz,
    "image_download_sha256": ds,
    "devices": ["pi3-64bit", "pi4-64bit", "pi5-64bit", "pi-zero2-64bit"],
}]}, indent=2))
