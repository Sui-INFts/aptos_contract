module infts_credit_score_addr::infts_credit_score {
    use std::option::{Self, Option};
    use std::signer;
    use std::string;

    use aptos_std::table::{Self, Table};
    use aptos_std::string_utils;

    use aptos_framework::event;
    use aptos_framework::object::{Self, ExtendRef, Object};
    use aptos_framework::timestamp;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;

    use aptos_token_objects::collection;
    use aptos_token_objects::token::{Self, Token};

    /// Only admin can set pending admin
    const EONLY_ADMIN_CAN_SET_PENDING_ADMIN: u64 = 2;
    /// Sender is not pending admin
    const ENOT_PENDING_ADMIN: u64 = 3;
    /// Only admin can update mint fee collector
    const EONLY_ADMIN_CAN_UPDATE_MINT_FEE_COLLECTOR: u64 = 4;
    /// Only admin can update mint fee
    const EONLY_ADMIN_CAN_UPDATE_MINT_FEE: u64 = 5;
    /// Only admin can update score
    const EONLY_ADMIN_CAN_UPDATE_SCORE: u64 = 15;
    /// User has already minted an SBT
    const EALREADY_MINTED: u64 = 16;
    /// Token does not exist
    const ETOKEN_NOT_FOUND: u64 = 17;
    /// Invalid score range (0-1000)
    const EINVALID_SCORE: u64 = 18;
    /// Insufficient balance for mint fee
    const EINSUFFICIENT_BALANCE: u64 = 19;
    
    /// Default mint fee per SBT (0 APT)
    const DEFAULT_MINT_FEE: u64 = 0;
    /// Maximum credit score
    const MAX_CREDIT_SCORE: u64 = 1000;

    // Property keys as constants
    const PROPERTY_SCORE: vector<u8> = b"score";
    const PROPERTY_LAST_UPDATED: vector<u8> = b"last_updated";
    const PROPERTY_MINT_TIMESTAMP: vector<u8> = b"mint_timestamp";

    #[event]
    struct MintSbtEvent has store, drop {
        token_obj: Object<Token>,
        recipient_addr: address,
        mint_fee: u64,
        timestamp: u64,
    }

    #[event]
    struct UpdateScoreEvent has store, drop {
        token_obj: Object<Token>,
        old_score: u64,
        new_score: u64,
        updater: address,
        timestamp: u64,
    }

    #[event]
    struct AdminChangedEvent has store, drop {
        old_admin: address,
        new_admin: address,
        timestamp: u64,
    }

    #[event]
    struct MintFeeUpdatedEvent has store, drop {
        old_fee: u64,
        new_fee: u64,
        updater: address,
        timestamp: u64,
    }

    /// Stored on each SBT object for mutable properties like score
    struct TokenProperties has key, store {
        score: u64,
        last_updated: u64,
        mint_timestamp: u64,
    }

    /// Unique per contract, owns the collection
    struct CollectionOwnerConfig has key {
        extend_ref: ExtendRef,
        collection_obj: Object<collection::Collection>,
        token_counter: u64,
    }

    /// Global per contract
    struct Config has key {
        admin_addr: address,
        pending_admin_addr: Option<address>,
        mint_fee_collector_addr: address,
        mint_fee: u64,
        collection_owner_obj: Object<CollectionOwnerConfig>,
        user_tokens: Table<address, Object<Token>>,
    }

    /// Initialize the module, create the single collection
    fun init_module(sender: &signer) {
        let module_addr = signer::address_of(sender);
        let collection_owner_constructor_ref = &object::create_object(module_addr);
        let collection_owner_signer = &object::generate_signer(collection_owner_constructor_ref);

        let collection_name = string::utf8(b"Credit Score SBT Collection");
        let collection_desc = string::utf8(b"Aptos DeFi Credit Score Soulbound Tokens");
        let collection_uri = string::utf8(b"https://example.com/credit_score/collection.json");

        let collection_constructor_ref = &collection::create_unlimited_collection(
            collection_owner_signer,
            collection_desc,
            collection_name,
            option::none(),
            collection_uri,
        );

        let collection_obj = object::object_from_constructor_ref(collection_constructor_ref);

        move_to(collection_owner_signer, CollectionOwnerConfig {
            extend_ref: object::generate_extend_ref(collection_owner_constructor_ref),
            collection_obj,
            token_counter: 0,
        });

        let collection_owner_obj = object::object_from_constructor_ref<CollectionOwnerConfig>(
            collection_owner_constructor_ref
        );

        move_to(sender, Config {
            admin_addr: module_addr,
            pending_admin_addr: option::none(),
            mint_fee_collector_addr: module_addr,
            mint_fee: DEFAULT_MINT_FEE,
            collection_owner_obj,
            user_tokens: table::new(),
        });
    }

    // Entry Functions //

    /// Set pending admin of the contract
    public entry fun set_pending_admin(sender: &signer, new_admin: address) acquires Config {
        let sender_addr = signer::address_of(sender);
        let config = borrow_global_mut<Config>(@infts_credit_score_addr);
        assert!(sender_addr == config.admin_addr, EONLY_ADMIN_CAN_SET_PENDING_ADMIN);
        config.pending_admin_addr = option::some(new_admin);
    }

    /// Accept admin of the contract
    public entry fun accept_admin(sender: &signer) acquires Config {
        let sender_addr = signer::address_of(sender);
        let config = borrow_global_mut<Config>(@infts_credit_score_addr);
        assert!(config.pending_admin_addr == option::some(sender_addr), ENOT_PENDING_ADMIN);
        
        let old_admin = config.admin_addr;
        config.admin_addr = sender_addr;
        config.pending_admin_addr = option::none();

        event::emit(AdminChangedEvent {
            old_admin,
            new_admin: sender_addr,
            timestamp: timestamp::now_seconds(),
        });
    }

    /// Update mint fee collector address
    public entry fun update_mint_fee_collector(
        sender: &signer, 
        new_mint_fee_collector: address
    ) acquires Config {
        let sender_addr = signer::address_of(sender);
        let config = borrow_global_mut<Config>(@infts_credit_score_addr);
        assert!(sender_addr == config.admin_addr, EONLY_ADMIN_CAN_UPDATE_MINT_FEE_COLLECTOR);
        config.mint_fee_collector_addr = new_mint_fee_collector;
    }

    /// Update mint fee (admin only)
    public entry fun update_mint_fee(sender: &signer, new_mint_fee: u64) acquires Config {
        let sender_addr = signer::address_of(sender);
        let config = borrow_global_mut<Config>(@infts_credit_score_addr);
        assert!(sender_addr == config.admin_addr, EONLY_ADMIN_CAN_UPDATE_MINT_FEE);
        
        let old_fee = config.mint_fee;
        config.mint_fee = new_mint_fee;

        event::emit(MintFeeUpdatedEvent {
            old_fee,
            new_fee: new_mint_fee,
            updater: sender_addr,
            timestamp: timestamp::now_seconds(),
        });
    }

    /// Update the DeFi score on an SBT
    public entry fun update_score(
        sender: &signer, 
        token_obj: Object<Token>, 
        new_score: u64
    ) acquires Config, TokenProperties {
        let sender_addr = signer::address_of(sender);
        let config = borrow_global<Config>(@infts_credit_score_addr);
        assert!(sender_addr == config.admin_addr, EONLY_ADMIN_CAN_UPDATE_SCORE);
        assert!(new_score <= MAX_CREDIT_SCORE, EINVALID_SCORE);

        let token_addr = object::object_address(&token_obj);
        assert!(exists<TokenProperties>(token_addr), ETOKEN_NOT_FOUND);
        
        let token_properties = borrow_global_mut<TokenProperties>(token_addr);
        
        // Get old score for event
        let old_score = token_properties.score;
        
        // Update properties
        token_properties.score = new_score;
        token_properties.last_updated = timestamp::now_seconds();

        event::emit(UpdateScoreEvent {
            token_obj,
            old_score,
            new_score,
            updater: sender_addr,
            timestamp: timestamp::now_seconds(),
        });
    }

    /// Batch update scores for multiple users
    public entry fun batch_update_scores(
        sender: &signer,
        token_objs: vector<Object<Token>>,
        new_scores: vector<u64>
    ) acquires Config, TokenProperties {
        let sender_addr = signer::address_of(sender);
        let config = borrow_global<Config>(@infts_credit_score_addr);
        assert!(sender_addr == config.admin_addr, EONLY_ADMIN_CAN_UPDATE_SCORE);
        
        let len = std::vector::length(&token_objs);
        assert!(len == std::vector::length(&new_scores), 100); // lengths must match
        
        let i = 0;
        while (i < len) {
            let token_obj = *std::vector::borrow(&token_objs, i);
            let new_score = *std::vector::borrow(&new_scores, i);
            
            assert!(new_score <= MAX_CREDIT_SCORE, EINVALID_SCORE);
            
            let token_addr = object::object_address(&token_obj);
            if (exists<TokenProperties>(token_addr)) {
                let token_properties = borrow_global_mut<TokenProperties>(token_addr);
                let old_score = token_properties.score;
                
                token_properties.score = new_score;
                token_properties.last_updated = timestamp::now_seconds();

                event::emit(UpdateScoreEvent {
                    token_obj,
                    old_score,
                    new_score,
                    updater: sender_addr,
                    timestamp: timestamp::now_seconds(),
                });
            };
            
            i = i + 1;
        };
    }

    /// Actual implementation of minting SBT (non-transferable)
    fun mint_sbt_internal(
        _recipient_addr: address,
        collection_owner_obj: Object<CollectionOwnerConfig>
    ): Object<Token> acquires CollectionOwnerConfig {
        let collection_owner_addr = object::object_address(&collection_owner_obj);
        let collection_owner_config = borrow_global_mut<CollectionOwnerConfig>(collection_owner_addr);
        let collection_owner_signer = &object::generate_signer_for_extending(
            &collection_owner_config.extend_ref
        );
        let collection_obj = collection_owner_config.collection_obj;

        // Increment counter
        collection_owner_config.token_counter = collection_owner_config.token_counter + 1;
        let token_id = collection_owner_config.token_counter;

        let token_name = string_utils::format1(&b"Credit Score SBT #{}", token_id);
        let token_desc = string::utf8(b"User's DeFi credit score soulbound token");
        let token_uri = string_utils::format1(&b"https://example.com/credit_score/{}.json", token_id);

        let token_constructor_ref = &token::create(
            collection_owner_signer,
            collection::name(collection_obj),
            token_desc,
            token_name,
            option::none(),
            token_uri,
        );

        // Make it Soulbound (non-transferable)
        let transfer_ref = object::generate_transfer_ref(token_constructor_ref);
        object::disable_ungated_transfer(&transfer_ref);

        // Create the token object
        let token_obj = object::object_from_constructor_ref(token_constructor_ref);

        // Store the token properties directly
        let token_signer = &object::generate_signer(token_constructor_ref);
        let current_time = timestamp::now_seconds();
        move_to(token_signer, TokenProperties {
            score: 0u64,
            last_updated: current_time,
            mint_timestamp: current_time,
        });

        // Token is soulbound, no transfer needed

        token_obj
    }

    /// Mint SBT for the user (one per address)
    public entry fun mint_sbt(sender: &signer) acquires Config, CollectionOwnerConfig {
        let sender_addr = signer::address_of(sender);
        let config = borrow_global_mut<Config>(@infts_credit_score_addr);
        assert!(!table::contains(&config.user_tokens, sender_addr), EALREADY_MINTED);

        let mint_fee = config.mint_fee;
        
        // Transfer mint fee if non-zero
        if (mint_fee > 0) {
            assert!(
                coin::balance<AptosCoin>(sender_addr) >= mint_fee, 
                EINSUFFICIENT_BALANCE
            );
            coin::transfer<AptosCoin>(sender, config.mint_fee_collector_addr, mint_fee);
        };

        let token_obj = mint_sbt_internal(sender_addr, config.collection_owner_obj);

        table::add(&mut config.user_tokens, sender_addr, token_obj);

        event::emit(MintSbtEvent {
            token_obj,
            recipient_addr: sender_addr,
            mint_fee,
            timestamp: timestamp::now_seconds(),
        });
    }

    // ================================= View Functions ================================= //

    #[view]
    /// Get contract admin
    public fun get_admin(): address acquires Config {
        let config = borrow_global<Config>(@infts_credit_score_addr);
        config.admin_addr
    }

    #[view]
    /// Get contract pending admin
    public fun get_pending_admin(): Option<address> acquires Config {
        let config = borrow_global<Config>(@infts_credit_score_addr);
        config.pending_admin_addr
    }

    #[view]
    /// Get mint fee collector address
    public fun get_mint_fee_collector(): address acquires Config {
        let config = borrow_global<Config>(@infts_credit_score_addr);
        config.mint_fee_collector_addr
    }

    #[view]
    /// Get current mint fee
    public fun get_mint_fee(): u64 acquires Config {
        let config = borrow_global<Config>(@infts_credit_score_addr);
        config.mint_fee
    }

    #[view]
    /// Get the DeFi score from an SBT's properties
    public fun get_score(token_obj: Object<Token>): u64 acquires TokenProperties {
        let token_addr = object::object_address(&token_obj);
        let token_properties = borrow_global<TokenProperties>(token_addr);
        token_properties.score
    }

    #[view]
    /// Get last updated timestamp for a token
    public fun get_last_updated(token_obj: Object<Token>): u64 acquires TokenProperties {
        let token_addr = object::object_address(&token_obj);
        let token_properties = borrow_global<TokenProperties>(token_addr);
        token_properties.last_updated
    }

    #[view]
    /// Get mint timestamp for a token
    public fun get_mint_timestamp(token_obj: Object<Token>): u64 acquires TokenProperties {
        let token_addr = object::object_address(&token_obj);
        let token_properties = borrow_global<TokenProperties>(token_addr);
        token_properties.mint_timestamp
    }

    #[view]
    /// Check if user has minted an SBT
    public fun has_minted(user_addr: address): bool acquires Config {
        let config = borrow_global<Config>(@infts_credit_score_addr);
        table::contains(&config.user_tokens, user_addr)
    }

    #[view]
    /// Get user's SBT object if minted
    public fun get_user_sbt(user_addr: address): Option<Object<Token>> acquires Config {
        let config = borrow_global<Config>(@infts_credit_score_addr);
        if (table::contains(&config.user_tokens, user_addr)) {
            option::some(*table::borrow(&config.user_tokens, user_addr))
        } else {
            option::none()
        }
    }

    #[view]
    /// Get total number of minted tokens
    public fun get_total_minted(): u64 acquires Config, CollectionOwnerConfig {
        let config = borrow_global<Config>(@infts_credit_score_addr);
        let collection_owner_addr = object::object_address(&config.collection_owner_obj);
        let collection_owner_config = borrow_global<CollectionOwnerConfig>(collection_owner_addr);
        collection_owner_config.token_counter
    }

    #[view]
    /// Get user's credit score (returns 0 if not minted)
    public fun get_user_score(user_addr: address): u64 acquires Config, TokenProperties {
        let config = borrow_global<Config>(@infts_credit_score_addr);
        if (table::contains(&config.user_tokens, user_addr)) {
            let token_obj = *table::borrow(&config.user_tokens, user_addr);
            get_score(token_obj)
        } else {
            0
        }
    }

    // ================================= Test Functions ================================= //

    #[test_only]
    public fun init_module_for_test(sender: &signer) {
        init_module(sender);
    }

    #[test_only]
    public fun get_collection_owner_obj_for_test(): Object<CollectionOwnerConfig> acquires Config {
        let config = borrow_global<Config>(@infts_credit_score_addr);
        config.collection_owner_obj
    }
}