# COBrA
Fair COntent Trade on the BlockchAin

## DESCRIPTION
I have implemented a decentralised content publishing service, which enables the authors of new contents to submit their creation (song, video, photo,...) and to be rewarded accordingly to customers’ fruition. The users of COBrA are:
  - Customers: entities that wish to access a new content.
  - Authors: creators of a new contents
Customers may buy two kinds of accounts: Standard and Premium. Standard accounts require a payment for every single content access request, while Premium accounts require the payment of a fixed sum coverig a period of time, so enabling an
unrestricted access to any content for x time (expressed either in hours or in block height difference) starting from the subscription time. Once a customer has obtained the access to a content, it can consume the content, at most one time.
A customer can gift another customer, by buying access rights for someone else instead of itself, both for Standard and for Premium Accounts. Premium accounts cannot gift for free single contents to other users.

## IMPLEMENTATION
The smart contracts are written in Solidity using Remix to compile/deploy them. 
In the report file can be found a full description of the implementation chioces and some examples to understand how to deploy the contracts and use some of their functions. There's also an explaination of how to compute an extimation of the gas consumed by some functions.
