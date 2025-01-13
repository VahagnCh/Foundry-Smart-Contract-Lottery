# Foundry Smart Contract Lottery

A decentralized and automated raffle system built with Foundry that uses Chainlink VRF (Verifiable Random Function) for transparent and provably fair winner selection.

## What is a Provably Random Raffle?

A provably random raffle is a lottery system where:

1. **Verifiable Randomness**: The winner selection process uses Chainlink VRF (Verifiable Random Function), which provides cryptographic proof that the random number used for selecting the winner was not manipulated.

2. **Transparency**: Anyone can verify:
   - How winners are selected
   - That the selection was truly random
   - That no one (not even the contract owner) could predict or manipulate the outcome

3. **Automation**: The raffle runs automatically using Chainlink Automation:
   - No manual intervention needed
   - Predetermined intervals between raffles
   - Automatic winner selection and prize distribution

## How it Works

1. Users enter the raffle by paying a ticket fee
2. After a set time interval, Chainlink Automation triggers the raffle drawing
3. Chainlink VRF provides a verified random number
4. The contract uses this random number to select a winner
5. The entire prize pool is automatically sent to the winner

This creates a trustless lottery system where participants can be confident in the fairness of the selection process.
