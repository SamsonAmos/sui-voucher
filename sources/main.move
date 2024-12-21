module dacade_deepbook::voucher_manager {
    use std::string::{String};
    use sui::balance::{Balance, zero};
    use sui::coin::{Coin, take, put, value as coin_value};
    use sui::sui::SUI;
    use sui::object::{new, uid_to_inner};
    use sui::event;

    // Custom error codes
    const EVOUCHEREXPIRED: u64 = 0; // Error: Voucher has expired or is already redeemed
    const EUNAUTHORIZED: u64 = 2;   // Error: Unauthorized access or invalid user ID

    /// User structure
    /// Represents a user with an ID, name, balance in SUI, and a list of redeemed vouchers
    public struct User has store {
        id: u64,
        name: String,
        balance: Balance<SUI>,
        redeemed_vouchers: vector<u64>,
    }

    /// Voucher structure
    /// Represents a voucher with an ID, description, value in SUI, and a redemption status
    public struct Voucher has store {
        id: u64,
        description: String,
        value: u64, // Value in SUI
        is_redeemed: bool,
    }

    /// Voucher Manager structure
    /// Manages users, vouchers, and overall balance
    public struct VoucherManager has key, store {
        id: UID,
        balance: Balance<SUI>, // Total SUI balance of the manager
        vouchers: vector<Voucher>, // List of vouchers managed
        users: vector<User>, // List of registered users
        voucher_count: u64, // Total number of vouchers issued
        user_count: u64,    // Total number of users registered
    }

    /// Events for tracking actions
    public struct ManagerFunded has copy, drop {
        manager_id: ID,
        amount: u64, // Amount funded to the manager
    }

    public struct VoucherIssued has copy, drop {
        voucher_id: u64,
        description: String,
        value: u64, // Value of the issued voucher
    }

    public struct VoucherRedeemed has copy, drop {
        user_id: u64,
        voucher_id: u64,
        value: u64, // Value of the redeemed voucher
    }

    public struct UserRegistered has copy, drop {
        user_id: u64,
        name: String, // Name of the registered user
    }

    /// Initialize a voucher manager
    /// Creates and shares a new `VoucherManager` object on-chain
    public entry fun create_manager(ctx: &mut TxContext) {
        // Generate UID for the manager
        let manager_uid = new(ctx);

        // Initialize a new VoucherManager object with default values
        let manager = VoucherManager {
            id: manager_uid,
            balance: zero<SUI>(),
            vouchers: vector::empty(),
            users: vector::empty(),
            voucher_count: 0,
            user_count: 0,
        };

        // Share the VoucherManager object on-chain
        transfer::share_object(manager);
    }

    /// Register a user to the voucher manager
    /// Adds a new user to the manager's user list and emits a registration event
    public entry fun register_user(
        manager: &mut VoucherManager,
        name: String,
        _ctx: &mut TxContext
    ) {
        // Get the current user count to assign a unique ID
        let user_count = manager.user_count;

        // Create a new user object
        let new_user = User {
            id: user_count,
            name,
            balance: zero<SUI>(),
            redeemed_vouchers: vector::empty(),
        };

        // Add the user to the manager's user list and increment the user count
        vector::push_back(&mut manager.users, new_user);
        manager.user_count = user_count + 1;

        // Emit a user registration event
        event::emit(UserRegistered {
            user_id: user_count,
            name,
        });
    }

    /// Issue a voucher
    /// Creates a new voucher and adds it to the manager's voucher list
    public entry fun issue_voucher(
        manager: &mut VoucherManager,
        description: String,
        value: u64,
        _ctx: &mut TxContext
    ) {
        // Get the current voucher count to assign a unique ID
        let voucher_count = manager.voucher_count;

        // Create a new voucher object
        let new_voucher = Voucher {
            id: voucher_count,
            description,
            value,
            is_redeemed: false,
        };

        // Add the voucher to the manager's voucher list and increment the voucher count
        vector::push_back(&mut manager.vouchers, new_voucher);
        manager.voucher_count = voucher_count + 1;

        // Emit a voucher issuance event
        event::emit(VoucherIssued {
            voucher_id: voucher_count,
            description,
            value,
        });
    }

    /// Fund the manager
    /// Adds SUI funds to the manager's balance and emits a funding event
    public entry fun fund_manager(
        manager: &mut VoucherManager,
        coins: Coin<SUI>, // Accept Coin<SUI>
        _ctx: &mut TxContext
    ) {
        // Get the coin value
        let amount = coin_value<SUI>(&coins);

        // Add the coin to the manager's balance
        put(&mut manager.balance, coins);

        // Emit the funding event
        event::emit(ManagerFunded {
            manager_id: uid_to_inner(&manager.id),
            amount,
        });
    }

    /// Redeem a voucher
    /// Validates and processes voucher redemption for a user
    public entry fun redeem_voucher(
        manager: &mut VoucherManager,
        user_id: u64,
        voucher_id: u64,
        ctx: &mut TxContext
    ) {
        // Validate user existence
        assert!(user_id < vector::length(&manager.users), EUNAUTHORIZED);
        let user = vector::borrow_mut(&mut manager.users, user_id);

        // Validate voucher existence and redemption status
        assert!(voucher_id < vector::length(&manager.vouchers), EVOUCHEREXPIRED);
        let voucher = vector::borrow_mut(&mut manager.vouchers, voucher_id);
        assert!(!voucher.is_redeemed, EVOUCHEREXPIRED);

        // Mark voucher as redeemed and record it in the user's redeemed vouchers
        voucher.is_redeemed = true;
        vector::push_back(&mut user.redeemed_vouchers, voucher_id);

        // Transfer the voucher value from the manager to the user's balance
        let redeemed_amount = take(&mut manager.balance, voucher.value, ctx);
        put(&mut user.balance, redeemed_amount);

        // Emit a voucher redemption event
        event::emit(VoucherRedeemed {
            user_id,
            voucher_id,
            value: voucher.value,
        });
    }
}
