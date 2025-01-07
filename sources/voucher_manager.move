#[allow(duplicate_alias)]
module voucher_manager::voucher_manager {
    use std::string::{String};
    use sui::balance::{Balance, zero};
    use sui::coin::{Coin, take, put, value as coin_value};
    use sui::sui::SUI;
    use sui::object::{new, uid_to_inner};
    use sui::event;
    use sui::transfer;

    const EVOUCHEREXPIRED: u64 = 0; // Error: Voucher expired or already redeemed
    const EUNAUTHORIZED: u64 = 2;   // Error: Unauthorized access

    public struct User has store {
        id: u64,
        name: String,
        balance: Balance<SUI>,
        redeemed_vouchers: vector<u64>,
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
    }

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

    public entry fun create_manager(ctx: &mut TxContext) {
        let manager_uid = new(ctx);
        let manager = VoucherManager {
            id: manager_uid,
            balance: zero<SUI>(),
            vouchers: vector::empty(),
            users: vector::empty(),
            voucher_count: 0,
            user_count: 0,
        };
        transfer::share_object(manager);
    }

    public entry fun register_user(
        manager: &mut VoucherManager,
        name: String,
        _ctx: &mut TxContext
    ) {
        let user_count = manager.user_count;
        let new_user = User {
            id: user_count,
            name,
            balance: zero<SUI>(),
            redeemed_vouchers: vector::empty(),
        };
        vector::push_back(&mut manager.users, new_user);
        manager.user_count = user_count + 1;

        event::emit(UserRegistered {
            user_id: user_count,
            name,
        });
    }

    public entry fun issue_voucher(
        manager: &mut VoucherManager,
        description: String,
        value: u64,
        _ctx: &mut TxContext
    ) {
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

    public entry fun fund_manager(
        manager: &mut VoucherManager,
        coins: Coin<SUI>,
        _ctx: &mut TxContext
    ) {
        let amount = coin_value<SUI>(&coins);
        put(&mut manager.balance, coins);

        event::emit(ManagerFunded {
            manager_id: uid_to_inner(&manager.id),
            amount,
        });
    }

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

public entry fun refund_user(
    manager: &mut VoucherManager,
    user_id: u64,
    ctx: &mut TxContext
) {
    // Validate user existence
    assert!(user_id < vector::length(&manager.users), EUNAUTHORIZED);
    let user = vector::borrow_mut(&mut manager.users, user_id);

    // Get the total value of the user's balance
    let user_balance_value = sui::balance::value(&user.balance);
    assert!(user_balance_value > 0, EVOUCHEREXPIRED);


    // Withdraw the user's balance as a Coin<SUI>
    let refund_coin = sui::coin::take(&mut user.balance, user_balance_value, ctx);

    // Transfer the funds back to the user's wallet
    sui::transfer::public_transfer(refund_coin, ctx.sender());
}

}
