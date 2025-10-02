#[test_only]
module infts_credit_score_addr::test_infts_credit_score {
    use std::option;
    use std::signer;
    use aptos_framework::aptos_coin::{Self, AptosCoin};
    use aptos_framework::coin;
    use aptos_framework::account;
    use aptos_framework::timestamp;

    use infts_credit_score_addr::infts_credit_score;

    #[test(aptos_framework = @0x1, sender = @infts_credit_score_addr, user1 = @0x200, user2 = @0x201)]
    fun test_happy_path(
        aptos_framework: &signer,
        sender: &signer,
        user1: &signer,
        user2: &signer,
    ) {
        // Initialize timestamp and accounts
        timestamp::set_time_has_started_for_testing(aptos_framework);
        let user1_addr = signer::address_of(user1);
        let user2_addr = signer::address_of(user2);
        account::create_account_for_test(user1_addr);
        account::create_account_for_test(user2_addr);

        // Initialize the module
        infts_credit_score::init_module_for_test(sender);

        // User1 mints SBT
        infts_credit_score::mint_sbt(user1);
        let user1_sbt_opt = infts_credit_score::get_user_sbt(user1_addr);
        assert!(option::is_some(&user1_sbt_opt), 1);
        let user1_sbt = *option::borrow(&user1_sbt_opt);
        let score = infts_credit_score::get_score(user1_sbt);
        assert!(score == 0, 2);

        // Check properties
        let last_updated = infts_credit_score::get_last_updated(user1_sbt);
        assert!(last_updated == timestamp::now_seconds(), 3);

        // Admin updates score
        timestamp::fast_forward_seconds(100); // Advance time
        infts_credit_score::update_score(sender, user1_sbt, 75);
        let new_score = infts_credit_score::get_score(user1_sbt);
        assert!(new_score == 75, 4);
        let new_last_updated = infts_credit_score::get_last_updated(user1_sbt);
        assert!(new_last_updated == timestamp::now_seconds(), 5);

        // User2 mints SBT
        infts_credit_score::mint_sbt(user2);
        let user2_sbt_opt = infts_credit_score::get_user_sbt(user2_addr);
        assert!(option::is_some(&user2_sbt_opt), 6);
        let user2_sbt = *option::borrow(&user2_sbt_opt);
        let score2 = infts_credit_score::get_score(user2_sbt);
        assert!(score2 == 0, 7);
    }

    #[test(aptos_framework = @0x1, sender = @infts_credit_score_addr, user1 = @0x200)]
    #[expected_failure(abort_code = 16, location = infts_credit_score_addr::infts_credit_score)]
    fun test_mint_twice_fails(
        aptos_framework: &signer,
        sender: &signer,
        user1: &signer,
    ) {
        timestamp::set_time_has_started_for_testing(aptos_framework);
        let user1_addr = signer::address_of(user1);
        account::create_account_for_test(user1_addr);

        infts_credit_score::init_module_for_test(sender);

        // First mint succeeds
        infts_credit_score::mint_sbt(user1);
        let user1_sbt_opt = infts_credit_score::get_user_sbt(user1_addr);
        assert!(option::is_some(&user1_sbt_opt), 1);

        // Second mint fails
        infts_credit_score::mint_sbt(user1);
    }

    #[test(aptos_framework = @0x1, sender = @infts_credit_score_addr, user1 = @0x200, non_admin = @0x202)]
    #[expected_failure(abort_code = 15, location = infts_credit_score_addr::infts_credit_score)]
    fun test_non_admin_cannot_update_score(
        aptos_framework: &signer,
        sender: &signer,
        user1: &signer,
        non_admin: &signer,
    ) {
        timestamp::set_time_has_started_for_testing(aptos_framework);
        let user1_addr = signer::address_of(user1);
        account::create_account_for_test(user1_addr);
        account::create_account_for_test(signer::address_of(non_admin));

        infts_credit_score::init_module_for_test(sender);

        infts_credit_score::mint_sbt(user1);
        let user1_sbt_opt = infts_credit_score::get_user_sbt(user1_addr);
        let user1_sbt = *option::borrow(&user1_sbt_opt);

        // Non-admin tries to update score, fails
        infts_credit_score::update_score(non_admin, user1_sbt, 50);
    }

    #[test(aptos_framework = @0x1, sender = @infts_credit_score_addr, user1 = @0x200)]
    fun test_admin_management(
        aptos_framework: &signer,
        sender: &signer,
        user1: &signer,
    ) {
        timestamp::set_time_has_started_for_testing(aptos_framework);
        let user1_addr = signer::address_of(user1);
        account::create_account_for_test(user1_addr);

        infts_credit_score::init_module_for_test(sender);

        // Check initial admin
        assert!(infts_credit_score::get_admin() == @infts_credit_score_addr, 1);

        // Set pending admin to user1
        infts_credit_score::set_pending_admin(sender, user1_addr);
        assert!(infts_credit_score::get_pending_admin() == option::some(user1_addr), 2);

        // User1 accepts admin
        infts_credit_score::accept_admin(user1);
        assert!(infts_credit_score::get_admin() == user1_addr, 3);
        assert!(infts_credit_score::get_pending_admin() == option::none(), 4);
    }

    #[test(aptos_framework = @0x1, sender = @infts_credit_score_addr, user1 = @0x200)]
    fun test_mint_with_fee(
        aptos_framework: &signer,
        sender: &signer,
        user1: &signer,
    ) {
        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(aptos_framework);

        timestamp::set_time_has_started_for_testing(aptos_framework);
        let user1_addr = signer::address_of(user1);
        account::create_account_for_test(user1_addr);
        coin::register<AptosCoin>(user1);

        infts_credit_score::init_module_for_test(sender);

        // Set mint_fee to 100 using the public function
        infts_credit_score::update_mint_fee(sender, 100);

        // Mint fee collector
        let collector_addr = infts_credit_score::get_mint_fee_collector();
        account::create_account_for_test(collector_addr);

        // Fund user1 and mint
        aptos_coin::mint(aptos_framework, user1_addr, 100);
        infts_credit_score::mint_sbt(user1);

        // Check balance transferred
        assert!(coin::balance<AptosCoin>(collector_addr) == 100, 1);
        assert!(coin::balance<AptosCoin>(user1_addr) == 0, 2);

        let user1_sbt_opt = infts_credit_score::get_user_sbt(user1_addr);
        assert!(option::is_some(&user1_sbt_opt), 3);

        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);
    }
}