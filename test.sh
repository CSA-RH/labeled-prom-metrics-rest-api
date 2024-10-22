#!/bin/bash

# Check if an argument was provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 {node|python}"
    exit 1
fi

# Get the argument
arg=$1
LANG="${arg,,}"

# Check the argument value
case $LANG in
    node)
        echo "You chose Node.js"
        ;;
    python)
        echo "You chose Python"
        ;;
    *)
        echo "Invalid argument: $arg"
        echo "Usage: $0 {node|python}"
        exit 1
        ;;
esac

HOST=https://$(oc get route prom-$LANG -ojsonpath='{.spec.host}')
CUSTOMERS=("bayern" "malagacf" "realmadrid")

# For loop with 10 iterations
for i in {1..10}; do    
    INDEX=$((RANDOM % ${#CUSTOMERS[@]}))  
    CUSTOMER=${CUSTOMERS[$INDEX]}    
    OPERATION=$((RANDOM % 2 + 1))
    echo "Iteration $i: ${CUSTOMERS[$INDEX]}. OP=$OPERATION"   
    curl -H "customer: $CUSTOMER" $HOST/operation$OPERATION
    echo && echo 
done