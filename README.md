# RAT-Benchmark
This repository contains Matlab implementations of the algorithms used in our paper entitled "Evaluating Performance of RAT Selection Algorithms for 5G HetNets", which we are submitting to be considered for publication in the IEEE Access. Our benchmark includes a library of different radio access technology (RAT) selection algorithms including:
- HSS (Highest Signal Strength): the default RAT association mechanism
- LSH (Local Search Heuristic): a centralized approach with local search 
- RM (Regret Matching): a partially distributed game-theoretic algorithm
- RSG (RAT Selection Games): a non-cooperative game scheme
- ERL (Enhanced Reinforcement Learning): a reinforcement learning with network-assisted feedback
- CODIPAS (Combined Fully Distributed Payoff and Strategy Reinforcement Learning): a fully distributed algoirthm

# Dataset
The following datasets are used in setting up PHY data rates of mobile users based on the mapping table of the corresponding technology.
- The WiFi dataset: this dataset provides traces of Received Signal Strength (RSS) measurement of the WiFi base stations colled at the University of Colorado. Available to access at https://crawdad.org/~crawdad/cu/cu_wart/20111024/   
- The LTE dataset: this dataset provides the measured Channel Quality Indication (CQI) from a tier-1 LTE operator in North America.

# Copyright
If you use any of the algorithms implemented in this repository, we would appreciate it if you could cite our paper
D. D. Nguyen, H. X. Nguyen and L. B. White, "Evaluating Performance of RAT Selection Algorithms for 5G HetNets,” The University of Adelaide, Australia, 2018. (will be updated)

# Contacts
This dataset and benchmark have been developed at the University of Adelaide with the effort of the authors:
- Duong D. Nguyen: https://www.adelaide.edu.au/directory/duong.nguyen
- Hung X. Nguyen: https://www.adelaide.edu.au/directory/hung.nguyen
- Langford B. White: https://www.adelaide.edu.au/directory/langford.white
