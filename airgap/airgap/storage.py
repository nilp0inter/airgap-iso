from subprocess import check_output
import json

from invoke import task, run

from airgap import check


def get_thumbdrive_device():
    output = json.loads(check_output(["lsblk", "-J"]))
    device = list(filter(lambda x: x["name"].startswith("sd") and x["mountpoints"] == [None] and not x.get("children"), output["blockdevices"]))
    if not device:
        raise ValueError("NO device detected")
    return f"/dev/{device[0]['name']}"


@task
def get_drive(c):
    print(get_thumbdrive_device())


@task
def init(c):
    device = get_thumbdrive_device()
    if check(f"cryptsetup isLuks {device}"):
        print("Thumbdrive already initialized, use mount")
    else:
        c.run(f"cryptsetup luksFormat {device}", pty=True)
        c.run(f"cryptsetup luksOpen {device} thumbdrive", pty=True)
        c.run("mkfs.ext4 /dev/mapper/thumbdrive")
        c.run("mount /dev/mapper/thumbdrive /mnt")
        with c.cd("/mnt"):
            c.run("git init .")
            c.run("git remote add origin /root/gpgmain")
        c.run("umount /mnt")
        c.run("cryptsetup luksClose thumbdrive")


@task
def mount(c):
    device = get_thumbdrive_device()
    c.run(f"cryptsetup luksOpen {device} thumbdrive", pty=True)
    c.run("mount /dev/mapper/thumbdrive /mnt")


@task
def umount(c):
    c.run("umount /mnt")
    c.run("cryptsetup luksClose thumbdrive")

