from invoke import Program, Collection
from airgap import tasks

program = Program(namespace=Collection.from_module(tasks), version='0.1.0')
