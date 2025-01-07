# Sui-Voucher
The Sui-Voucher is a blockchain-based smart contract designed to manage a voucher system. It enables a decentralized way of managing vouchers, users, and funds using the Sui Move language.

## Features:
1. Create a Voucher Manager: Initialize the system with a zero balance, no users, and no vouchers.
2. Register Users: Add users to the system, assigning them unique IDs and a starting balance of zero.
3. Issue Vouchers: Create vouchers with a description, value (in SUI), and redemption status.
4. Fund the Manager: Add SUI funds to the manager's balance for voucher redemption.
5. Redeem Vouchers: Allow users to redeem vouchers for SUI coins, transferring value from the manager’s balance to the user’s balance while marking the voucher as redeemed.

The system also emits events (e.g., user registration, voucher issuance, redemption, funding) to log key actions. It ensures transparency, fraud prevention, and accountability.