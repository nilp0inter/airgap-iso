from invoke import task, run

@task
def init(c):
    c.run("git init --bare /root/gpgmain")
    c.run("gpg -K")
    with c.cd("/root/.gnupg"):
        c.run("git init .")
        c.run("git remote add origin /root/gpgmain")
        c.run("echo '.*' > .gitignore")
        c.run("echo '*.conf' >> .gitignore")
        c.run("echo disable-ccid > scdaemon.conf")
        c.run("echo reader-port Yubico YubiKey >> scdaemon.conf")
        c.run("git add -f .gitignore")
        c.run("git add -A")
        c.run("git commit -m 'Initial state'")
        c.run("git push --set-upstream origin main")

@task
def commit(c):
    with c.cd("/root/.gnupg"):
        c.run("git add -A")
        c.run("git commit -v", pty=True)

@task
def gen_key(c):
    c.run("gpg --expert --full-gen-key", pty=True)


@task
def edit_key(c, key):
    c.run(f"gpg --expert --edit-key {key}", pty=True)


@task
def restore(c):
    with c.cd("/root/.gnupg"):
        c.run("git fetch --all")
        c.run("git reset --hard origin/main")
        c.run("git clean -fd")


@task
def export_public_keys_to_sd(c, key):
    c.run("echo 'type=0x0c' | sfdisk /dev/mmcblk0")
    c.run("mkfs.vfat /dev/mmcblk0p1")
    c.run("mkdir -p /tmp/sd")
    c.run("mount /dev/mmcblk0p1 /tmp/sd")
    c.run(f"gpg --armor --export {key} > /tmp/sd/pubkeys.pgp")
    c.run("umount /tmp/sd")
