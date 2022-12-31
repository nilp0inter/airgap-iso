import binascii
import yaml
import subprocess

from invoke import task, run

from airgap import check

SSSS_SPLIT = "/nix/store/jwdnxm8hnis5cgp9f5nwnyscmww6b3aj-ssss-0.5.7/bin/ssss-split"

@task
def split(c, secrets_yaml, threshold=3, shares=5):
    docs = list()
    for i in range(shares):
        docs.append(dict())

    with open(secrets_yaml, 'r') as secretfile:
        secrets = yaml.load(secretfile, yaml.SafeLoader)
        for key, secret in secrets.items():
            try:
                secret = secret.ljust(128, " ").encode('ascii')
                assert len(secret) == 128
            except UnicodeEncodeError as exc:
                raise ValueError("secret MUST be an ASCII string of max 128 characters") from exc
            proc = subprocess.Popen(
                [SSSS_SPLIT, "-n", str(shares), "-t", str(threshold), "-Q"],
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL)
            stdout, _ = proc.communicate(secret)
            chunks = stdout.decode('ascii').splitlines()
            for i, c in enumerate(chunks):
                docs[i][key] = chunks[i]

    for i, d in enumerate(docs, 1):
        with open(f"{secrets_yaml}.ssss{i}.yml", "w") as outputfile:
            outputfile.write("\n".join([
                f"To decode one of these secrets you need to gather a total of {threshold} parts of the {shares} that exist.",
                "And then execute this command and follow instructions:",
                f"$ ssss-combine -t {threshold}"
                "", "", ""]))
            yaml.dump(d, outputfile, sort_keys=False)
