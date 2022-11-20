from invoke import Program, Collection
from invoke import task, run

from airgap import gpg, storage, backup

@task
def game(c):
    run("ninvaders", pty=True)


collection = Collection(
    game,
    gpg,
    storage,
    backup
)

program = Program(namespace=collection, version='0.1.0')
