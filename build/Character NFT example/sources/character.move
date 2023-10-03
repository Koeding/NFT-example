/* 
Note: Using AptosCoin at the moment to create character accessories // need to create a coin module to mint players tokens
upon successful quest completion. Tokens are used as in game currency to upgrade your character.
*/


module character::character {

    use std::signer;
    use std::vector;
    use std::option::{Self, Option};
    use std::string::{Self, String};
    use aptos_token_objects::collection;
    use aptos_token_objects::token;
    use aptos_token_objects::property_map;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::{Self, AptosCoin};
    use aptos_framework::object::{Self, Object};
    use aptos_framework::event::{Self, EventHandle};
    use aptos_framework::account::{Self};
    use aptos_framework::fungible_asset::{Self, Metadata};    
    use aptos_framework::primary_fungible_store;
    
    #[test_only]
    use std::debug;

    
    //==============================================================================================
    // Errors 
    //==============================================================================================
    
    // Not module admin
    const ENOT_ADMIN: u64 = 1;
    // Not valid moderator
    const ENOT_MODERATOR: u64 = 2;
    // Not token creator
    const ENOT_CREATOR: u64 = 3;
    // One character per account
    const EACCOUNT_ALREADY_HAS_CHARACTER: u64 = 4;
    // Not enough funds for purchase
    const ENOT_ENOUGH_FUNDS: u64 = 5;
    // Not enough funds provided for mint
    const ENOT_ENOUGH_FUNDS_PROVIDED: u64 = 6;
    // Armour does not exist
    const EARMOUR_NON_EXISTANT: u64 = 7;
    // Trinket does not exist
    const ETRINKET_NON_EXISTANT: u64 = 8;
    // Weapon does not exist
    const EWEAPON_NON_EXISTANT: u64 = 9;
    // Invalid trinket unequip
    const EINVALID_TRINKET_UNEQUIP: u64 = 10;
    // Invalid trinket unequip
    const EINVALID_WEAPON_UNEQUIP: u64 = 11;
    // Invalid trinket unequip
    const EINVALID_ARMOUR_UNEQUIP: u64 = 12;
    // Token doesnt exist
    const ETOKEN_DOES_NOT_EXIST: u64 = 13;


    //==============================================================================================
    // Constants
    //==============================================================================================
    
    /// Character collection constants
    const OVERMIND_PLAYERS_NFT_COLLECTION: vector<u8> = b"Overminders";
    const OVERMIND_PLAYERS_NFT_DESCRIPTION: vector<u8> = b"An Overmind Adventurer";
    const OVERMIND_PLAYERS_NFT_COLLECTION_URI: vector<u8> = b"https://www.giantfreakinrobot.com/wp-content/uploads/2022/08/rick-astley-1200x675.jpg";

    /// Weapon collection name
    const OVERMIND_PLAYERS_WEAPON_COLLECTION: vector<u8> = b"Weapons";
    /// Weapon collection description
    const OVERMIND_PLAYERS_WEAPON_DESCRIPTION: vector<u8> = b"Character Weapon";
    /// Weapon collection URI
    const OVERMIND_PLAYERS_WEAPON_COLLECTION_URI: vector<u8> = b"https://www.giantfreakinrobot.com/wp-content/uploads/2022/08/rick-astley-1200x675.jpg";

    /// Weapon token names
    const DAGGER_TOKEN_NAME: vector<u8> = b"Dagger Token";
    const BROADSWORD_TOKEN_NAME: vector<u8> = b"Broadsword Token";
    const STAFF_TOKEN_NAME: vector<u8> = b"Staff Token";
    const WIZARDS_STAFF_TOKEN_NAME: vector<u8> = b"Wizards' Staff Token";
    const GREATSWORD_TOKEN_NAME: vector<u8> = b"Greatsword Token";
    const PISTOL_TOKEN_NAME: vector<u8> = b"Pistol Token";
    const LASER_PISTOL_TOKEN_NAME: vector<u8> = b"Laser Pistol Token";

   
    /// Trinket collection name
    const OVERMIND_PLAYERS_TRINKET_COLLECTION: vector<u8> = b"Trinket";
    /// Trinket collection description
    const OVERMIND_PLAYERS_TRINKET_DESCRIPTION: vector<u8> = b"Character Trinket";
    /// Trinket collection URI
    const OVERMIND_PLAYERS_TRINKET_COLLECTION_URI: vector<u8> = b"https://www.giantfreakinrobot.com/wp-content/uploads/2022/08/rick-astley-1200x675.jpg";

    /// Trinket token names
    const CHAIN_TOKEN_NAME: vector<u8> = b"Chain Token";
    const PENDANT_TOKEN_NAME: vector<u8> = b"Pendant Token";
    const BASEBALL_CAP_TOKEN_NAME: vector<u8> = b"Baseball Cap Token";
    const WIZARDS_HAT_TOKEN_NAME: vector<u8> = b"Wizards' Hat Token";
    const HELMET_TOKEN_NAME: vector<u8> = b"Helmet Token";
    const CROWN_TOKEN_NAME: vector<u8> = b"Crown Token";
    const HALO_TOKEN_NAME: vector<u8> = b"Halo Token";

    /// Armour collection name
    const OVERMIND_PLAYERS_ARMOUR_COLLECTION: vector<u8> = b"Armour";
    /// aArmour collection description
    const OVERMIND_PLAYERS_ARMOUR_DESCRIPTION: vector<u8> = b"Character Armour";
    /// armour collection URI
    const OVERMIND_PLAYERS_ARMOUR_COLLECTION_URI: vector<u8> = b"https://www.giantfreakinrobot.com/wp-content/uploads/2022/08/rick-astley-1200x675.jpg";

    /// Armour token names
    const SHIRT_TOKEN_NAME: vector<u8> = b"Shirt Token";
    const CLOAK_TOKEN_NAME: vector<u8> = b"Cloak Token";
    const WIZARDS_CLOAK_TOKEN_NAME: vector<u8> = b"Wizards' Cloak Token";
    const CHAINMAIL_TOKEN_NAME: vector<u8> = b"Chainmail Token";
    const KNIGHTS_ARMOUR_TOKEN_NAME: vector<u8> = b"Knights' Armour Token";
    const TUXEDO_TOKEN_NAME: vector<u8> = b"Tuxedo Token";
    const GOLDEN_AMOUR_TOKEN_NAME: vector<u8> = b"Golden Armour Token";

    // Rarity property name
    const RARITY_PROPERTY_NAME: vector<u8> = b"Rarity Property";
    // Item cost property name
    const ITEM_COST_PROPERTY_NAME: vector<u8> = b"Item Cost Property";
    // Item name property 
    const ITEM_NAME_PROPERTY: vector<u8> = b"Item Name";
    
       
    /// Seed for resouce creation
    const SEED: vector<u8> = b"character";

  
    //==============================================================================================
    // Structs
    //==============================================================================================

