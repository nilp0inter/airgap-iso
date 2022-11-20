from subprocess import check_call, CalledProcessError

def check(*args, **kwargs):
    try:
        check_call(*args, shell=True, **kwargs)
    except CalledProcessError:
        return False
    else:
        return True
