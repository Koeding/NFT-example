module overminders::overminders {
    use std::option;
    use std::signer;
    use std::string::{Self, String};
    use aptos_framework::account::{Self};
    use aptos_framework::aptos_coin::{AptosCoin};
    use aptos_framework::coin;
    use aptos_framework::event::{Self, EventHandle};
    use aptos_framework::fungible_asset::{Self, Metadata};
    use aptos_framework::object::{Self, Object};
    use aptos_framework::primary_fungible_store;
    use aptos_token_objects::collection;
    use aptos_token_objects::property_map::{Self};
    use aptos_token_objects::token;

    #[test_only]
    use aptos_framework::account::{Account};
    #[test_only]
    use aptos_framework::aptos_coin::{Self};
    #[test_only]
    use std::debug;

    /// Error codes
    const ECHARACTER_EXISTS: u64 = 0;
    const ENOT_ENOUGH_FUNDS: u64 = 1;
    const ETOKEN_DOES_NOT_EXIST: u64 = 2;
    const ENOT_CREATOR: u64 = 3;

    /// Character collection constants
    const OVERMIND_PLAYERS_NFT_COLLECTION: vector<u8> = b"Overminders";
    const OVERMIND_PLAYERS_NFT_DESCRIPTION: vector<u8> = b"An Overmind Adventurer";
    const OVERMIND_PLAYERS_NFT_COLLECTION_URI: vector<u8> = b"https://www.giantfreakinrobot.com/wp-content/uploads/2022/08/rick-astley-1200x675.jpg";

    /// Character token constants
    const OVERMIND_MALE_CHARACTER_BASE_URI: vector<u8> = b"https://www.giantfreakinrobot.com/wp-content/uploads/2022/08/rick-astley-1200x675.jpg";
    const OVERMIND_FEMALE_CHARACTER_BASE_URI: vector<u8> = b"https://www.giantfreakinrobot.com/wp-content/uploads/2022/08/rick-astley-1200x675.jpg";

    // Property names
    const STATUS_PROPERTY_NAME: vector<u8> = b"Status";
    const STAMINA_PROPERTY_NAME: vector<u8> = b"Stamina";
    const AGILITY_PROPERTY_NAME: vector<u8> = b"Agility";
    const INTELLECT_PROPERTY_NAME: vector<u8> = b"Intellect";
    const STAMINA_INCREASE_PROPERTY_NAME: vector<u8> = b"Stamina Increase";
    const INTELLECT_INCREASE_PROPERTY_NAME: vector<u8> = b"Intellect Increase";
    const AGILITY_INCREASE_PROPERTY_NAME: vector<u8> = b"Agility Increase";
    const ARMOUR_PROPERTY_NAME: vector<u8> = b"Armour";
    const WEAPON_PROPERTY_NAME: vector<u8> = b"Weapon";
    const TRINKET_PROPERTY_NAME: vector<u8> = b"Trinket";
    const ITEM_COST_PROPERTY_NAME: vector<u8> = b"Item Cost";
    const ITEM_NAME_PROPERTY: vector<u8> = b"Item Name";
    
    /// Character status
    const OVERMINERS_STATUS_TITLE_TIER_1_MALE: vector<u8> = b"Emperor";
    const OVERMINERS_STATUS_TITLE_TIER_1_FEMALE: vector<u8> = b"Empress";
    const OVERMINERS_STATUS_TITLE_TIER_2_MALE: vector<u8> = b"King";
    const OVERMINERS_STATUS_TITLE_TIER_2_FEMALE: vector<u8> = b"Queen ";
    const OVERMINERS_STATUS_TITLE_TIER_3_MALE: vector<u8> = b"Prince";
    const OVERMINERS_STATUS_TITLE_TIER_3_FEMALE: vector<u8> = b"Princess";
    const OVERMINERS_STATUS_TITLE_TIER_4_MALE: vector<u8> = b"Duke";
    const OVERMINERS_STATUS_TITLE_TIER_4_FEMALE: vector<u8> = b"Duchess";
    const OVERMINERS_STATUS_TITLE_TIER_5_MALE: vector<u8> = b"Baron";
    const OVERMINERS_STATUS_TITLE_TIER_5_FEMALE: vector<u8> = b"Baroness";
    const OVERMINERS_STATUS_TITLE_TIER_6: vector<u8> = b"Commoner";

    /// Armour collection constants
    const OVERMIND_PLAYERS_ARMOUR_COLLECTION: vector<u8> = b"Armour";
    const OVERMIND_PLAYERS_ARMOUR_DESCRIPTION: vector<u8> = b"Character Armour";
    const OVERMIND_PLAYERS_ARMOUR_COLLECTION_URI: vector<u8> = b"https://www.giantfreakinrobot.com/wp-content/uploads/2022/08/rick-astley-1200x675.jpg";

    /// Armour token names
    const SHIRT_TOKEN_NAME: vector<u8> = b"Shirt Token";
    const CLOAK_TOKEN_NAME: vector<u8> = b"Cloak Token";
    const WIZARDS_CLOAK_TOKEN_NAME: vector<u8> = b"Wizards' Cloak Token";
    const CHAINMAIL_TOKEN_NAME: vector<u8> = b"Chainmail Token";
    const KNIGHTS_ARMOUR_TOKEN_NAME: vector<u8> = b"Knights' Armour Token";
    const TUXEDO_TOKEN_NAME: vector<u8> = b"Tuxedo Token";
    const GOLDEN_AMOUR_TOKEN_NAME: vector<u8> = b"Golden Armour Token";

    /// Trinket collection constants
    const OVERMIND_PLAYERS_TRINKET_COLLECTION: vector<u8> = b"Trinket";
    const OVERMIND_PLAYERS_TRINKET_DESCRIPTION: vector<u8> = b"Character Trinket";
    const OVERMIND_PLAYERS_TRINKET_COLLECTION_URI: vector<u8> = b"https://www.giantfreakinrobot.com/wp-content/uploads/2022/08/rick-astley-1200x675.jpg";

    /// Trinket token names
    const CHAIN_TOKEN_NAME: vector<u8> = b"Chain Token";
    const PENDANT_TOKEN_NAME: vector<u8> = b"Pendant Token";
    const BASEBALL_CAP_TOKEN_NAME: vector<u8> = b"Baseball Cap Token";
    const WIZARDS_HAT_TOKEN_NAME: vector<u8> = b"Wizards' Hat Token";
    const HELMET_TOKEN_NAME: vector<u8> = b"Helmet Token";
    const CROWN_TOKEN_NAME: vector<u8> = b"Crown Token";
    const HALO_TOKEN_NAME: vector<u8> = b"Halo Token";

    /// Weapon collection constants
    const OVERMIND_PLAYERS_WEAPON_COLLECTION: vector<u8> = b"Weapons";
    const OVERMIND_PLAYERS_WEAPON_DESCRIPTION: vector<u8> = b"Character Weapon";
    const OVERMIND_PLAYERS_WEAPON_COLLECTION_URI: vector<u8> = b"https://www.giantfreakinrobot.com/wp-content/uploads/2022/08/rick-astley-1200x675.jpg";

    /// Weapon token names
    const DAGGER_TOKEN_NAME: vector<u8> = b"Dagger Token";
    const BROADSWORD_TOKEN_NAME: vector<u8> = b"Broadsword Token";
    const STAFF_TOKEN_NAME: vector<u8> = b"Staff Token";
    const WIZARDS_STAFF_TOKEN_NAME: vector<u8> = b"Wizards' Staff Token";
    const GREATSWORD_TOKEN_NAME: vector<u8> = b"Greatsword Token";
    const PISTOL_TOKEN_NAME: vector<u8> = b"Pistol Token";
    const LASER_PISTOL_TOKEN_NAME: vector<u8> = b"Laser Pistol Token";

    /// Seed for resource creation
    const SEED: vector<u8> = b"overminders";

    struct State has key {
        collection: String,
        moderators: vector<address>,
        players: vector<address>,
        resource_signer_capability: account::SignerCapability,  
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct ArmourToken has key {
        property_mutator_ref: property_map::MutatorRef,
        fungible_asset_mint_ref: fungible_asset::MintRef,
        fungible_asset_burn_ref: fungible_asset::BurnRef,
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct TrinketToken has key {
        property_mutator_ref: property_map::MutatorRef,
        fungible_asset_mint_ref: fungible_asset::MintRef,
        fungible_asset_burn_ref: fungible_asset::BurnRef,
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct WeaponToken has key {
        property_mutator_ref: property_map::MutatorRef,
        fungible_asset_mint_ref: fungible_asset::MintRef,
        fungible_asset_burn_ref: fungible_asset::BurnRef,
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    /// Armour increases stamina. Better armour items = more stamina.
    struct StaminaIncrease has key {
        value: u64,
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    /// Trinkets increase intellect. Better trinket items = more intel.
    struct IntellectIncrease has key {
        value: u64,
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    /// Weapons increase agility. Better weapons = more agility.
    struct AgilityIncrease has key {
        value: u64,
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    /// Character Token
    struct Character has key {
        name: String,
        gender: String,
        mutator_ref: token::MutatorRef,
        property_mutator_ref: property_map::MutatorRef,
        stamina_update_events: EventHandle<StaminaUpdateEvent>,
        agility_update_events: EventHandle<AgilityUpdateEvent>,
        intellect_update_events: EventHandle<IntellectUpdateEvent>,
        base_uri: String,
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    /// The characters's accumulated experience
    struct ExperiencePoints has key {
        value: u64,
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    /// The character's stamina
    struct Stamina has key {
        value: u64,
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    /// The characters's agility
    struct Agility has key {
        value: u64,
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    /// The characters's intellect
    struct Intellect has key {
        value: u64,
    }

    //==============================================================================================
    // Events
    //==============================================================================================
    
    struct StaminaUpdateEvent has store, drop {
        old_stamina: u64,
        new_stamina: u64,
        character_address: address,
    }

    struct AgilityUpdateEvent has store, drop {
        old_agility: u64,
        new_agility: u64,
        character_address: address,
    }

    struct IntellectUpdateEvent has store, drop {
        old_intellect: u64,
        new_intellect: u64,
        character_address: address,
    }

    struct TrinketCreationEvent has store, drop {
        trinket_name: String,
        player_address: address,
    }

    fun init_module(admin: &signer) {
        // create resource account
        let (resource_signer, signer_capability) = account::create_resource_account(admin, SEED);

        // publish state
        let state = State {
            collection: string::utf8(OVERMIND_PLAYERS_NFT_COLLECTION),
            moderators: vector[signer::address_of(admin), signer::address_of(&resource_signer)],
            players: vector[],
            resource_signer_capability: signer_capability,
        };
        move_to<State>(&resource_signer, state);

        coin::register<AptosCoin>(&resource_signer);
        
        create_character_collection(&resource_signer);
        init_armour_module(&resource_signer);
        init_trinket_module(&resource_signer);
        init_weapon_module(&resource_signer);
    }

    /*
     * @params: name - Players Overmind tag
     * @params: description - Character description
     * @notice: creates a Character nft, limit of one per account.
     */
    public entry fun create_character_for_player(
        player: &signer,
        description: String,
        name: String,
        gender: String,
    ) acquires State {
        if (object::owns<Character>(signer::address_of(player))) {
            ECHARACTER_EXISTS;
        };
        let resource = account::create_resource_address(&@overminders, SEED);
        let state = borrow_global<State>(resource);
        let res_sig = account::create_signer_with_capability(&state.resource_signer_capability);
        // Determine Gender & Create character
        let uri: String;
        if (gender == string::utf8(b"male")) {
            uri = string::utf8(OVERMIND_MALE_CHARACTER_BASE_URI);
        } else {
            uri = string::utf8(OVERMIND_FEMALE_CHARACTER_BASE_URI);
        };
        let constructor_ref = token::create_named_token(
            &res_sig,
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
        object::transfer_with_ref(linear_transfer_ref, signer::address_of(player));
        object::disable_ungated_transfer(&transfer_ref);

        move_to(&object_signer, Stamina { value: 1 });
        move_to(&object_signer, Agility { value: 1 });
        move_to(&object_signer, Intellect { value: 1 });

        let properties = property_map::prepare_input(vector[], vector[], vector[]);
        property_map::init(&constructor_ref, properties);
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(STATUS_PROPERTY_NAME),
            string::utf8(OVERMINERS_STATUS_TITLE_TIER_6),
        );
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(STAMINA_PROPERTY_NAME),
            1,
        );
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(AGILITY_PROPERTY_NAME),
            1,
        );
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(INTELLECT_PROPERTY_NAME),
            1,
        );
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(WEAPON_PROPERTY_NAME),
            string::utf8(b"unequipped"),
        );
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(ARMOUR_PROPERTY_NAME),
            string::utf8(b"unequipped"),
        );
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(TRINKET_PROPERTY_NAME),
            string::utf8(b"unequipped"),
        );

        move_to(&object_signer, Character {
            name: name,
            gender: gender,
            mutator_ref: token::generate_mutator_ref(&constructor_ref), 
            property_mutator_ref: property_mutator_ref,
            stamina_update_events: object::new_event_handle<StaminaUpdateEvent>(&object_signer),
            agility_update_events: object::new_event_handle<AgilityUpdateEvent>(&object_signer),
            intellect_update_events: object::new_event_handle<IntellectUpdateEvent>(&object_signer),
            base_uri: uri,
        });

    }

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

    public entry fun upgrade_armour(from: &signer, armour_token_name: String, character_name: String) acquires Stamina, Character, ArmourToken, StaminaIncrease {
        let character_address = token::create_token_address(
            &signer::address_of(from), 
            &string::utf8(OVERMIND_PLAYERS_NFT_COLLECTION), 
            &character_name
        );
        let character_obj = object::address_to_object<Character>(character_address);
        let armour_token = object::address_to_object<ArmourToken>(armour_token_address(armour_token_name));
        equip_armour(from, armour_token, character_obj);
    }

    public entry fun upgrade_weapon(from: &signer, weapon_token_name: String, character_name: String) acquires Agility, Character, WeaponToken, AgilityIncrease {
        let character_address = token::create_token_address(
            &signer::address_of(from), 
            &string::utf8(OVERMIND_PLAYERS_NFT_COLLECTION), 
            &character_name
        );
        let character_obj = object::address_to_object<Character>(character_address);
        let weapon_token = object::address_to_object<WeaponToken>(weapon_token_address(weapon_token_name));
        equip_weapon(from, weapon_token, character_obj);
    }

    public entry fun upgrade_trinket(from: &signer, trinket_token_name: String, character_name: String) acquires Intellect, Character, TrinketToken, IntellectIncrease {
        let character_address = token::create_token_address(
            &signer::address_of(from), 
            &string::utf8(OVERMIND_PLAYERS_NFT_COLLECTION), 
            &character_name
        );
        let character_obj = object::address_to_object<Character>(character_address);
        let trinket_token = object::address_to_object<TrinketToken>(trinket_token_address(trinket_token_name));
        equip_trinket(from, trinket_token, character_obj);
    }

    public entry fun equip_armour(from: &signer, armour: Object<ArmourToken>, to: Object<Character>) acquires Stamina, Character, ArmourToken, StaminaIncrease {
        burn_armour(from, armour);
        let stamina_boost = token_stamina_increase(armour);
        let character_address = object::object_address(&to);
        let stamina = borrow_global_mut<Stamina>(character_address);
        let new_stamina = stamina.value + stamina_boost;

        let character = borrow_global_mut<Character>(character_address);
        event::emit_event(&mut character.stamina_update_events, StaminaUpdateEvent {
            old_stamina: stamina.value,
            new_stamina: new_stamina,
            character_address: character_address,
        });

        property_map::update_typed(&character.property_mutator_ref, &string::utf8(STAMINA_PROPERTY_NAME), new_stamina);
        let metadata = object::convert<ArmourToken, Metadata>(armour);
        property_map::update_typed(&character.property_mutator_ref, &string::utf8(ARMOUR_PROPERTY_NAME), fungible_asset::name(metadata));
    }

    public entry fun equip_trinket(from: &signer, trinket: Object<TrinketToken>, to: Object<Character>) acquires Intellect, Character, TrinketToken, IntellectIncrease {
        burn_trinket(from, trinket);
        let intellect_boost = token_intellect_increase(trinket);
        let character_address = object::object_address(&to);
        let intellect = borrow_global_mut<Intellect>(character_address);
        let new_intellect = intellect.value + intellect_boost;

        let character = borrow_global_mut<Character>(character_address);
        event::emit_event(&mut character.intellect_update_events, IntellectUpdateEvent {
            old_intellect: intellect.value,
            new_intellect: new_intellect,
            character_address: character_address,
        });

        property_map::update_typed(&character.property_mutator_ref, &string::utf8(INTELLECT_PROPERTY_NAME), new_intellect);
        let metadata = object::convert<TrinketToken, Metadata>(trinket);
        property_map::update_typed(&character.property_mutator_ref, &string::utf8(TRINKET_PROPERTY_NAME), fungible_asset::name(metadata));
    }

    public entry fun equip_weapon(from: &signer, weapon: Object<WeaponToken>, to: Object<Character>) acquires Agility, Character, WeaponToken, AgilityIncrease {
        burn_weapon(from, weapon);
        let agility_boost = token_agility_increase(weapon);
        let character_address = object::object_address(&to);
        let agility = borrow_global_mut<Agility>(character_address);   
        let new_agility = agility.value + agility_boost;

        let character = borrow_global_mut<Character>(character_address);
        event::emit_event(&mut character.agility_update_events, AgilityUpdateEvent {
            old_agility: agility.value,
            new_agility: new_agility,
            character_address: character_address,
        });
      
        property_map::update_typed(&character.property_mutator_ref, &string::utf8(AGILITY_PROPERTY_NAME), new_agility);
        let metadata = object::convert<WeaponToken, Metadata>(weapon);
        property_map::update_typed(&character.property_mutator_ref, &string::utf8(WEAPON_PROPERTY_NAME), fungible_asset::name(metadata));
    
    }

    #[view]
    public fun get_character_address(character_name: String): address {
        let resource = account::create_resource_address(&@overminders, SEED);
        token::create_token_address(
            &resource, 
            &string::utf8(OVERMIND_PLAYERS_NFT_COLLECTION), 
            &character_name
        )
    }

    #[view]
    /// Check characters current stamina
    public fun current_stamina(token: Object<Character>): u64 acquires Stamina {
        let stamina = borrow_global<Stamina>(object::object_address(&token));
        stamina.value
    }

    #[view]
    /// Check characters current agility
    public fun current_agility(token: Object<Character>): u64 acquires Agility {
        let agility = borrow_global<Agility>(object::object_address(&token));
        agility.value
    }

    #[view]
    /// Check characters current stamiintellectna
    public fun current_intellect(token: Object<Character>): u64 acquires Intellect {
        let intellect = borrow_global<Intellect>(object::object_address(&token));
        intellect.value
    }

    //-----------------------------------------------------------------//
    //                          ARMOUR CODE                            //
    //-----------------------------------------------------------------//

    fun init_armour_module(creator: &signer) {
        
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
        stamina_boost: u64,
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

        move_to(&object_signer, StaminaIncrease { value: stamina_boost });

        // Initialize the property map.
        let properties = property_map::prepare_input(vector[], vector[], vector[]);
        property_map::init(&constructor_ref, properties);
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(STAMINA_INCREASE_PROPERTY_NAME),
            stamina_boost
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
        let fungible_asset_burn_ref = fungible_asset::generate_burn_ref(&constructor_ref);

        // Publishes the armourToken resource 
        let armour_token = ArmourToken {
            property_mutator_ref: property_mutator_ref,
            fungible_asset_mint_ref: fungible_asset_mint_ref,
            fungible_asset_burn_ref: fungible_asset_burn_ref,
        };
        move_to(&object_signer, armour_token);
    }

    public entry fun mint_armour(player: &signer, item_name: String) acquires ArmourToken, State {
        let resource = account::create_resource_address(&@overminders, SEED);
        let state = borrow_global<State>(resource);
        let creator = account::create_signer_with_capability(&state.resource_signer_capability);
        let armour_token = object::address_to_object<ArmourToken>(armour_token_address(item_name));
        let cost = property_map::read_u64<ArmourToken>(&armour_token, &string::utf8(ITEM_COST_PROPERTY_NAME));
        assert!(cost <= coin::balance<AptosCoin>(signer::address_of(player)), ENOT_ENOUGH_FUNDS);
        coin::transfer<AptosCoin>(player, signer::address_of(&creator), cost);
        mint_armour_internal(&creator, armour_token, signer::address_of(player));
    }

    fun mint_armour_internal(creator: &signer, token: Object<ArmourToken>, receiver: address) acquires ArmourToken {
        let armour_token = authorized_armour_borrow<ArmourToken>(creator, &token);
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

    public(friend) fun burn_armour(from: &signer, armour: Object<ArmourToken>) acquires ArmourToken {
        let metadata = object::convert<ArmourToken, Metadata>(armour);
        let armour_addr = object::object_address(&armour);
        let armour_token = borrow_global<ArmourToken>(armour_addr);
        let store = primary_fungible_store::ensure_primary_store_exists(signer::address_of(from), metadata);
        fungible_asset::burn_from(&armour_token.fungible_asset_burn_ref, store, 1);
    }

    #[view]
    public fun token_stamina_increase(token: Object<ArmourToken>): u64 acquires StaminaIncrease {
        let token_stamina_increase_value = borrow_global<StaminaIncrease>(object::object_address(&token));
        token_stamina_increase_value.value
    }

    #[view]
    /// Returns the current armour token of the owner
    public fun current_armour(_owner_addr: address, armour: Object<ArmourToken>): String {
        let metadata = object::convert<ArmourToken, Metadata>(armour);
        fungible_asset::name(metadata)
    }

    #[view]
    /// Returns the armour token address by name
    public fun armour_token_address(weapon_token_name: String): address {
        let resource = account::create_resource_address(&@overminders, SEED);
        token::create_token_address(&resource, &string::utf8(OVERMIND_PLAYERS_ARMOUR_COLLECTION), &weapon_token_name)
    }

    #[view]
    /// Returns the shirt token address
    public fun shirt_token_address(): address {
        armour_token_address(string::utf8(SHIRT_TOKEN_NAME))
    }

    #[view]
    /// Returns the cloak token address
    public fun cloak_token_address(): address {
        armour_token_address(string::utf8(CLOAK_TOKEN_NAME))
    }
    #[view]
    /// Returns the wizards' cloak token address
    public fun wizards_cloak_token_address(): address {
        armour_token_address(string::utf8(WIZARDS_CLOAK_TOKEN_NAME))
    }

    #[view]
    /// Returns the chainmail token address
    public fun chainmail_token_address(): address {
        armour_token_address(string::utf8(CHAINMAIL_TOKEN_NAME))
    }
    #[view]
    /// Returns the knights' armour token address
    public fun knights_armour_token_address(): address {
        armour_token_address(string::utf8(KNIGHTS_ARMOUR_TOKEN_NAME))
    }

    #[view]
    /// Returns the shirt token address
    public fun tuxedo_token_address(): address {
        armour_token_address(string::utf8(TUXEDO_TOKEN_NAME))
    }

    #[view]
    /// Returns the shirt token address
    public fun golden_armour_token_address(): address {
        armour_token_address(string::utf8(GOLDEN_AMOUR_TOKEN_NAME))
    }
    
    #[view]
    /// Returns the balance of armour tokens of the owner
    public fun armour_balance(owner_addr: address, armour: Object<ArmourToken>): u64 {
        let metadata = object::convert<ArmourToken, Metadata>(armour);
        let store = primary_fungible_store::ensure_primary_store_exists(owner_addr, metadata);
        fungible_asset::balance(store)
    }

    //-----------------------------------------------------------------//
    //                          TRINKET CODE                           //
    //-----------------------------------------------------------------//

    fun init_trinket_module(creator: &signer) {

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
        intellect_boost: u64,
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

        move_to(&object_signer, IntellectIncrease { value: intellect_boost });

        // Initialize the property map.
        let properties = property_map::prepare_input(vector[], vector[], vector[]);
        property_map::init(&constructor_ref, properties);
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(INTELLECT_INCREASE_PROPERTY_NAME),
            intellect_boost
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
        let fungible_asset_burn_ref = fungible_asset::generate_burn_ref(&constructor_ref);

        // Publishes the TrinketToken resource with the refs.
        let trinket_token = TrinketToken {
            property_mutator_ref: property_mutator_ref,
            fungible_asset_mint_ref: fungible_asset_mint_ref,
            fungible_asset_burn_ref: fungible_asset_burn_ref,
        };
        move_to(&object_signer, trinket_token);
    } 

    public(friend) entry fun mint_trinket(player: &signer, item_name: String) acquires State, TrinketToken {
        let resource = account::create_resource_address(&@overminders, SEED);
        let state = borrow_global<State>(resource);
        let creator = account::create_signer_with_capability(&state.resource_signer_capability);
        let trinket_token = object::address_to_object<TrinketToken>(trinket_token_address(item_name));
        let cost = property_map::read_u64<TrinketToken>(&trinket_token, &string::utf8(ITEM_COST_PROPERTY_NAME));
        assert!(cost <= coin::balance<AptosCoin>(signer::address_of(player)), ENOT_ENOUGH_FUNDS);
        coin::transfer<AptosCoin>(player, signer::address_of(&creator), cost);
        mint_trinket_internal(&creator, trinket_token, signer::address_of(player));
    }

    fun mint_trinket_internal(creator: &signer, token: Object<TrinketToken>, receiver: address) acquires TrinketToken {
        let trinket_token = authorized_trinket_borrow<TrinketToken>(creator, &token);
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

    public(friend) fun burn_trinket(from: &signer, trinket: Object<TrinketToken>) acquires TrinketToken {
        let metadata = object::convert<TrinketToken, Metadata>(trinket);
        let trinket_addr = object::object_address(&trinket);
        let trinket_token = borrow_global<TrinketToken>(trinket_addr);
        let store = primary_fungible_store::ensure_primary_store_exists(signer::address_of(from), metadata);
        fungible_asset::burn_from(&trinket_token.fungible_asset_burn_ref, store, 1);
    }

    #[view]
    public fun token_intellect_increase(token: Object<TrinketToken>): u64 acquires IntellectIncrease {
        let token_intellect_increase_value = borrow_global<IntellectIncrease>(object::object_address(&token));
        token_intellect_increase_value.value
    }

    #[view]
    /// Returns the current trinket token of the owner
    public fun current_trinket(_owner_addr: address, trinket: Object<TrinketToken>): String {
        let metadata = object::convert<TrinketToken, Metadata>(trinket);
        fungible_asset::name(metadata)
    }

    #[view]
    /// Returns the trinket token address by name
    public fun trinket_token_address(trinket_token_name: String): address {
        let resource = account::create_resource_address(&@overminders, SEED);
        token::create_token_address(&resource, &string::utf8(OVERMIND_PLAYERS_TRINKET_COLLECTION), &trinket_token_name)
    }

    #[view]
    /// Returns the chain token address
    public fun chain_token_address(): address {
        trinket_token_address(string::utf8(CHAIN_TOKEN_NAME))
    }
    
    #[view]
    /// Returns the pendant token address
    public fun pendant_token_address(): address {
        trinket_token_address(string::utf8(PENDANT_TOKEN_NAME))
    }
    #[view]
    /// Returns the baseball cap token address
    public fun baseball_cap_token_address(): address {
        trinket_token_address(string::utf8(BASEBALL_CAP_TOKEN_NAME))
    }

    #[view]
    /// Returns the wizards' hat token address
    public fun wizards_hat_token_address(): address {
        trinket_token_address(string::utf8(WIZARDS_HAT_TOKEN_NAME))
    }
    #[view]
    /// Returns the helmet token address
    public fun helmet_token_address(): address {
        trinket_token_address(string::utf8(HELMET_TOKEN_NAME))
    }

    #[view]
    /// Returns the crown token address
    public fun crown_token_address(): address {
        trinket_token_address(string::utf8(CROWN_TOKEN_NAME))
    }

    #[view]
    /// Returns the halo token address
    public fun halo_token_address(): address {
        trinket_token_address(string::utf8(HALO_TOKEN_NAME))
    }

    #[view]
    /// Returns the balance of trinket tokens of the owner
    public fun trinket_balance(owner_addr: address, trinket: Object<TrinketToken>): u64 {
        let metadata = object::convert<TrinketToken, Metadata>(trinket);
        let store = primary_fungible_store::ensure_primary_store_exists(owner_addr, metadata);
        fungible_asset::balance(store)
    }

    //-----------------------------------------------------------------//
    //                        WEAPON CODE                              //
    //-----------------------------------------------------------------//

    fun init_weapon_module(creator: &signer) {
        
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
        agility_boost: u64,
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

        move_to(&object_signer, AgilityIncrease { value: agility_boost });

        // Initialize the property map.
        let properties = property_map::prepare_input(vector[], vector[], vector[]);
        property_map::init(&constructor_ref, properties);
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(AGILITY_INCREASE_PROPERTY_NAME),
            agility_boost
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
        let fungible_asset_burn_ref = fungible_asset::generate_burn_ref(&constructor_ref);


        // Publishes the WeaponToken resource
        let weapon_token = WeaponToken {
            property_mutator_ref: property_mutator_ref,
            fungible_asset_mint_ref: fungible_asset_mint_ref,
            fungible_asset_burn_ref: fungible_asset_burn_ref,
        };
        move_to(&object_signer, weapon_token);
    }

    public(friend) entry fun mint_weapon(player: &signer, item_name: String) acquires State, WeaponToken {
        let resource = account::create_resource_address(&@overminders, SEED);
        let state = borrow_global<State>(resource);
        let creator = account::create_signer_with_capability(&state.resource_signer_capability);
        let weapon_token = object::address_to_object<WeaponToken>(weapon_token_address(item_name));
        let cost = property_map::read_u64<WeaponToken>(&weapon_token, &string::utf8(ITEM_COST_PROPERTY_NAME));
        assert!(cost <= coin::balance<AptosCoin>(signer::address_of(player)), ENOT_ENOUGH_FUNDS);
        coin::transfer<AptosCoin>(player, signer::address_of(&creator), cost);
        mint_weapon_internal(&creator, weapon_token, signer::address_of(player));
    }

    fun mint_weapon_internal(creator: &signer, token: Object<WeaponToken>, receiver: address) acquires WeaponToken {
        let weapon_token = authorized_weapon_borrow<WeaponToken>(creator, &token);
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


    public(friend) fun burn_weapon(from: &signer, weapon: Object<WeaponToken>) acquires WeaponToken {
        let metadata = object::convert<WeaponToken, Metadata>(weapon);
        let weapon_addr = object::object_address(&weapon);
        let weapon_token = borrow_global<WeaponToken>(weapon_addr);
        let store = primary_fungible_store::ensure_primary_store_exists(signer::address_of(from), metadata);
        fungible_asset::burn_from(&weapon_token.fungible_asset_burn_ref, store, 1);
    }

    #[view]
    public fun token_agility_increase(token: Object<WeaponToken>): u64 acquires AgilityIncrease {
        let token_agility_increase_value = borrow_global<AgilityIncrease>(object::object_address(&token));
        token_agility_increase_value.value
    }

    #[view]
    /// Returns the current weapon token of the owner
    public fun current_weapon(_owner_addr: address, weapon: Object<WeaponToken>): String {
        let metadata = object::convert<WeaponToken, Metadata>(weapon);
        fungible_asset::name(metadata)
    }

    #[view]
    /// Returns the weapon token address by name
    public fun weapon_token_address(weapon_token_name: String): address {
        let resource = account::create_resource_address(&@overminders, SEED);
        token::create_token_address(&resource, &string::utf8(OVERMIND_PLAYERS_WEAPON_COLLECTION), &weapon_token_name)
    }

    #[view]
    /// Returns the dagger token address
    public fun dagger_token_address(): address {
        weapon_token_address(string::utf8(DAGGER_TOKEN_NAME))
    }
    
    #[view]
    /// Returns the broadsword token address
    public fun broadsword_token_address(): address {
        weapon_token_address(string::utf8(BROADSWORD_TOKEN_NAME))
    }

    #[view]
    /// Returns the staff token address
    public fun staff_token_address(): address {
        weapon_token_address(string::utf8(STAFF_TOKEN_NAME))
    }

    #[view]
    /// Returns the wizards' staff token address
    public fun wizards_staff_token_address(): address {
        weapon_token_address(string::utf8(WIZARDS_STAFF_TOKEN_NAME))
    }
    #[view]

    /// Returns the greatsword token address
    public fun greatsword_token_address(): address {
        weapon_token_address(string::utf8(GREATSWORD_TOKEN_NAME))
    }

    #[view]
    /// Returns the pistol token address
    public fun pistol_token_address(): address {
        weapon_token_address(string::utf8(PISTOL_TOKEN_NAME))
    }

    #[view]
    /// Returns the laser pistol token address
    public fun laser_pistol_token_address(): address {
        weapon_token_address(string::utf8(LASER_PISTOL_TOKEN_NAME))
    }

    #[view]
    /// Returns the balance of weapon tokens of the owner
    public fun weapon_balance(owner_addr: address, weapon: Object<WeaponToken>): u64 {
        let metadata = object::convert<WeaponToken, Metadata>(weapon);
        let store = primary_fungible_store::ensure_primary_store_exists(owner_addr, metadata);
        fungible_asset::balance(store)
    }

    //-----------------------------------------------------------------//
    //                             TESTS                               //
    //-----------------------------------------------------------------//

    #[test(creator = @overminders, user1 = @0x456, aptos_framework = @0x1)] 
    public fun test_character_creation(creator: &signer, user1: &signer, aptos_framework: &signer) acquires State, Stamina, Agility, Intellect, WeaponToken {
        let user1_address = signer::address_of(user1);
        account::create_account_for_test(user1_address);
        account::create_account_for_test(signer::address_of(creator));

        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(aptos_framework);
        coin::register<AptosCoin>(creator);
        coin::register<AptosCoin>(user1);

        let coins = coin::mint((100 as u64), &mint_cap);
        coin::deposit(user1_address, (coins));

        init_module(creator);

        create_character_for_player(
            user1, 
            string::utf8(b"A strong independant woman"), 
            string::utf8(b"alice"), 
            string::utf8(b"female")
        );
        let character_addr = get_character_address(string::utf8(b"alice"));
        let character_token = object::address_to_object(character_addr);

        assert!(current_intellect(character_token) == 1, 0);
        assert!(current_stamina(character_token) == 1, 1);
        assert!(current_agility(character_token) == 1, 2);
        assert!(object::owner<Character>(character_token) == user1_address, 3);

        mint_weapon(user1, string::utf8(b"Dagger Token"));
        let dagger_token = object::address_to_object<WeaponToken>(dagger_token_address());
        
        assert!(weapon_balance(user1_address, dagger_token) == 1, 4);
        let resource = account::create_resource_address(&@overminders, SEED);

        assert!(coin::balance<AptosCoin>(resource) == (15 as u64), 1); 
        assert!(coin::balance<AptosCoin>(user1_address) == (85 as u64), 2);

        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);
    }

    #[test(creator = @overminders, user1 = @0x456, aptos_framework = @0x1)]
    #[expected_failure(abort_code = ECHARACTER_EXISTS, location = Self)] 
    public fun test_multiple_characters_same_account_fails(creator: &signer, user1: &signer, aptos_framework: &signer) acquires State {
        let user1_address = signer::address_of(user1);
        account::create_account_for_test(user1_address);
        account::create_account_for_test(signer::address_of(creator));

        init_module(creator);

        create_character_for_player(
            user1, 
            string::utf8(b"A strong independant woman"), 
            string::utf8(b"alice"), 
            string::utf8(b"female")
        );
        create_character_for_player(
            user1, 
            string::utf8(b"A strong independant woman"), 
            string::utf8(b"alice"), 
            string::utf8(b"female")
        );
    }

    #[test(creator = @overminders, user1 = @0x456, user2 = @0x789, aptos_framework = @0x1)]
    public fun test_armour(creator: &signer, user1: &signer, user2: &signer, aptos_framework: &signer) acquires State, ArmourToken {
        assert!(signer::address_of(creator) == @overminders, 0);

        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(aptos_framework);

        let user1_address = signer::address_of(user1);
        let user2_address = signer::address_of(user2);
        account::create_account_for_test(user2_address);
        account::create_account_for_test(user1_address);
        account::create_account_for_test(signer::address_of(creator));

        coin::register<AptosCoin>(creator);
        coin::register<AptosCoin>(user1);
        coin::register<AptosCoin>(user2);

        let coins1 = coin::mint((100 as u64), &mint_cap);
        let coins2 = coin::mint((100 as u64), &mint_cap);
        coin::deposit(user1_address, (coins1));
        coin::deposit(user2_address, (coins2));

        init_module(creator);

        mint_armour(user1, string::utf8(SHIRT_TOKEN_NAME));

        let shirt_token = object::address_to_object<ArmourToken>(shirt_token_address());
        assert!(armour_balance(user1_address, shirt_token) == 1, 0);

        mint_armour(user2, string::utf8(CHAINMAIL_TOKEN_NAME));
        let chainmail_token = object::address_to_object<ArmourToken>(chainmail_token_address());
        
        assert!(armour_balance(user2_address, chainmail_token) == 1, 0);

        let resource = account::create_resource_address(&@overminders, SEED);
        
        assert!(coin::balance<AptosCoin>(resource) == (50 as u64), 1); 
        assert!(coin::balance<AptosCoin>(user1_address) == (85 as u64), 2);
        assert!(coin::balance<AptosCoin>(user2_address) == (65 as u64), 2);

        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);
    }

    #[test(creator = @overminders, user1 = @0x456, user2 = @0x789, aptos_framework = @0x1)]
    public fun test_trinket(creator: &signer, user1: &signer, user2: &signer, aptos_framework: &signer) acquires State, TrinketToken {
        assert!(signer::address_of(creator) == @overminders, 0);

        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(aptos_framework);

        let user1_address = signer::address_of(user1);
        let user2_address = signer::address_of(user2);
        account::create_account_for_test(user2_address);
        account::create_account_for_test(user1_address);
        account::create_account_for_test(signer::address_of(creator));

        coin::register<AptosCoin>(creator);
        coin::register<AptosCoin>(user1);
        coin::register<AptosCoin>(user2);


        let coins1 = coin::mint((100 as u64), &mint_cap);
        let coins2 = coin::mint((100 as u64), &mint_cap);
        coin::deposit(user1_address, (coins1));
        coin::deposit(user2_address, (coins2));

        init_module(creator);

        mint_trinket(user1, string::utf8(CHAIN_TOKEN_NAME));
        let chain_token = object::address_to_object<TrinketToken>(chain_token_address());

        assert!(trinket_balance(user1_address, chain_token) == 1, 0);

        mint_trinket(user2, string::utf8(PENDANT_TOKEN_NAME));
        let pendant_token = object::address_to_object<TrinketToken>(pendant_token_address());

        assert!(trinket_balance(user2_address, pendant_token) == 1, 0);

        let resource = account::create_resource_address(&@overminders, SEED);

        assert!(coin::balance<AptosCoin>(resource) == (35 as u64), 1); 
        assert!(coin::balance<AptosCoin>(user1_address) == (85 as u64), 2);
        assert!(coin::balance<AptosCoin>(user2_address) == (80 as u64), 2);

        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);
    }
    
    #[test(creator = @overminders, user1 = @0x456, user2 = @0x789, aptos_framework = @0x1)]
    public fun test_weapon(creator: &signer, user1: &signer, user2: &signer, aptos_framework: &signer) acquires State, WeaponToken {
        assert!(signer::address_of(creator) == @overminders, 0);

        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(aptos_framework);

        let user1_address = signer::address_of(user1);
        let user2_address = signer::address_of(user2);
        account::create_account_for_test(user2_address);
        account::create_account_for_test(user1_address);
        account::create_account_for_test(signer::address_of(creator));
        
        coin::register<AptosCoin>(creator);
        coin::register<AptosCoin>(user1);
        coin::register<AptosCoin>(user2);

        let coins1 = coin::mint((100 as u64), &mint_cap);
        let coins2 = coin::mint((100 as u64), &mint_cap);
        coin::deposit(user1_address, (coins1));
        coin::deposit(user2_address, (coins2));

        init_module(creator);

        mint_weapon(user1, string::utf8(DAGGER_TOKEN_NAME));
        debug::print(&current_weapon(user1_address, object::address_to_object<WeaponToken>(dagger_token_address())));
        let dagger_token = object::address_to_object<WeaponToken>(dagger_token_address());
        
        assert!(weapon_balance(user1_address, dagger_token) == 1, 0);

        mint_weapon(user2, string::utf8(BROADSWORD_TOKEN_NAME));
        let broadsword_token = object::address_to_object<WeaponToken>(broadsword_token_address());
        
        assert!(weapon_balance(user2_address, broadsword_token) == 1, 0);
        
        let resource = account::create_resource_address(&@overminders, SEED);

        assert!(coin::balance<AptosCoin>(resource) == (35 as u64), 1); 
        assert!(coin::balance<AptosCoin>(user1_address) == (85 as u64), 2);
        assert!(coin::balance<AptosCoin>(user2_address) == (80 as u64), 2);

        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);
    }
}