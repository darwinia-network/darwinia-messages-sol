## Running Instructions
To run a verification job:

1. Open terminal and `cd` your way to the `certora` directory in the bridge repository.

2. `touch` the `applyHarness.patch` file to make sure its last modification timestamp is later than your contracts:
    ```sh
    touch applyHarness.patch
    ```

3. Execute the `munged` command in the make file to copy the contracts to the munged directory and apply the changes in the patch:
    ```sh
    make munged
    ```

5. Run the script you'd like to get results for:
    ```sh
    sh scripts/BeaconLightClient.sh
    ```
