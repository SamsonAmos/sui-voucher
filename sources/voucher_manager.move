module voucher_manager::voucher_manager {
    use std::string::{String};
    use sui::balance::{Balance, zero};
    use sui::coin::{Coin, take, put, value as coin_value};
    use sui::sui::SUI;
    use sui::object::{new, uid_to_inner};
    use sui::event;

    // Error messages for specific failure scenarios
    const EVOUCHEREXPIRED: u64 = 0; // Voucher expired or already redeemed
    const EUNAUTHORIZED: u64 = 2;   // Unauthorized access

    // Data structures for users, vouchers, and the manager
    public struct User has store {
        id: u64,
        name: String,
        balance: Balance<SUI>,
        redeemed_vouchers: vector<u64>,
        staked_amount: Balance<SUI>, // Tracks staked tokens
    }

    public struct Voucher has store {
        id: u64,
        description: String,
        value: u64,
        is_redeemed: bool,
    }

    public struct VoucherManager has key, store {
        id: UID,
        balance: Balance<SUI>,
        vouchers: vector<Voucher>,
        users: vector<User>,
        voucher_count: u64,
        user_count: u64,
        owner: address,              
        admins: vector<address>,     
    }

    // Events for state changes
    public struct ManagerFunded has copy, drop {
        manager_id: ID,
        amount: u64,
    }

    public struct VoucherIssued has copy, drop {
        voucher_id: u64,
        description: String,
        value: u64,
    }

    public struct VoucherRedeemed has copy, drop {
        user_id: u64,
        voucher_id: u64,
        value: u64,
    }

    public struct UserRegistered has copy, drop {
        user_id: u64,
        name: String,
    }

    public struct UserStaked has copy, drop {
        user_id: u64,
        amount: u64,
    }

    public struct AdminAdded has copy, drop {
        admin_address: address,
    }

    // Create a new VoucherManager with the calling address as the owner
    public entry fun create_manager(ctx: &mut TxContext) {
        let manager_uid = new(ctx);
        let owner_address = ctx.sender();

        // Initialize a new VoucherManager with zero balances, no users or vouchers
        let manager = VoucherManager {
            id: manager_uid,
            balance: zero<SUI>(),
            vouchers: vector::empty(),
            users: vector::empty(),
            voucher_count: 0,
            user_count: 0,
            owner: owner_address,
            admins: vector::empty(),
        };

        // Share the newly created VoucherManager object
        transfer::share_object(manager);
    }

    // Check if an address is an admin or the owner
    fun is_admin(manager: &VoucherManager, address: address): bool {
        // Returns true if the address is an admin or the owner
        vector::contains(&manager.admins, &address) || manager.owner == address
    }

    // Register a new user
    public entry fun register_user(
        manager: &mut VoucherManager,
        name: String,
        ctx: &mut TxContext
    ) {
        // Ensure only the owner can register new users
        assert!(ctx.sender() == manager.owner, EUNAUTHORIZED);

        let user_count = manager.user_count;
        let new_user = User {
            id: user_count,
            name,
            balance: zero<SUI>(),
            redeemed_vouchers: vector::empty(),
            staked_amount: zero<SUI>(),
        };

        // Add the new user to the list of users and increment the user count
        vector::push_back(&mut manager.users, new_user);
        manager.user_count = user_count + 1;

        event::emit(UserRegistered {
            user_id: user_count,
            name,
        });
    }

    // Fund the manager's balance
    public entry fun fund_manager(
        manager: &mut VoucherManager,
        coins: Coin<SUI>,
        ctx: &mut TxContext
    ) {

        // Ensure only admins can fund the manager
        assert!(is_admin(manager, ctx.sender()), EUNAUTHORIZED);

        // Get the value of the coins and add them to the manager's balance
        let amount = coin_value<SUI>(&coins);
        put(&mut manager.balance, coins);

        event::emit(ManagerFunded {
            manager_id: uid_to_inner(&manager.id),
            amount,
        });
    }

    // Issue a new voucher
    public entry fun issue_voucher(
        manager: &mut VoucherManager,
        description: String,
        value: u64,
        ctx: &mut TxContext
    ) {
        assert!(is_admin(manager, ctx.sender()), EUNAUTHORIZED);

        let voucher_count = manager.voucher_count;
        let new_voucher = Voucher {
            id: voucher_count,
            description,
            value,
            is_redeemed: false,
        };
        vector::push_back(&mut manager.vouchers, new_voucher);
        manager.voucher_count = voucher_count + 1;

        event::emit(VoucherIssued {
            voucher_id: voucher_count,
            description,
            value,
        });
    }

    // Redeem a voucher
    public entry fun redeem_voucher(
        manager: &mut VoucherManager,
        user_id: u64,
        voucher_id: u64,
        ctx: &mut TxContext
    ) {
        assert!(user_id < vector::length(&manager.users), EUNAUTHORIZED);

        let user = vector::borrow_mut(&mut manager.users, user_id);
        assert!(voucher_id < vector::length(&manager.vouchers), EVOUCHEREXPIRED);

        let voucher = vector::borrow_mut(&mut manager.vouchers, voucher_id);
        assert!(!voucher.is_redeemed, EVOUCHEREXPIRED);

        voucher.is_redeemed = true;
        vector::push_back(&mut user.redeemed_vouchers, voucher_id);

        let redeemed_amount = take(&mut manager.balance, voucher.value, ctx);
        put(&mut user.balance, redeemed_amount);

        event::emit(VoucherRedeemed {
            user_id,
            voucher_id,
            value: voucher.value,
        });
    }

    // Add a new admin
    public entry fun add_admin(
        manager: &mut VoucherManager,
        admin_address: address,
        ctx: &mut TxContext
    ) {
        assert!(ctx.sender() == manager.owner, EUNAUTHORIZED);
        vector::push_back(&mut manager.admins, admin_address);

        event::emit(AdminAdded { admin_address });
    }

    // Stake tokens
    public entry fun stake_tokens(
        manager: &mut VoucherManager,
        user_id: u64,
        amount: Coin<SUI>,
        _ctx: &mut TxContext
    ) {
        // Ensure the user ID is valid
        assert!(user_id < vector::length(&manager.users), EUNAUTHORIZED);

        let user = vector::borrow_mut(&mut manager.users, user_id);
        
        // Add the staked tokens to the user's staked amount
        let staked_value = coin_value<SUI>(&amount);
        put(&mut user.staked_amount, amount);

        // Emit an event for the user staking tokens
        event::emit(UserStaked {
            user_id,
            amount: staked_value,
        });
    }
}
