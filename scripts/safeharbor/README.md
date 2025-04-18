# Overview

Safeharbor registry is a contract that allows protocols to identify addresses that are entitled to have funds recovered by a white hat during an attack.

# How to use

## Prerequisites

1. Active contracts CSV file.
Generated from the excel sheet, this file lives on the spells mainnet repo and is updated during the crafting process. If addressed are added or changed, they MUST appear in the diff of the active contracts file.

## First time setup
To adopt the safeharbor registry, there's a need to do a one time transaction to deploy the initial agreement details and then include the `adoptSafeHarbor` into a spell.

// TODO: add more details on this

## Subsequent spells

After the initial setup, the script takes care of generating the necessary calldata for updating the included contracts in the registry. The general execution flow is as follows:

1. Get the existing scope from the deployed registry.
2. Parse the updated active contracts CSV file and compare it with the existing scope.
3. If there are necessary changes, generate the calls to correctly update the registry.
