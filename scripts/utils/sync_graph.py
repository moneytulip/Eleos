#!/usr/bin/python3
import os
import shutil

os.chdir('/home/dank/eleos')

for artifact in ['BDeployer', 'Borrowable', 'CDeployer', 'Collateral', 'Distributor', 'Factory', 'AmplifyPriceOracle', 'FarmingPool', 'PoolToken', 'VaultToken']:
    src_path = f"/home/dank/eleos/artifacts/contracts/{artifact}.sol/{artifact}.json"
    if artifact == 'Factory':
        dst_path = f"/home/dank/eleos-subgraph/abis/Amplify{artifact}.json"
    else:
        dst_path = f"/home/dank/eleos-subgraph/abis/{artifact}.json"
    print(artifact)
    shutil.copyfile(src_path, dst_path)
