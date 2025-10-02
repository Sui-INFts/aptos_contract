<h1 align="center">INFT Protocol: Intelligent NFT</h1>

<h3 align="center">Next-generation intelligent NFTs powered by AI, evolving with your data</h3>

<p align="center">
  <a href="https://aptos-client-eight.vercel.app/" style="color: #a77dff">Platform</a> | <a href="https://www.figma.com/deck/FcCmfAIWAyBsNf52hWGjge" style="color: #a77dff">Pitchdeck</a> | <a href="" style="color: #a77dff">Demo Video</a>
</p>

<p align="center">
  <a href="" style="color: #a77dff">Aptos</a> | <a href="https://explorer.aptoslabs.com/txn/0x1e87c79ffd90a73b7eff4cfcc32dd240a34f91755794e2a6fd50ddea76456db5?network=testnet" style="color: #a77dff">INFT SBT Minting</a> | <a href="" style="color: #a77dff">Credit Score</a>
</p>

![image](https://github.com/user-attachments/assets/2fc951f2-a160-4388-9275-a044a28e0290)

## Background

Traditional credit scoring systems are limited to Web2 financial institutions and often exclude large populations without formal credit histories. As Web3 expands, the need for decentralized, transparent, and AI-driven credit evaluation has become increasingly urgent. Current NFT standards also lack intelligence or adaptability — they remain static digital assets with no capacity for evolution.

The INFT Protocol bridges these gaps by introducing **Intelligent NFTs (INFTs):** dynamic, AI-driven NFTs that grow, evolve, and reflect user-specific attributes. The first use case of this protocol is a decentralized credit scoring system, where an INFT acts as a living certificate of financial trust across Web2 and Web3 ecosystems.

## What is INFT Protocol?

INFT Protocol is an AI-integrated NFT framework that enables:
* Intelligent NFTs (INFTs): NFTs that evolve based on user behavior and data.
* Decentralized Credit Scoring: Combining Web2 and Web3 data to generate a verifiable, on-chain credit score.
* AI Integration (iO Model): AI agents that analyze behavior, assign scores, and customize the evolution of each INFT.
* Secure Storage: All data is encrypted and stored on decentralized storage networks.

Through INFTs, users can track their creditworthiness, borrowing power, and financial history, while companies can leverage INFTs to assess loan limits, eligibility for airdrops, and risk management.

## First Use Case: Credit Scoring

The INFT Credit Scoring System generates personalized credit scores by evaluating three main categories:

1. **Transaction Behavior (60%)**
   * Payment frequency
   * Transaction volume
   * Repayment timeliness

2. **Engagement Behavior (20%)**
   * Quiz participation
   * Login streaks
   * Referrals

3. **Credit History (20%)**
   * Borrowing/repayment success or delays
   * On-chain credit records represented via credit-specific SBTs (Soulbound Tokens)

## Credit Score Formula

The credit score is calculated as:

$$
\text{Credit Score} = (0.6 \times T_s) + (0.2 \times E_s) + (0.2 \times C_s)
$$

Where:
* $T_s$ = Transaction Score (0–600 points)
* $E_s$ = Engagement Score (0–200 points)
* $C_s$ = Credit History Score (0–200 points)

Maximum Credit Score: 1000 points

## Data Storage & Security

<img width="3712" height="1664" alt="image" src="https://github.com/user-attachments/assets/1c864c79-d8d4-4830-bf00-a3edbeb8b111" />

* **SUI / MOVE Networks:**
  * Data is encrypted with SEAL encryption.
  * Stored in Walrus Storage.
  * INFT metadata updates automatically as scores/tier evolve.

* **Aptos Network:**
  * Data is stored in Shelby Storage (optimized for the Aptos ecosystem).
  * SEAL encryption is not applied in Aptos mode.
  * iO AI model still processes all scoring logic.
  * Users can interact with AI agents and directly perform on-chain DeFi transactions via Aptos smart contracts.

## Role of iO AI Model

The iO AI model is the core engine of INFT Protocol. It:
* Processes Web2 financial history, Web3 on-chain activity, and user engagement data.
* Calculates the final credit score using the weighted formula.
* Guides the evolution of each INFT, updating metadata, visuals, and tier.
* Enables chat-based interaction, allowing users to communicate with their AI agent, receive financial insights, and manage credit profiles directly.

All results are permanently recorded and synchronized on-chain, ensuring transparency and trust.

## Network Expansion

INFT Protocol supports multi-network deployment:

* **SUI / MOVE Chains:**
  * SEAL encryption + Walrus Storage.
  * Suited for broader Web3 financial integrations.

* **Aptos Network:**
  * Shelby Storage integration.
  * Chat-based AI agents for DeFi transaction execution.
  * INFT credit scoring tied directly to on-chain Aptos DeFi activity.

This modular approach allows INFT Protocol to adapt to ecosystem-specific strengths, providing both flexibility and scalability.

## Use Cases

* **For Users:**
  * Access personal credit scores across Web2 & Web3.
  * Build a verifiable financial reputation on-chain.
  * Unlock higher DeFi borrowing limits.
  * Qualify for token airdrops and whitelists.

* **For Companies / Protocols:**
  * Assess borrower risk using INFT-based credit scores.
  * Offer customized financial products.
  * Filter participants for community events, airdrops, or exclusive sales.

## Tech Stack

* AI Model: iO AI
* NFT Standard: INFT (Intelligent NFT, evolving metadata)
* Credit Records: SBTs (Soulbound Tokens)
* Storage:
  * Walrus (SUI)
  * Shelby (APTOS)
* Encryption: SEAL (only for MOVE networks)
* Smart Contracts: Move (SUI, APTOS)

## Roadmap

* **Phase 1:** Credit Scoring INFT MVP (SUI + Walrus Storage)
* **Phase 2:** Aptos Network Expansion (Shelby Storage + iO AI integration)
* **Phase 3:** Multi-chain INFT standardization & cross-chain interoperability
* **Phase 4:** Marketplace for INFT-based financial services (lending, staking, airdrops, and risk analysis tools)

## Contribution

We welcome contributions from developers, AI researchers, and Web3 builders.
Please check our issues tab for open tasks, or feel free to submit a PR.