    struct State has key {
        collection: String,
        moderators: vector<address>,
        players: vector<address>,
        character_creation_events: EventHandle<CharacterCreationEvent>,
        weapon_creation_events: EventHandle<WeaponCreationEvent>,
        armour_creation_events: EventHandle<ArmourCreationEvent>,
        trinket_creation_events: EventHandle<TrinketCreationEvent>,
        resource_signer_capability: account::SignerCapability,
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct Character has key {
        gender: String,
        name: String,
        weapon: Option<Object<WeaponToken>>,
        armour: Option<Object<ArmourToken>>,
        trinket: Option<Object<TrinketToken>>,
        treasure: Option<Object<Treasure>>,
        mutator_ref: token::MutatorRef,
        property_mutator_ref: property_map::MutatorRef,
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct WeaponToken has key {
        weapon_name: String,
        cost: u64,
        property_mutator_ref: property_map::MutatorRef,
        fungible_asset_mint_ref: fungible_asset::MintRef,
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct ArmourToken has key {
        armour_name: String,
        cost: u64,
        property_mutator_ref: property_map::MutatorRef,
        fungible_asset_mint_ref: fungible_asset::MintRef,
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct TrinketToken has key {
        trinket_name: String,
        cost: u64,
        property_mutator_ref: property_map::MutatorRef,
        fungible_asset_mint_ref: fungible_asset::MintRef,
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct Treasure has key {
        treasure_name: String,
        treasure_environment_modifier: String,
        treasure_title_prefix: String,
        treasure_rarity: Rarity,
    }
       
    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct Rarity has key, store {
        // 0 = poo, 255 = flex
        item_rarity: u64,
    }
   
    //==============================================================================================
    // Events
    //==============================================================================================
    
    struct CharacterCreationEvent has store, drop {
        name: String,
        character_address: address,
    }

    struct WeaponCreationEvent has store, drop {
        weapon_name: String,
        player_address: address,
    }

    struct ArmourCreationEvent has store, drop {
        armour_name: String,
        player_address: address,
    }

    struct TrinketCreationEvent has store, drop {
        trinket_name: String,
        player_address: address,
    }

    //==============================================================================================
    // Functions
    //==============================================================================================

    /*
     * @params: account - Resource account hosting collection data
     * @notice: instantiating collection / for overminder PDA
     */
    fun init_module(admin: &signer) {
        // create resource account
        let (resource_signer, signer_capability) = account::create_resource_account(admin, SEED);

        // publish state
        let state = State {
            collection: string::utf8(OVERMIND_PLAYERS_NFT_COLLECTION),
            moderators: vector[signer::address_of(admin), signer::address_of(&resource_signer)],
            players: vector[],
            character_creation_events: account::new_event_handle<CharacterCreationEvent>(&resource_signer),
            weapon_creation_events: account::new_event_handle<WeaponCreationEvent>(&resource_signer),
            armour_creation_events: account::new_event_handle<ArmourCreationEvent>(&resource_signer),
            trinket_creation_events: account::new_event_handle<TrinketCreationEvent>(&resource_signer),
            resource_signer_capability: signer_capability,
        };
        move_to<State>(&resource_signer, state);

        coin::register<AptosCoin>(& resource_signer);
        
        create_character_collection(&resource_signer);
        create_armour(&resource_signer);
        create_weapon(&resource_signer);
        create_trinket(&resource_signer);
    }

    //==============================================================================================
    // Character Minting Functions
    //==============================================================================================
    
    entry fun mint_character(resource: &signer,
        player: address,
        gender: String,
        name: String,
        description: String,
        uri: String,
    ) acquires State {
        assert!(is_moderator(signer::address_of(resource)), ENOT_MODERATOR);
        let state = borrow_global_mut<State>(signer::address_of(resource));

        assert!(!vector::contains(&state.players, &player), EACCOUNT_ALREADY_HAS_CHARACTER);
        
        let token_address = create_character_for_player(resource, player, gender, name, description, uri);

        event::emit_event(&mut state.character_creation_events, CharacterCreationEvent {
            name: name,
            character_address: token_address,
        });
    }

    /*
     * @params: resource - The overlord..
     * @params: name - Players Overmind tag
     * @params: description - Character description
     * @notice: Called from mint_player
     * @notice: creates a Character nft, limit of one per account.
     */
   fun create_character_for_player(
        resource: &signer,
        player: address,
        gender: String,
        name: String,
        description: String,
        uri: String,
    ): address {
        let constructor_ref = token::create_named_token(
            resource,
            string::utf8(OVERMIND_PLAYERS_NFT_COLLECTION),
            description,
            name,
            option::none(),
            uri,
        );
        let object_signer = object::generate_signer(&constructor_ref);

        // Transfer to player and make soulbound
        let transfer_ref = object::generate_transfer_ref(&constructor_ref);
        let linear_transfer_ref = object::generate_linear_transfer_ref(&transfer_ref);
        let property_mutator_ref = property_map::generate_mutator_ref(&constructor_ref);
        object::transfer_with_ref(linear_transfer_ref, player);
        object::disable_ungated_transfer(&transfer_ref);

        let properties = property_map::prepare_input(vector[], vector[], vector[]);
        property_map::init(&constructor_ref, properties);

        move_to(&object_signer, Character {
            gender: gender,
            name: name,
            weapon: option::none<Object<WeaponToken>>(),
            armour: option::none<Object<ArmourToken>>(),
            trinket: option::none<Object<TrinketToken>>(),
            treasure: option::none<Object<Treasure>>(),
            mutator_ref: token::generate_mutator_ref(&constructor_ref), 
            property_mutator_ref: property_mutator_ref,
            });

        signer::address_of(&object_signer)
    }

    //==============================================================================================
    // Token Object Minting Functions
    //==============================================================================================

    
    public entry fun mint_weapon(creator: &signer, receiver: &signer, item_name: String, cost: u64) acquires WeaponToken {
        let weapon_token = object::address_to_object<WeaponToken>(weapon_token_address(signer::address_of(creator), item_name));

        assert!(property_map::read_u64<WeaponToken>(&weapon_token, &string::utf8(ITEM_COST_PROPERTY_NAME)) <= cost, ENOT_ENOUGH_FUNDS_PROVIDED);
        assert!(coin::balance<AptosCoin>(signer::address_of(receiver)) >= cost, ENOT_ENOUGH_FUNDS);

        coin::transfer<AptosCoin>(receiver, signer::address_of(creator), cost);
        mint_weapon_internal(creator, weapon_token, signer::address_of(receiver), 1);
    }

    fun mint_weapon_internal(creator: &signer, token: Object<WeaponToken>, receiver: address, cost: u64) acquires WeaponToken {
        let weapon_token = authorized_weapon_borrow<WeaponToken>(creator, &token);
        assert!(coin::balance<AptosCoin>(receiver) >= cost, ENOT_ENOUGH_FUNDS);
        let fungible_asset_mint_ref = &weapon_token.fungible_asset_mint_ref;
        let weapon_asset = fungible_asset::mint(fungible_asset_mint_ref, 1);
        primary_fungible_store::deposit(receiver, weapon_asset);
    }

    inline fun authorized_weapon_borrow<T: key>(creator: &signer, token: &Object<T>): &WeaponToken {
        let token_address = object::object_address(token);
        assert!(exists<WeaponToken>(token_address), ETOKEN_DOES_NOT_EXIST);

        assert!(token::creator(*token) == signer::address_of(creator), ENOT_CREATOR);
        borrow_global<WeaponToken>(token_address)
    }
   
    public entry fun mint_armour(creator: &signer, receiver: &signer, item_name: String, cost: u64) acquires ArmourToken {
        let armour_token = object::address_to_object<ArmourToken>(armour_token_address(signer::address_of(creator), item_name));

        assert!(property_map::read_u64<ArmourToken>(&armour_token, &string::utf8(ITEM_COST_PROPERTY_NAME)) <= cost, ENOT_ENOUGH_FUNDS);
        assert!(coin::balance<AptosCoin>(signer::address_of(receiver)) >= cost, ENOT_ENOUGH_FUNDS);

        coin::transfer<AptosCoin>(receiver, signer::address_of(creator), cost);
        mint_armour_internal(creator, armour_token, signer::address_of(receiver), 1);
    }

    fun mint_armour_internal(creator: &signer, token: Object<ArmourToken>, receiver: address, cost: u64) acquires ArmourToken {
        let armour_token = authorized_armour_borrow<ArmourToken>(creator, &token);
        assert!(coin::balance<AptosCoin>(receiver) >= cost, ENOT_ENOUGH_FUNDS);
        let fungible_asset_mint_ref = &armour_token.fungible_asset_mint_ref;
        let armour_asset = fungible_asset::mint(fungible_asset_mint_ref, 1);
        primary_fungible_store::deposit(receiver, armour_asset);
    }

    inline fun authorized_armour_borrow<T: key>(creator: &signer, token: &Object<T>): &ArmourToken {
        let token_address = object::object_address(token);
        assert!(exists<ArmourToken>(token_address), ETOKEN_DOES_NOT_EXIST);

        assert!(token::creator(*token) == signer::address_of(creator), ENOT_CREATOR);
        borrow_global<ArmourToken>(token_address)
    }

    public entry fun mint_trinket(creator: &signer, receiver: &signer, item_name: String, cost: u64) acquires TrinketToken {
        let trinket_token = object::address_to_object<TrinketToken>(trinket_token_address(signer::address_of(creator), item_name));

        assert!(property_map::read_u64<TrinketToken>(&trinket_token, &string::utf8(ITEM_COST_PROPERTY_NAME)) <= cost, ENOT_ENOUGH_FUNDS);
        assert!(coin::balance<AptosCoin>(signer::address_of(receiver)) >= cost, ENOT_ENOUGH_FUNDS);

        coin::transfer<AptosCoin>(receiver, signer::address_of(creator), cost);
        mint_trinket_internal(creator, trinket_token, signer::address_of(receiver), 1);
    }

    fun mint_trinket_internal(creator: &signer, token: Object<TrinketToken>, receiver: address, cost: u64) acquires TrinketToken {
        let trinket_token = authorized_trinket_borrow<TrinketToken>(creator, &token);
        assert!(coin::balance<AptosCoin>(receiver) >= cost, ENOT_ENOUGH_FUNDS);
        let fungible_asset_mint_ref = &trinket_token.fungible_asset_mint_ref;
        let trinket_asset = fungible_asset::mint(fungible_asset_mint_ref, 1);
        primary_fungible_store::deposit(receiver, trinket_asset);
    }

    inline fun authorized_trinket_borrow<T: key>(creator: &signer, token: &Object<T>): &TrinketToken {
        let token_address = object::object_address(token);
        assert!(exists<TrinketToken>(token_address), ETOKEN_DOES_NOT_EXIST);

        assert!(token::creator(*token) == signer::address_of(creator), ENOT_CREATOR);
        borrow_global<TrinketToken>(token_address)
    }

    public fun equip_weapon(owner: &signer, character: Object<Character>, weapon: Object<WeaponToken>) acquires Character {
        let character_obj = borrow_global_mut<Character>(object::object_address<Character>(&character));
        option::fill(&mut character_obj.weapon, weapon);
        object::transfer_to_object(owner, weapon, character);
        let item_name = property_map::read_string(&weapon, &string::utf8(ITEM_NAME_PROPERTY));
        property_map::add_typed(
            &character_obj.property_mutator_ref,
            string::utf8(b"Weapon"),
            item_name,
        );
    }

    public fun unequip_weapon(owner: &signer, character: Object<Character>, weapon: Object<WeaponToken>) acquires Character {
        let character_obj = borrow_global_mut<Character>(object::object_address<Character>(&character));
        let stored_weapon = option::extract(&mut character_obj.weapon);
        assert!(stored_weapon == weapon, EINVALID_WEAPON_UNEQUIP);
        object::transfer(owner, weapon, signer::address_of(owner));
        property_map::update_typed(
            &character_obj.property_mutator_ref,
            &string::utf8(b"Weapon"),
            string::utf8(b"None"),
        );
    }

   public fun equip_armour(owner: &signer, character: Object<Character>, armour: Object<ArmourToken>) acquires Character {
        let character_obj = borrow_global_mut<Character>(object::object_address<Character>(&character));
        option::fill(&mut character_obj.armour, armour);
        object::transfer_to_object(owner, armour, character);
        let item_name = property_map::read_string(&armour, &string::utf8(ITEM_NAME_PROPERTY));
        property_map::add_typed(
            &character_obj.property_mutator_ref,
            string::utf8(b"Armour"),
            item_name,
        );
    }

    public fun unequip_armour(_owner: &signer, character: Object<Character>) acquires Character {
        let character_obj = borrow_global_mut<Character>(object::object_address<Character>(&character));
        let _stored_armour = option::extract(&mut character_obj.armour);
        
        // object::transfer(owner, stored_armour, signer::address_of(owner));
        property_map::update_typed(
            &character_obj.property_mutator_ref,
            &string::utf8(b"Armour"),
            string::utf8(b"None"),
        );
    }

    public fun equip_trinket(owner: &signer, character: Object<Character>, trinket: Object<TrinketToken>) acquires Character {
        let character_obj = borrow_global_mut<Character>(object::object_address(&character));
        option::fill(&mut character_obj.trinket, trinket);
        object::transfer_to_object(owner, trinket, character);
        let item_name = property_map::read_string(&trinket, &string::utf8(ITEM_NAME_PROPERTY));
        property_map::add_typed(
            &character_obj.property_mutator_ref,
            string::utf8(b"Trinket"),
            item_name,
        );
    }

    public fun unequip_trinket(owner: &signer, character: Object<Character>, trinket: Object<TrinketToken>) acquires Character {
        let character_obj = borrow_global_mut<Character>(object::object_address(&character));
        let stored_trinket = option::extract(&mut character_obj.trinket);
        assert!(stored_trinket == trinket, EINVALID_TRINKET_UNEQUIP);
        object::transfer(owner, trinket, signer::address_of(owner));
        property_map::update_typed(
            &character_obj.property_mutator_ref,
            &string::utf8(b"Trinket"),
            string::utf8(b"None"),
        );
    }

    //==============================================================================================
    // Collection Creation Functions
    //==============================================================================================

    /// Creates the character collection.
    fun create_character_collection(creator: &signer) {
        collection::create_unlimited_collection(
            creator,
            string::utf8(OVERMIND_PLAYERS_NFT_DESCRIPTION),
            string::utf8(OVERMIND_PLAYERS_NFT_COLLECTION),
            option::none(),
            string::utf8(OVERMIND_PLAYERS_NFT_COLLECTION_URI),
        );
    }

    /// Creates the weapon collection.
    fun create_weapon_collection(creator: &signer) {
        collection::create_unlimited_collection(
            creator,
            string::utf8(OVERMIND_PLAYERS_WEAPON_DESCRIPTION),
            string::utf8(OVERMIND_PLAYERS_WEAPON_COLLECTION),
            option::none(),
            string::utf8(OVERMIND_PLAYERS_WEAPON_COLLECTION_URI),
        );
    }

    /// Creates the armour collection.
    fun create_armour_collection(creator: &signer) {
        collection::create_unlimited_collection(
            creator,
            string::utf8(OVERMIND_PLAYERS_ARMOUR_DESCRIPTION),
            string::utf8(OVERMIND_PLAYERS_ARMOUR_COLLECTION),
            option::none(),
            string::utf8(OVERMIND_PLAYERS_ARMOUR_COLLECTION_URI),
        );
    }

    /// Creates the trinket collection.
    fun create_trinket_collection(creator: &signer) {
        collection::create_unlimited_collection(
            creator,
            string::utf8(OVERMIND_PLAYERS_TRINKET_DESCRIPTION),
            string::utf8(OVERMIND_PLAYERS_TRINKET_COLLECTION),
            option::none(),
            string::utf8(OVERMIND_PLAYERS_TRINKET_COLLECTION_URI),
        );
    }

    //==============================================================================================
    // Fungible Token Creation Functions
    //==============================================================================================

    /// Creates the weapon token as fungible token.
    fun create_weapon_token_as_fungible_token(
        creator: &signer,
        description: String,
        name: String,
        uri: String,
        fungible_asset_name: String,
        fungible_asset_symbol: String,
        icon_uri: String,
        project_uri: String,
        weapon_rarity: u64,
        cost: u64,
    ) {
        let collection = string::utf8(OVERMIND_PLAYERS_WEAPON_COLLECTION);
        let constructor_ref = token::create_named_token(
            creator,
            collection,
            description,
            name,
            option::none(),
            uri,
        );


        let object_signer = object::generate_signer(&constructor_ref);
        let property_mutator_ref = property_map::generate_mutator_ref(&constructor_ref);

        move_to(&object_signer, Rarity { item_rarity: weapon_rarity });

        // Initialize the property map.
        let properties = property_map::prepare_input(vector[], vector[], vector[]);
        property_map::init(&constructor_ref, properties);
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(RARITY_PROPERTY_NAME),
            weapon_rarity
        );
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(ITEM_COST_PROPERTY_NAME),
            cost
        );
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(ITEM_NAME_PROPERTY),
            name
        );

        // Creates the fungible asset.
        primary_fungible_store::create_primary_store_enabled_fungible_asset(
            &constructor_ref,
            option::none(),
            fungible_asset_name,
            fungible_asset_symbol,
            0,
            icon_uri,
            project_uri,
        );
        let fungible_asset_mint_ref = fungible_asset::generate_mint_ref(&constructor_ref);

        // Publishes the WeaponToken resource
        let weapon_token = WeaponToken {
            weapon_name: fungible_asset_name,
            cost: cost,
            property_mutator_ref: property_mutator_ref,
            fungible_asset_mint_ref: fungible_asset_mint_ref,
        };
        move_to(&object_signer, weapon_token);
    }

    /// Creates the armour token as fungible token.
    fun create_armour_token_as_fungible_token(
        creator: &signer,
        description: String,
        name: String,
        uri: String,
        fungible_asset_name: String,
        fungible_asset_symbol: String,
        icon_uri: String,
        project_uri: String,
        armour_rarity: u64,
        cost: u64,
    ) {
        let collection = string::utf8(OVERMIND_PLAYERS_ARMOUR_COLLECTION);
        let constructor_ref = token::create_named_token(
            creator,
            collection,
            description,
            name,
            option::none(),
            uri,
        );

        let object_signer = object::generate_signer(&constructor_ref);
        let property_mutator_ref = property_map::generate_mutator_ref(&constructor_ref);

        move_to(&object_signer, Rarity { item_rarity: armour_rarity });

        // Initialize the property map.
        let properties = property_map::prepare_input(vector[], vector[], vector[]);
        property_map::init(&constructor_ref, properties);
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(RARITY_PROPERTY_NAME),
            armour_rarity
        );
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(ITEM_COST_PROPERTY_NAME),
            cost
        );
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(ITEM_NAME_PROPERTY),
            name
        );

