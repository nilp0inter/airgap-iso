from invoke import task, run

@task
def init(c):
    c.run("git init --bare /root/gpgmain")
    c.run("gpg -K")
    with c.cd("/root/.gnupg"):
        c.run("git init .")
        c.run("git remote add origin /root/gpgmain")
        c.run("echo '.*' > .gitignore")
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
