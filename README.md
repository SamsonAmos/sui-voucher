# Sui-Voucher

Sui-Voucher is a decentralized voucher management system built on the Sui blockchain, using the Move language. It provides a secure and transparent way to manage vouchers, users, and funds, allowing for a flexible and extensible system that can be used in various blockchain applications.

## Key Features

1. **Voucher Manager Creation**: Set up the Voucher Manager with an initial zero balance, no users, and no vouchers. The system is ready for further actions such as user registration and voucher issuance.
   
2. **User Registration**: Register users to the system with a unique ID and a starting balance of zero. Each user can then manage their vouchers and participate in staking.

3. **Voucher Issuance**: Create new vouchers with a description, value (in SUI), and redemption status. Vouchers can be redeemed by users for SUI coins once issued.

4. **Funding the Manager**: Admins can fund the Voucher Manager with SUI coins, ensuring that sufficient funds are available for voucher redemption. This allows for seamless user interactions.

5. **Voucher Redemption**: Users can redeem their vouchers for SUI coins, transferring the value from the manager’s balance to the user’s balance. Once redeemed, the voucher’s status is updated to prevent double redemption.

6. **Admin Management**: The system allows for the addition of admin addresses. Admins can manage vouchers, fund the manager, and perform other high-level functions, ensuring secure and controlled access.

7. **Token Staking**: Users can stake their SUI tokens within the system, which are tracked in individual user accounts. This functionality opens up the possibility of integrating staking rewards or other tokenomics features.

8. **Access Control**: The system enforces strict access control. Only the owner and authorized admins can perform sensitive operations such as funding the manager, issuing vouchers, and adding new admins.

9. **Event Logging**: The system emits events for all major actions, including user registration, voucher issuance, redemption, manager funding, staking, and admin addition. This provides full transparency, enabling better monitoring, accountability, and auditability.


## System Overview

The VoucherManager smart contract manages all operations related to users, vouchers, and funds. It contains the following key components:

- **VoucherManager**: The central system object that holds the balance, user data, vouchers, and manages critical operations.
- **User**: Each registered user has a unique ID, balance, list of redeemed vouchers, and staked tokens.
- **Voucher**: Represents an issued voucher with a value and redemption status.
- **Admin**: Special addresses with higher privileges for managing and controlling the system.

The system emits events such as:

- **UserRegistered**: Emitted when a new user is registered.
- **VoucherIssued**: Emitted when a new voucher is created.
- **VoucherRedeemed**: Emitted when a user redeems a voucher.
- **ManagerFunded**: Emitted when the manager is funded with SUI coins.
- **UserStaked**: Emitted when a user stakes tokens.
- **AdminAdded**: Emitted when a new admin is added.