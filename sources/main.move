module dacade_deepbook::voucher_manager {
    use std::string::{String};
    use sui::balance::{Balance, zero};
    use sui::coin::{Coin, take, put, value as coin_value};
    use sui::sui::SUI;
    use sui::object::{new, uid_to_inner};
    use sui::event;
    use sui::tx_context::{self, TxContext};
    use sui::transfer;

    /// Custom error codes
    const ERR_INVALID_USER_ID: u64 = 0; // Invalid user ID
    const ERR_INVALID_VOUCHER_ID: u64 = 1; // Invalid voucher ID
    const ERR_VOUCHER_ALREADY_REDEEMED: u64 = 2; // Voucher already redeemed
    const ERR_INSUFFICIENT_FUNDS: u64 = 3; // Manager has insufficient funds
    const ERR_UNAUTHORIZED: u64 = 4; // Unauthorized access

    /// User structure
    struct User has store {
        id: u64,
        name: String,
        balance: Balance<SUI>,
        redeemed_vouchers: vector<u64>,
    }

    /// Voucher structure
    struct Voucher has store {
        id: u64,
        description: String,
        value: u64, // Value in SUI
        is_redeemed: bool,
    }

    /// Voucher Manager structure
    struct VoucherManager has key, store {
        id: UID,
        owner: address, // Owner for access control
        balance: Balance<SUI>, // Manager's total SUI balance
        vouchers: vector<Voucher>, // List of vouchers managed
        users: vector<User>, // List of registered users
    }

    /// Events for tracking actions
    struct ManagerFunded has copy, drop {
        manager_id: UID,
        amount: u64, // Amount funded
    }

    struct VoucherIssued has copy, drop {
        voucher_id: u64,
        description: String,
        value: u64,
    }

    struct VoucherRedeemed has copy, drop {
        user_id: u64,
        voucher_id: u64,
        value: u64,
    }

    struct UserRegistered has copy, drop {
        user_id: u64,
        name: String,
    }

    /// Initialize a new VoucherManager
    public entry fun create_manager(ctx: &mut TxContext) {
        let manager_uid = new(ctx);
        let owner = tx_context::sender(ctx);

        let manager = VoucherManager {
            id: manager_uid,
            owner,
            balance: zero<SUI>(),
            vouchers: vector::empty(),
            users: vector::empty(),
        };

        transfer::transfer(manager, owner);
    }

    /// Register a new user
    public entry fun register_user(
        manager: &mut VoucherManager,
        name: String,
        ctx: &mut TxContext
    ) {
        assert!(tx_context::sender(ctx) == manager.owner, ERR_UNAUTHORIZED);

        let user_id = vector::length(&manager.users) as u64;

        let new_user = User {
            id: user_id,
            name,
            balance: zero<SUI>(),
            redeemed_vouchers: vector::empty(),
        };

        vector::push_back(&mut manager.users, new_user);

        event::emit(UserRegistered {
            user_id,
            name,
        });
    }

    /// Issue a new voucher
    public entry fun issue_voucher(
        manager: &mut VoucherManager,
        description: String,
        value: u64,
        ctx: &mut TxContext
    ) {
        assert!(tx_context::sender(ctx) == manager.owner, ERR_UNAUTHORIZED);

        let voucher_id = vector::length(&manager.vouchers) as u64;

        let new_voucher = Voucher {
            id: voucher_id,
            description,
            value,
            is_redeemed: false,
        };

        vector::push_back(&mut manager.vouchers, new_voucher);

        event::emit(VoucherIssued {
            voucher_id,
            description,
            value,
        });
    }

    /// Fund the manager with SUI
    public entry fun fund_manager(
        manager: &mut VoucherManager,
        coins: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        assert!(tx_context::sender(ctx) == manager.owner, ERR_UNAUTHORIZED);

        let amount = coin_value<SUI>(&coins);
        put(&mut manager.balance, coins);

        event::emit(ManagerFunded {
            manager_id: manager.id,
            amount,
        });
    }

    /// Redeem a voucher for a user
    public entry fun redeem_voucher(
        manager: &mut VoucherManager,
        user_id: u64,
        voucher_id: u64,
        ctx: &mut TxContext
    ) {
        assert!(tx_context::sender(ctx) == manager.owner, ERR_UNAUTHORIZED);

        // Validate user existence
        if !(user_id < vector::length(&manager.users)) {
            return ERR_INVALID_USER_ID;
        }
        let user = vector::borrow_mut(&mut manager.users, user_id);

        // Validate voucher existence and redemption status
        if !(voucher_id < vector::length(&manager.vouchers)) {
            return ERR_INVALID_VOUCHER_ID;
        }
        let voucher = vector::borrow_mut(&mut manager.vouchers, voucher_id);

        if voucher.is_redeemed {
            return ERR_VOUCHER_ALREADY_REDEEMED;
        }

        // Check manager's balance
        let voucher_value = voucher.value;
        if coin_value<SUI>(&manager.balance) < voucher_value {
            return ERR_INSUFFICIENT_FUNDS;
        }

        // Redeem voucher
        voucher.is_redeemed = true;
        vector::push_back(&mut user.redeemed_vouchers, voucher_id);

        let redeemed_coins = take(&mut manager.balance, voucher_value, ctx);
        put(&mut user.balance, redeemed_coins);

        event::emit(VoucherRedeemed {
            user_id,
            voucher_id,
            value: voucher_value,
        });
    }
}
