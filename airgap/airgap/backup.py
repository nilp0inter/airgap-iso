from invoke import task, run

from airgap import check

@task
def restore(c):
    with c.cd("/mnt"):
        c.run("git push --force origin main")
    with c.cd("/root/.gnupg"):
        c.run("git fetch --all")
        c.run("git reset --hard origin/main")
        c.run("git clean -fd")

@task
def save(c):
    with c.cd("/root/.gnupg"):
        c.run("git push origin main")
    with c.cd("/mnt"):
        c.run("git pull origin main")
