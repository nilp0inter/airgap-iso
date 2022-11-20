from invoke import task, run

@task
def game(c):
    run("ninvaders", pty=True)


@task
def integration(c):
    print("Running integration tests!")
