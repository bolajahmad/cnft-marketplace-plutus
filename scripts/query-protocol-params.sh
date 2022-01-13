set -x

#!/bin/bash
~/.local/bin/cardano-cli query protocol-parameters \
    $BLOCKCHAIN \
    --out-file "scripts/$BLOCKCHAIN_PREFIX/protocol-parameters.json"