        // Creates the fungible asset.
        primary_fungible_store::create_primary_store_enabled_fungible_asset(
            &constructor_ref,
            option::none(),
            fungible_asset_name,
            fungible_asset_symbol,
            0,
            icon_uri,
            project_uri,
        );
        let fungible_asset_mint_ref = fungible_asset::generate_mint_ref(&constructor_ref);

        // Publishes the armourToken resource 
        let armour_token = ArmourToken {
            armour_name: fungible_asset_name,
            cost: cost,
            property_mutator_ref: property_mutator_ref,
            fungible_asset_mint_ref: fungible_asset_mint_ref,
        };
        move_to(&object_signer, armour_token);
    }

    /// Creates the trinket token as fungible token.
    fun create_trinket_token_as_fungible_token(
        creator: &signer,
        description: String,
        name: String,
        uri: String,
        fungible_asset_name: String,
        fungible_asset_symbol: String,
        icon_uri: String,
        project_uri: String,
        trinket_rarity: u64,
        cost: u64,
    ) {
        let collection = string::utf8(OVERMIND_PLAYERS_TRINKET_COLLECTION);
        let constructor_ref = token::create_named_token(
            creator,
            collection,
            description,
            name,
            option::none(),
            uri,
        );


        let object_signer = object::generate_signer(&constructor_ref);
        let property_mutator_ref = property_map::generate_mutator_ref(&constructor_ref);

        move_to(&object_signer, Rarity { item_rarity: trinket_rarity });

        // Initialize the property map.
        let properties = property_map::prepare_input(vector[], vector[], vector[]);
        property_map::init(&constructor_ref, properties);
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(RARITY_PROPERTY_NAME),
            trinket_rarity
        );
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(ITEM_COST_PROPERTY_NAME),
            cost
        );
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(ITEM_NAME_PROPERTY),
            name
        );

        // Creates the fungible asset.
        primary_fungible_store::create_primary_store_enabled_fungible_asset(
            &constructor_ref,
            option::none(),
            fungible_asset_name,
            fungible_asset_symbol,
            0,
            icon_uri,
            project_uri,
        );
        let fungible_asset_mint_ref = fungible_asset::generate_mint_ref(&constructor_ref);
        // Publishes the TrinketToken resource with the refs.
        let trinket_token = TrinketToken {
            trinket_name: fungible_asset_name,
            cost: cost,
            property_mutator_ref: property_mutator_ref,
            fungible_asset_mint_ref: fungible_asset_mint_ref,
        };
        move_to(&object_signer, trinket_token);
    }                                                                             

    //==============================================================================================
    // Collection & Fungible Token Creation Functions - One shots
    //==============================================================================================

    fun create_weapon(creator: &signer) {
        create_weapon_collection(creator);

        // TODO: Draw the images - they can all be astley for now
        create_weapon_token_as_fungible_token(
            creator,
            string::utf8(b"Dagger Token Description"),
            string::utf8(DAGGER_TOKEN_NAME),
            string::utf8(b"https://raw.githubusercontent.com/Koeding/overminder/main/sources/metadata/weapons/dagger.json?token=GHSAT0AAAAAACHCG532TSFADEMEKON2XXVCZINQ54Q"),
            string::utf8(b"Dagger"),
            string::utf8(b"DAGGR"),
            string::utf8(b"OVERMIND_PLAYERS_WEAPON_COLLECTION_URI"),
            string::utf8(b"https://www.giantfreakinrobot.com/wp-content/uploads/2022/08/rick-astley-1200x675.jpg"),
            2,
            15,
        );
        create_weapon_token_as_fungible_token(
            creator,
            string::utf8(b"Broadsword Token Description"),
            string::utf8(BROADSWORD_TOKEN_NAME),
            string::utf8(b"https://raw.githubusercontent.com/Koeding/overminder/main/sources/metadata/weapons/broadsword.json?token=GHSAT0AAAAAACHCG533GWZAFH2EVBFGV25GZINQ6WA"),
            string::utf8(b"Broadsword"),
            string::utf8(b"BSWORD"),
            string::utf8(b"OVERMIND_PLAYERS_WEAPON_COLLECTION_URI"),
            string::utf8(b"https://www.giantfreakinrobot.com/wp-content/uploads/2022/08/rick-astley-1200x675.jpg"),
            5,
            20,
        );
        create_weapon_token_as_fungible_token(
            creator,
            string::utf8(b"Staff Token Description"),
            string::utf8(STAFF_TOKEN_NAME),
            string::utf8(b"https://raw.githubusercontent.com/Koeding/overminder/main/sources/metadata/weapons/staff.json?token=GHSAT0AAAAAACHCG5323QDYXBCVBQXF5GHUZINRAYA"),
            string::utf8(b"Staff"),
            string::utf8(b"STAFF"),
            string::utf8(b"OVERMIND_PLAYERS_WEAPON_COLLECTION_URI"),
            string::utf8(b"https://www.giantfreakinrobot.com/wp-content/uploads/2022/08/rick-astley-1200x675.jpg"),
            5,
            20,
        );
        create_weapon_token_as_fungible_token(
            creator,
            string::utf8(b"Wizards' Staff Token Description"),
            string::utf8(WIZARDS_STAFF_TOKEN_NAME),
            string::utf8(b"https://raw.githubusercontent.com/Koeding/overminder/main/sources/metadata/weapons/wizards_staff.json?token=GHSAT0AAAAAACHCG533RAB7LL7ZWI6ZRPRGZINRBMQ"),
            string::utf8(b"Wizards' Staff"),
            string::utf8(b"WSTAFF"),
            string::utf8(b"OVERMIND_PLAYERS_WEAPON_COLLECTION_URI"),
            string::utf8(b"https://www.giantfreakinrobot.com/wp-content/uploads/2022/08/rick-astley-1200x675.jpg"),
            10,
            35,
        );
        create_weapon_token_as_fungible_token(
            creator,
            string::utf8(b"Greatsword Token Description"),
            string::utf8(GREATSWORD_TOKEN_NAME),
            string::utf8(b"https://raw.githubusercontent.com/Koeding/overminder/main/sources/metadata/weapons/greatsword.json?token=GHSAT0AAAAAACHCG532AAKQ2JVP27BCTHUYZINRB4A"),
            string::utf8(b"Greatsword"),
            string::utf8(b"GSWORD"),
            string::utf8(b"OVERMIND_PLAYERS_WEAPON_COLLECTION_URI"),
            string::utf8(b"https://www.giantfreakinrobot.com/wp-content/uploads/2022/08/rick-astley-1200x675.jpg"),
            10,
            35,
        );
        create_weapon_token_as_fungible_token(
            creator,
            string::utf8(b"Pistol Token Description"),
            string::utf8(PISTOL_TOKEN_NAME),
            string::utf8(b"https://raw.githubusercontent.com/Koeding/overminder/main/sources/metadata/weapons/pistol.json?token=GHSAT0AAAAAACHCG532XG5U2YOAS6RMBYBYZINRCLQ"),
            string::utf8(b"Pistol"),
            string::utf8(b"PISTOL"),
            string::utf8(b"OVERMIND_PLAYERS_WEAPON_COLLECTION_URI"),
            string::utf8(b"https://www.giantfreakinrobot.com/wp-content/uploads/2022/08/rick-astley-1200x675.jpg"),
            20,
            70,
        );
        create_weapon_token_as_fungible_token(
            creator,
            string::utf8(b"PEW PEW PEW!"),
            string::utf8(LASER_PISTOL_TOKEN_NAME),
            string::utf8(b"https://raw.githubusercontent.com/Koeding/overminder/main/sources/metadata/weapons/laser_pistol.json?token=GHSAT0AAAAAACHCG533EOIRS6XO3AC7SBX4ZINRAPA"),
            string::utf8(b"Laser Pistol"),
            string::utf8(b"LASER"),
            string::utf8(b"OVERMIND_PLAYERS_WEAPON_COLLECTION_URI"),
            string::utf8(b"https://www.giantfreakinrobot.com/wp-content/uploads/2022/08/rick-astley-1200x675.jpg"),
            40,
            140,
        );
    }

    fun create_armour(creator: &signer) {
        create_armour_collection(creator);

        // TODO: Draw the images - they can all be astley for now
        create_armour_token_as_fungible_token(
            creator,
            string::utf8(b"Shirt Token Description"),
            string::utf8(SHIRT_TOKEN_NAME),
            string::utf8(b"https://raw.githubusercontent.com/Koeding/overminder/main/sources/metadata/armour/shirt.json?token=GHSAT0AAAAAACHCG532TY6GUN4WIKMCN63OZINRJTQ"),
            string::utf8(b"Shirt"),
            string::utf8(b"SHIRT"),
            string::utf8(b"OVERMIND_PLAYERS_ARMOUR_COLLECTION_URI"),
            string::utf8(b"https://www.giantfreakinrobot.com/wp-content/uploads/2022/08/rick-astley-1200x675.jpg"),
            2,
            15,
        );
        create_armour_token_as_fungible_token(
            creator,
            string::utf8(b"Cloak Token Description"),
            string::utf8(CLOAK_TOKEN_NAME),
            string::utf8(b"https://raw.githubusercontent.com/Koeding/overminder/main/sources/metadata/armour/cloak.json?token=GHSAT0AAAAAACHCG5326KS2BHKRLWY3QNPIZINRI5A"),
            string::utf8(b"Cloak"),
            string::utf8(b"CLOAK"),
            string::utf8(b"OVERMIND_PLAYERS_ARMOUR_COLLECTION_URI"),
            string::utf8(b"https://www.giantfreakinrobot.com/wp-content/uploads/2022/08/rick-astley-1200x675.jpg"),
            5,
            20,
        );
        create_armour_token_as_fungible_token(
            creator,
            string::utf8(b"Wizards' Cloak Token Description"),
            string::utf8(WIZARDS_CLOAK_TOKEN_NAME),
            string::utf8(b"https://raw.githubusercontent.com/Koeding/overminder/main/sources/metadata/armour/wizards_cloak.json?token=GHSAT0AAAAAACHCG533BI2N7SLHATJ6TQ2MZINRJ4Q"),
            string::utf8(b"Wizards' Cloak"),
            string::utf8(b"WCLOAK"),
            string::utf8(b"OVERMIND_PLAYERS_ARMOUR_COLLECTION_URI"),
            string::utf8(b"https://www.giantfreakinrobot.com/wp-content/uploads/2022/08/rick-astley-1200x675.jpg"),
            5,
            20,
        );
        create_armour_token_as_fungible_token(
            creator,
            string::utf8(b"Chainmail Token Description"),
            string::utf8(CHAINMAIL_TOKEN_NAME),
            string::utf8(b"https://raw.githubusercontent.com/Koeding/overminder/main/sources/metadata/armour/chainmail.json?token=GHSAT0AAAAAACHCG533CUFGMDRPUBGYTJ6IZINRKHA"),
            string::utf8(b"Chainmail"),
            string::utf8(b"CMAIL"),
            string::utf8(b"OVERMIND_PLAYERS_ARMOUR_COLLECTION_URI"),
            string::utf8(b"https://www.giantfreakinrobot.com/wp-content/uploads/2022/08/rick-astley-1200x675.jpg"),
            10,
            35,
        );
        create_armour_token_as_fungible_token(
            creator,
            string::utf8(b"Knights' Armour Token Description"),
            string::utf8(KNIGHTS_ARMOUR_TOKEN_NAME),
            string::utf8(b"https://raw.githubusercontent.com/Koeding/overminder/main/sources/metadata/armour/knights_armour.json?token=GHSAT0AAAAAACHCG533RPX7RKD47LIKPM6AZINRKOQ"),
            string::utf8(b"Knights' Armour"),
            string::utf8(b"KARMOUR"),
            string::utf8(b"OVERMIND_PLAYERS_ARMOUR_COLLECTION_URI"),
            string::utf8(b"https://www.giantfreakinrobot.com/wp-content/uploads/2022/08/rick-astley-1200x675.jpg"),
            10,
            35,
        );
        create_armour_token_as_fungible_token(
            creator,
            string::utf8(b"Tuxedo Token Description"),
            string::utf8(TUXEDO_TOKEN_NAME),
            string::utf8(b"https://raw.githubusercontent.com/Koeding/overminder/main/sources/metadata/armour/tuxedo.json?token=GHSAT0AAAAAACHCG53335LYHPEIBKCKBLTKZINRK5Q"),
            string::utf8(b"Tuxedo"),
            string::utf8(b"TUX"),
            string::utf8(b"OVERMIND_PLAYERS_ARMOUR_COLLECTION_URI"),
            string::utf8(b"https://www.giantfreakinrobot.com/wp-content/uploads/2022/08/rick-astley-1200x675.jpg"),
            20,
            70,
        );
        create_armour_token_as_fungible_token(
            creator,
            string::utf8(b"SHINY AF!"),
            string::utf8(GOLDEN_AMOUR_TOKEN_NAME),
            string::utf8(b"https://raw.githubusercontent.com/Koeding/overminder/main/sources/metadata/armour/golden_armour.json?token=GHSAT0AAAAAACHCG5336YZXLUIHL6UUR2NUZINRK6Q"),
            string::utf8(b"Golden Armour"),
            string::utf8(b"GARMOUR"),
            string::utf8(b"OVERMIND_PLAYERS_ARMOUR_COLLECTION_URI"),
            string::utf8(b"https://www.giantfreakinrobot.com/wp-content/uploads/2022/08/rick-astley-1200x675.jpg"),
            40,
            140,
        );
    }

    fun create_trinket(creator: &signer) {
        create_trinket_collection(creator);

        // TODO: Draw the images - they can all be astley for now
        create_trinket_token_as_fungible_token(
            creator,
            string::utf8(b"Chain Token Description"),
            string::utf8(CHAIN_TOKEN_NAME),
            string::utf8(b"https://raw.githubusercontent.com/Koeding/overminder/main/sources/metadata/trinkets/chain.json?token=GHSAT0AAAAAACHCG5322MRVN7KYHINZI3LSZINQTTQ"),
            string::utf8(b"Chain"),
            string::utf8(b"CHAIN"),
            string::utf8(b"OVERMIND_PLAYERS_TRINKET_COLLECTION_URI"),
            string::utf8(b"https://www.giantfreakinrobot.com/wp-content/uploads/2022/08/rick-astley-1200x675.jpg"),
            2,
            15,
        );
        create_trinket_token_as_fungible_token(
            creator,
            string::utf8(b"Pendant Token Description"),
            string::utf8(PENDANT_TOKEN_NAME),
            string::utf8(b"https://raw.githubusercontent.com/Koeding/overminder/main/sources/metadata/trinkets/pendant.json?token=GHSAT0AAAAAACHCG532RZ6AH3PFFQLTZMMEZINQU2Q"),
            string::utf8(b"Pendant"),
            string::utf8(b"PNDNT"),
            string::utf8(b"OVERMIND_PLAYERS_TRINKET_COLLECTION_URI"),
            string::utf8(b"https://www.giantfreakinrobot.com/wp-content/uploads/2022/08/rick-astley-1200x675.jpg"),
            5,
            20,
        );
        create_trinket_token_as_fungible_token(
            creator,
            string::utf8(b"Baseball Cap Token Description"),
            string::utf8(BASEBALL_CAP_TOKEN_NAME),
            string::utf8(b"https://raw.githubusercontent.com/Koeding/overminder/main/sources/metadata/trinkets/baseball_cap.json?token=GHSAT0AAAAAACHCG533MSOOHG4DCPX7TLR6ZINQWUQ"),
            string::utf8(b"Baseball Cap"),
            string::utf8(b"CAP"),
            string::utf8(b"OVERMIND_PLAYERS_TRINKET_COLLECTION_URI"),
            string::utf8(b"https://www.giantfreakinrobot.com/wp-content/uploads/2022/08/rick-astley-1200x675.jpg"),
            5,
            20,
        );
        create_trinket_token_as_fungible_token(
            creator,
            string::utf8(b"Wizards' Hat Token Description"),
            string::utf8(WIZARDS_HAT_TOKEN_NAME),
            string::utf8(b"https://raw.githubusercontent.com/Koeding/overminder/main/sources/metadata/trinkets/wizards_hat.json?token=GHSAT0AAAAAACHCG532WHFW6BA63BL2EV44ZINQXLQ"),
            string::utf8(b"Wizards' Hat"),
            string::utf8(b"WIZHAT"),
            string::utf8(b"OVERMIND_PLAYERS_TRINKET_COLLECTION_URI"),
            string::utf8(b"https://www.giantfreakinrobot.com/wp-content/uploads/2022/08/rick-astley-1200x675.jpg"),
            10,
            35,
        );
        create_trinket_token_as_fungible_token(
            creator,
            string::utf8(b"Helmet Token Description"),
            string::utf8(HELMET_TOKEN_NAME),
            string::utf8(b"https://raw.githubusercontent.com/Koeding/overminder/main/sources/metadata/trinkets/helmet.json?token=GHSAT0AAAAAACHCG5327ROFLQ5L3PBRC2NWZINQY3A"),
            string::utf8(b"Helmet"),
            string::utf8(b"HELMET"),
            string::utf8(b"OVERMIND_PLAYERS_TRINKET_COLLECTION_URI"),
            string::utf8(b"https://www.giantfreakinrobot.com/wp-content/uploads/2022/08/rick-astley-1200x675.jpg"),
            10,
            35,
        );
        create_trinket_token_as_fungible_token(
            creator,
            string::utf8(b"Crown Token Description"),
            string::utf8(CROWN_TOKEN_NAME),
            string::utf8(b"https://raw.githubusercontent.com/Koeding/overminder/main/sources/metadata/trinkets/crown.json?token=GHSAT0AAAAAACHCG5323OV54GM3BTHZPUKKZINQZQA"),
            string::utf8(b"Crown"),
            string::utf8(b"CROWN"),
            string::utf8(b"OVERMIND_PLAYERS_TRINKET_COLLECTION_URI"),
            string::utf8(b"https://www.giantfreakinrobot.com/wp-content/uploads/2022/08/rick-astley-1200x675.jpg"),
            20,
            70,
        );
        create_trinket_token_as_fungible_token(
            creator,
            string::utf8(b"Halo Token Description"),
            string::utf8(HALO_TOKEN_NAME),
            string::utf8(b"https://raw.githubusercontent.com/Koeding/overminder/main/sources/metadata/trinkets/halo.json?token=GHSAT0AAAAAACHCG532W76OQHVFZKVSU322ZINQZ5A"),
            string::utf8(b"Halo"),
            string::utf8(b"HALO"),
            string::utf8(b"OVERMIND_PLAYERS_TRINKET_COLLECTION_URI"),
            string::utf8(b"https://www.giantfreakinrobot.com/wp-content/uploads/2022/08/rick-astley-1200x675.jpg"),
            40,
            140,
        );
    }

    

    //==============================================================================================
    // View Functions
    //==============================================================================================

    #[view]
    /// Returns the Character token of the owner
    fun view_character(player_address: address, player_name: String): Character acquires Character {
        let character_address = token::create_token_address(
            &player_address, 
            &string::utf8(OVERMIND_PLAYERS_NFT_COLLECTION), 
            &player_name
        );
        move_from<Character>(character_address)
    }

    #[view]
    /// Returns the current weapon token of the owner
    public fun current_weapon(_owner_addr: address, weapon: Object<WeaponToken>): String {
        let metadata = object::convert<WeaponToken, Metadata>(weapon);
        fungible_asset::name(metadata)
    }

    #[view]
    /// Returns the trinket token address by name
    public fun weapon_token_address(creator: address, weapon_token_name: String): address {
        token::create_token_address(&creator, &string::utf8(OVERMIND_PLAYERS_WEAPON_COLLECTION), &weapon_token_name)
    }

    #[view]
    /// Returns the dagger token address
    public fun dagger_token_address(creator: address): address {
        weapon_token_address(creator, string::utf8(DAGGER_TOKEN_NAME))
    }
    
    #[view]
    /// Returns the broadsword token address
    public fun broadsword_token_address(creator: address): address {
        weapon_token_address(creator, string::utf8(BROADSWORD_TOKEN_NAME))
    }

    #[view]
    /// Returns the staff token address
    public fun staff_token_address(creator: address): address {
        weapon_token_address(creator, string::utf8(STAFF_TOKEN_NAME))
    }

    #[view]
    /// Returns the wizards' staff token address
    public fun wizards_staff_token_address(creator: address): address {
        weapon_token_address(creator, string::utf8(WIZARDS_STAFF_TOKEN_NAME))
    }
    #[view]

    /// Returns the greatsword token address
    public fun greatsword_token_address(creator: address): address {
        weapon_token_address(creator, string::utf8(GREATSWORD_TOKEN_NAME))
    }

    #[view]
    /// Returns the pistol token address
    public fun pistol_token_address(creator: address): address {
        weapon_token_address(creator, string::utf8(PISTOL_TOKEN_NAME))
    }

    #[view]
    /// Returns the laser pistol token address
    public fun laser_pistol_token_address(creator: address): address {
        weapon_token_address(creator, string::utf8(LASER_PISTOL_TOKEN_NAME))
    }
    
    #[view]
    /// Returns the current trinket token of the owner
    public fun current_trinket(_owner_addr: address, trinket: Object<TrinketToken>): String {
        let metadata = object::convert<TrinketToken, Metadata>(trinket);
        fungible_asset::name(metadata)
    }

    #[view]
    /// Returns the trinket token address by name
    public fun trinket_token_address(creator: address, trinket_token_name: String): address {
        token::create_token_address(&creator, &string::utf8(OVERMIND_PLAYERS_TRINKET_COLLECTION), &trinket_token_name)
    }

    #[view]
    /// Returns the chain token address
    public fun chain_token_address(creator: address): address {
        trinket_token_address(creator, string::utf8(CHAIN_TOKEN_NAME))
    }
    
    #[view]
    /// Returns the pendant token address
    public fun pendant_token_address(creator: address): address {
        trinket_token_address(creator, string::utf8(PENDANT_TOKEN_NAME))
    }
    #[view]
    /// Returns the baseball cap token address
    public fun baseball_cap_token_address(creator: address): address {
        trinket_token_address(creator, string::utf8(BASEBALL_CAP_TOKEN_NAME))
    }

    #[view]
    /// Returns the wizards' hat token address
    public fun wizards_hat_token_address(creator: address): address {
        trinket_token_address(creator, string::utf8(WIZARDS_HAT_TOKEN_NAME))
    }
    #[view]
    /// Returns the helmet token address
    public fun helmet_token_address(creator: address): address {
        trinket_token_address(creator, string::utf8(HELMET_TOKEN_NAME))
    }

    #[view]
    /// Returns the crown token address
    public fun crown_token_address(creator: address): address {
        trinket_token_address(creator, string::utf8(CROWN_TOKEN_NAME))
    }

    #[view]
    /// Returns the halo token address
    public fun halo_token_address(creator: address): address {
        trinket_token_address(creator, string::utf8(HALO_TOKEN_NAME))
    }

    #[view]
    /// Returns the current armour token of the owner
    public fun current_armour(_owner_addr: address, armour: Object<ArmourToken>): String {
        let metadata = object::convert<ArmourToken, Metadata>(armour);
        fungible_asset::name(metadata)
    }

    #[view]
    /// Returns the armour token address by name
    public fun armour_token_address(creator: address, weapon_token_name: String): address {
        token::create_token_address(&creator, &string::utf8(OVERMIND_PLAYERS_ARMOUR_COLLECTION), &weapon_token_name)
    }

    #[view]
    /// Returns the shirt token address
    public fun shirt_token_address(creator: address): address {
        armour_token_address(creator, string::utf8(SHIRT_TOKEN_NAME))
    }
    
    #[view]
    /// Returns the cloak token address
    public fun cloak_token_address(creator: address): address {
        armour_token_address(creator, string::utf8(CLOAK_TOKEN_NAME))
    }
    #[view]
    /// Returns the wizards' cloak token address
    public fun wizards_cloak_token_address(creator: address): address {
        armour_token_address(creator, string::utf8(WIZARDS_CLOAK_TOKEN_NAME))
    }

    #[view]
    /// Returns the chainmail token address
    public fun chainmail_token_address(creator: address): address {
        armour_token_address(creator, string::utf8(CHAINMAIL_TOKEN_NAME))
    }
    #[view]
    /// Returns the knights' armour token address
    public fun knights_armour_token_address(creator: address): address {
        armour_token_address(creator, string::utf8(KNIGHTS_ARMOUR_TOKEN_NAME))
    }

    #[view]
    /// Returns the shirt token address
    public fun tuxedo_token_address(creator: address): address {
        armour_token_address(creator, string::utf8(TUXEDO_TOKEN_NAME))
    }

    #[view]
    /// Returns the shirt token address
    public fun golden_armour_token_address(creator: address): address {
        armour_token_address(creator, string::utf8(GOLDEN_AMOUR_TOKEN_NAME))
    }

    //==============================================================================================
    // Validation functions
    //==============================================================================================

    inline fun is_moderator(moderator: address): bool {
        let resource_addr = account::create_resource_address(&@character, SEED);
        let state = borrow_global<State>(resource_addr);
        vector::contains(&state.moderators, &moderator)
    }

    inline fun get_character(creator: &address, name: &String): (Object<Character>, &Character) {
        let character_address = token::create_token_address(
            creator,
            &string::utf8(OVERMIND_PLAYERS_NFT_COLLECTION),
            name,
        );
        (object::address_to_object<Character>(character_address), borrow_global<Character>(character_address))
    }

    //==============================================================================================
    // Tests 
    //==============================================================================================

    
    #[test(admin = @character, user1 = @0x456, aptos_framework = @0x1)]
    public fun test_create_armour(admin: &signer, user1: &signer, aptos_framework: &signer) acquires ArmourToken {
        let admin_address = signer::address_of(admin);
        let user1_address = signer::address_of(user1);

        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(aptos_framework);

        account::create_account_for_test(admin_address);
        account::create_account_for_test(user1_address);

        coin::register<AptosCoin>(admin);
        coin::register<AptosCoin>(user1);

        let coins = coin::mint((100 as u64), &mint_cap);
        coin::deposit(user1_address, coins);

        create_armour(admin);
        mint_armour(admin, user1, string::utf8(SHIRT_TOKEN_NAME), (15 as u64));

        let shirt_token = object::address_to_object<ArmourToken>(shirt_token_address(admin_address));
        debug::print(&current_armour(user1_address, shirt_token));

        let expected_name: vector<u8> = b"Shirt";

        assert!(current_armour(user1_address, shirt_token) == string::utf8(expected_name), 0);

        assert!(coin::balance<AptosCoin>(admin_address) == (15 as u64), 1); 
        assert!(coin::balance<AptosCoin>(user1_address) == (85 as u64), 2);
        
        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);
    }

    #[test(admin = @character, user1 = @0x456, aptos_framework = @0x1)]
    public fun test_create_weapons(admin: &signer, user1: &signer, aptos_framework: &signer) acquires WeaponToken {
        let admin_address = signer::address_of(admin);
        let user1_address = signer::address_of(user1);

        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(aptos_framework);

        account::create_account_for_test(admin_address);
        account::create_account_for_test(user1_address);

        coin::register<AptosCoin>(admin);
        coin::register<AptosCoin>(user1);

        let coins = coin::mint((100 as u64), &mint_cap);
        coin::deposit(user1_address, coins);

        create_weapon(admin);
        mint_weapon(admin, user1, string::utf8(DAGGER_TOKEN_NAME), (15 as u64));

        let dagger_token = object::address_to_object<WeaponToken>(dagger_token_address(admin_address));
        debug::print(&current_weapon(user1_address, dagger_token));

        let expected_name: vector<u8> = b"Dagger";

        assert!(current_weapon(user1_address, dagger_token) == string::utf8(expected_name), 0);

        assert!(coin::balance<AptosCoin>(admin_address) == (15 as u64), 1); 
        assert!(coin::balance<AptosCoin>(user1_address) == (85 as u64), 2);
        
        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);
    }

    #[test(admin = @character, user1 = @0x456, aptos_framework = @0x1)]
    public fun test_create_trinket(admin: &signer, user1: &signer, aptos_framework: &signer) acquires TrinketToken {
        let admin_address = signer::address_of(admin);
        let user1_address = signer::address_of(user1);

        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(aptos_framework);

        account::create_account_for_test(admin_address);
        account::create_account_for_test(user1_address);

        coin::register<AptosCoin>(admin);
        coin::register<AptosCoin>(user1);

        let coins = coin::mint((100 as u64), &mint_cap);
        coin::deposit(user1_address, coins);

        create_trinket(admin);
        mint_trinket(admin, user1, string::utf8(CHAIN_TOKEN_NAME), (15 as u64));

        let chain_token = object::address_to_object<TrinketToken>(chain_token_address(admin_address));

        let expected_name: vector<u8> = b"Chain";

        assert!(current_trinket(user1_address, chain_token) == string::utf8(expected_name), 0);

        assert!(coin::balance<AptosCoin>(admin_address) == (15 as u64), 1); 
        assert!(coin::balance<AptosCoin>(user1_address) == (85 as u64), 2);
        
        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);
    }

    #[test(admin = @character, user1 = @0x456, aptos_framework = @0x1)]
    public fun test_all_collection_and_fa_creation(admin: &signer, user1: &signer, aptos_framework: &signer) acquires State, Character, ArmourToken, WeaponToken, TrinketToken {
        let admin_address = signer::address_of(admin);
        let user1_address = signer::address_of(user1);

        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(aptos_framework);

        account::create_account_for_test(admin_address);
        account::create_account_for_test(user1_address);

        coin::register<AptosCoin>(admin);
        coin::register<AptosCoin>(user1);

        let coins = coin::mint((100 as u64), &mint_cap);
        coin::deposit(user1_address, coins);

        init_module(admin);

        let resource = account::create_resource_address(&admin_address, SEED);
        let state = borrow_global<State>(resource);
        let resource_signer = account::create_signer_with_capability(&state.resource_signer_capability);

        let expected_gender = string::utf8(b"gender");
        let expected_name = string::utf8(b"name");
        let expected_description = string::utf8(b"description");
        let expected_uri = string::utf8(b"uri");

        mint_character(&resource_signer, 
        user1_address,
        expected_gender,    
        expected_name,  
        expected_description,   
        expected_uri,   
        );

        mint_armour(&resource_signer, user1, string::utf8(SHIRT_TOKEN_NAME), (15 as u64));
        mint_trinket(&resource_signer, user1, string::utf8(CHAIN_TOKEN_NAME), (15 as u64));
        mint_weapon(&resource_signer, user1, string::utf8(DAGGER_TOKEN_NAME), (15 as u64));

        let shirt_token = object::address_to_object<ArmourToken>(shirt_token_address(resource));
        let dagger_token = object::address_to_object<WeaponToken>(dagger_token_address(resource));
        let chain_token = object::address_to_object<TrinketToken>(chain_token_address(resource));

        let expected_armour_name: vector<u8> = b"Shirt";
        let expected_weapon_name: vector<u8> = b"Dagger";
        let expected_trinket_name: vector<u8> = b"Chain";

        let character_address = token::create_token_address(
            &resource,
            &string::utf8(OVERMIND_PLAYERS_NFT_COLLECTION),
            &expected_name,
        );

        equip_armour(&resource_signer, object::address_to_object<Character>(character_address), shirt_token);
        equip_trinket(&resource_signer, object::address_to_object<Character>(character_address), chain_token);
        equip_weapon(&resource_signer, object::address_to_object<Character>(character_address), dagger_token);
        
        let character = view_character(resource, expected_name);
        
        
        debug::print(&character.armour);
        debug::print(&property_map::read_string(&option::extract(&mut character.armour), &string::utf8(b"Item Name")));
        debug::print(&character.trinket);
        debug::print(&property_map::read_string(&option::extract(&mut character.trinket), &string::utf8(b"Item Name")));
        debug::print(&character.weapon);
        debug::print(&property_map::read_string(&option::extract(&mut character.weapon), &string::utf8(b"Item Name")));

        assert!(current_armour(user1_address, shirt_token) == string::utf8(expected_armour_name), 0);
        assert!(current_weapon(user1_address, dagger_token) == string::utf8(expected_weapon_name), 0);
        assert!(current_trinket(user1_address, chain_token) == string::utf8(expected_trinket_name), 0);

        move_to<Character>(user1, character);
        assert!(coin::balance<AptosCoin>(resource) == (45 as u64), 1); 
        assert!(coin::balance<AptosCoin>(user1_address) == (55 as u64), 2);
        
        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);
    }
}