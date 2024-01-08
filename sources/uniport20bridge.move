module uniport::uniport20bridge {
    use std::string::{Self, String};
    use std::ascii::{Self};
    use sui::object::{Self, UID};
    use sui::transfer::{Self};
    use sui::tx_context::{Self, TxContext};
    use sui::table::{Self, Table};
    use sui::sui::{Self, SUI};
    use sui::balance::{Self, Supply, Balance};
    use sui::coin::{Self, Coin};
    use sui::event;
    use std::type_name;
    use std::option::{Self, Option};

    struct UNIPORT20BRIDGE has drop {}

    struct BridgeAdminCap has key, store {
        id: UID,
    }

    struct MultiSigAdminCap has key, store {
        id: UID,
    }

    // P is the phantom type for ORDI, SATS, etc. for sake of no dynamic coin create
    // Coin<UniPort20<P>> is `ERC20` token
    struct UniPort20<phantom P> has drop {}

    // Pool<P> is `ERC20` token state
    struct Pool<phantom P> has key {
        id: UID,
        supply: Supply<UniPort20<P>>,
        name: String,
        symbol: String,
        decimals: u8,
    }

    struct BridgeState has key {
        id: UID,
        feeManager: Option<address>,
        sui: Balance<SUI>,
        chainFees: Table<u128, u64>,
        supportChains: Table<u128, bool>,
        used: Table<String, bool>, // hex string
        symbolContracts: Table<String, String>, // hex string
    }

    /// Errors
    const E_ZERO_AMOUNT: u64 = 1;
    const E_CHAIN_ID_NOT_SUPPORT: u64 = 2;
    const E_CHAIN_ID_FEE_NOT_SET: u64 = 3;
    const E_TXID_ALREADY_USED: u64 = 4;
    const E_INSUFFICIENT_FEE: u64 = 5;
    const E_AMOUNT_TOO_LARGE: u64 = 6;
    const E_NOT_FEE_MANAGER: u64 = 7;
    const E_DUPLICATE_SYMBOL: u64 = 8;

    const ZERO_ADDRESS: address = @0x0;

    /// Events
    struct FeeManagerChanged has copy, drop {
        oldFeeManager: address,
        newFeeManager: address,
    }

    struct FeeChanged has copy, drop {
        chainId: u128,
        oldFee: u64,
        newFee: u64,
    }

    struct SupportChainsChanged has copy, drop {
        chainId: u128,
        preSupport: bool,
        support: bool,
    }

    struct UNIPORT20Created has copy, drop {
        sender: address,
        uniport20: String,
        symbol: String,
    }

    struct BridgeMinted has copy, drop {
        token: String,
        to: address,
        amount: u64,
        srcChainId: u128,
        txId: String,
    }

    struct BridgeBurned has copy, drop {
        token: String,
        from: address,
        amount: u64,
        chainId: u128,
        fee: u64,
        receiver: String,
    }

    fun init(_otw: UNIPORT20BRIDGE, ctx: &mut TxContext) {
        transfer::share_object(BridgeState {
            id: object::new(ctx),
            feeManager: option::none<address>(),
            sui: balance::zero<SUI>(),
            chainFees: table::new<u128, u64>(ctx),
            supportChains: table::new<u128, bool>(ctx),
            used: table::new<String, bool>(ctx),
            symbolContracts: table::new<String, String>(ctx),
        });
        transfer::public_transfer(BridgeAdminCap { id: object::new(ctx) }, tx_context::sender(ctx));
        transfer::public_transfer(MultiSigAdminCap { id: object::new(ctx) }, tx_context::sender(ctx));
    }

    public fun type_of<T>(): String {
        string::utf8(ascii::into_bytes(type_name::into_string(type_name::get<T>())))
    }

    public entry fun createUNIPORT20<P: drop>(_: P, bridgeState: &mut BridgeState, name: vector<u8>, symbol: vector<u8>, decimals: u8, _: &BridgeAdminCap,  ctx: &mut TxContext) {
        let supply = balance::create_supply(UniPort20<P>{});

        let sym = string::utf8(symbol);
        assert!(!table::contains(&bridgeState.symbolContracts, sym), E_DUPLICATE_SYMBOL);
        table::add(&mut bridgeState.symbolContracts, sym, type_of<UniPort20<P>>());

        transfer::share_object(Pool {
            id: object::new(ctx),
            supply,
            name: string::utf8(name),
            symbol: sym,
            decimals
        });

        event::emit(UNIPORT20Created {
            sender: tx_context::sender(ctx),
            uniport20: type_of<UniPort20<P>>(),
            symbol: sym,
        });
    }

    public entry fun mint<P>(pool: &mut Pool<P>, bridgeState: &mut BridgeState, to: address, amount: u64, srcChainId: u128, txId: vector<u8>, _: &MultiSigAdminCap, ctx: &mut TxContext) {
        transfer::public_transfer(mint_(pool, bridgeState, amount, srcChainId, string::utf8(txId), ctx), to);
        event::emit(BridgeMinted {
            token: type_of<UniPort20<P>>(),
            to,
            amount,
            srcChainId,
            txId: string::utf8(txId),
        });
    }
 
    fun mint_<P>(pool: &mut Pool<P>, bridgeState: &mut BridgeState, amount: u64, srcChainId: u128, txId: String, ctx: &mut TxContext): Coin<UniPort20<P>> {
        assert!(table::contains(&bridgeState.supportChains, srcChainId), E_CHAIN_ID_NOT_SUPPORT);
        assert!(table::contains(&bridgeState.chainFees, srcChainId), E_CHAIN_ID_FEE_NOT_SET);
        assert!(!table::contains(&bridgeState.used, txId), E_TXID_ALREADY_USED);
        table::add(&mut bridgeState.used, txId, true);
        let bal = balance::increase_supply(&mut pool.supply, amount);
        coin::from_balance(bal, ctx)
    }

    public entry fun burn<P>(pool: &mut Pool<P>, coin: &mut Coin<UniPort20<P>>, bridgeState: &mut BridgeState, burnAmount: u64, dstChainId: u128, receiver: vector<u8>, sui: &mut Coin<SUI>, ctx: &mut TxContext) {
        assert!(burnAmount > 0, E_ZERO_AMOUNT);
        assert!(burnAmount <= coin::value(coin), E_AMOUNT_TOO_LARGE);
        assert!(table::contains(&bridgeState.supportChains, dstChainId), E_CHAIN_ID_NOT_SUPPORT);
        assert!(table::contains(&bridgeState.chainFees, dstChainId), E_CHAIN_ID_FEE_NOT_SET);
        let val = coin::value(sui);
        let fee = *table::borrow(&bridgeState.chainFees, dstChainId);
        assert!(val >= fee, E_INSUFFICIENT_FEE);
        let fee_coin = coin::split(sui, fee, ctx);
        balance::join(&mut bridgeState.sui, coin::into_balance(fee_coin));
        let burned = coin::split(coin, burnAmount, ctx);
        balance::decrease_supply(&mut pool.supply, coin::into_balance(burned));
        event::emit(BridgeBurned {
            token: type_of<UniPort20<P>>(),
            from: tx_context::sender(ctx),
            amount: burnAmount,
            chainId: dstChainId,
            fee,
            receiver: string::utf8(receiver),
        });
    }

    public entry fun withdraw(bridgeState: &mut BridgeState, to: address, _: &BridgeAdminCap, ctx: &mut TxContext) {
        let bal = balance::withdraw_all(&mut bridgeState.sui);
        sui::transfer(coin::from_balance(bal, ctx), to);
    }

    public entry fun setFeeManager(bridgeState: &mut BridgeState, newFeeManager: address, _: &BridgeAdminCap, _ctx: &mut TxContext) {
        let opt = option::swap_or_fill(&mut bridgeState.feeManager, newFeeManager);
        if (option::is_some(&opt)) {
            let oldFeeManager = option::destroy_some(opt);
            event::emit(FeeManagerChanged {
                oldFeeManager,
                newFeeManager,
            });
        } else {
            event::emit(FeeManagerChanged {
                oldFeeManager: ZERO_ADDRESS,
                newFeeManager,
            });
        };
    }

    public entry fun setFee(bridgeState: &mut BridgeState, chainId: u128, newFee: u64, ctx: &mut TxContext) {
        let feeManager = *option::borrow(&bridgeState.feeManager);
        assert!(feeManager == tx_context::sender(ctx), E_NOT_FEE_MANAGER);

        if (table::contains(&bridgeState.chainFees, chainId)) {
            event::emit(FeeChanged {
                chainId,
                oldFee: *table::borrow(&bridgeState.chainFees, chainId),
                newFee,
            });
            *table::borrow_mut(&mut bridgeState.chainFees, chainId) = newFee;
        } else {
            table::add(&mut bridgeState.chainFees, chainId, newFee);
            event::emit(FeeChanged {
                chainId,
                oldFee: 0,
                newFee,
            });
        };
    }

    public entry fun setSupportChains(bridgeState: &mut BridgeState, chainId: u128, support: bool, _: &BridgeAdminCap, _ctx: &mut TxContext) {
        if (table::contains(&bridgeState.supportChains, chainId)) {
            event::emit(SupportChainsChanged {
                chainId,
                preSupport: *table::borrow(&bridgeState.supportChains, chainId),
                support,
            });
            *table::borrow_mut(&mut bridgeState.supportChains, chainId) = support;
        } else {
            table::add(&mut bridgeState.supportChains, chainId, support);
            event::emit(SupportChainsChanged {
                chainId,
                preSupport: false,
                support,
            });
        };
    }

    public entry fun transfer(cap: BridgeAdminCap, recipient: address) {
        transfer::public_transfer(cap, recipient)
    }

    public entry fun transfer_msign(cap: MultiSigAdminCap, recipient: address) {
        transfer::public_transfer(cap, recipient)
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(UNIPORT20BRIDGE {}, ctx)
    }
}
