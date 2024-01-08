#[test_only]
module uniport::uniport20bridge_tests {
    use sui::sui::SUI;
    use sui::coin::{Self, Coin};
    use sui::test_scenario::{Self as test, Scenario, next_tx, ctx};
    use uniport::uniport20bridge::{Self, Pool, UniPort20, BridgeAdminCap, BridgeState, MultiSigAdminCap};

    // BTC
    struct SATS has drop {}
    struct ORDI has drop {}
    struct RATS has drop {}

    // ETH
    struct ETHS has drop {}
    struct ETHI has drop {}
    struct ETHR has drop {}

    // BSC
    struct BNBS has drop {}
    struct BSCI has drop {}
    struct BSCR has drop {}

    #[test] fun test_init_pool() {
        let scenario = scenario();
        test_init_pool_(&mut scenario);
        test::end(scenario);
    }

    fun set_fee_manager(sender: address, fee_manager: address, test: &mut Scenario) {
        next_tx(test, sender);
        {
            let bridgeState = test::take_shared<BridgeState>(test);
            let bridgeAdminCap = test::take_from_address<BridgeAdminCap>(test, sender);

            uniport20bridge::setFeeManager(&mut bridgeState, fee_manager, &bridgeAdminCap, ctx(test));
            test::return_shared(bridgeState);
            test::return_to_address(sender, bridgeAdminCap);
        };
    }

    fun set_support_chains(sender: address, chainId: u128, support: bool, test: &mut Scenario) {
        next_tx(test, sender);
        {
            let bridgeState = test::take_shared<BridgeState>(test);
            let bridgeAdminCap = test::take_from_address<BridgeAdminCap>(test, sender);

            uniport20bridge::setSupportChains(&mut bridgeState, chainId, support, &bridgeAdminCap, ctx(test));
            test::return_shared(bridgeState);
            test::return_to_address(sender, bridgeAdminCap);
        };
    }

    fun set_fee(sender: address, chainId: u128, fee: u64, test: &mut Scenario) {
        next_tx(test, sender);
        {
            let bridgeState = test::take_shared<BridgeState>(test);
            uniport20bridge::setFee(&mut bridgeState, chainId, fee, ctx(test));
            test::return_shared(bridgeState);
        };
    }

    fun create_uniport20<P: drop>(witness: P, sender: address, name: vector<u8>, symbol: vector<u8>, decimals: u8, test: &mut Scenario) {
        next_tx(test, sender);
        {
            let bridgeState = test::take_shared<BridgeState>(test);
            let bridgeAdminCap = test::take_from_address<BridgeAdminCap>(test, sender);

            uniport20bridge::createUNIPORT20(
                witness,
                &mut bridgeState,
                name,
                symbol,
                decimals,
                &bridgeAdminCap,
                ctx(test)
            );
            test::return_shared(bridgeState);
            test::return_to_address(sender, bridgeAdminCap);
        };
    }

    fun mint_uniport20<P: drop>(_witness: P, sender: address, amount: u64, srcChainId: u128, txId: vector<u8>, test: &mut Scenario) {
        next_tx(test, sender);
        {
            let pool = test::take_shared<Pool<P>>(test);
            let bridgeState = test::take_shared<BridgeState>(test);
            let multiSigAdminCap = test::take_from_address<MultiSigAdminCap>(test, sender);

            uniport20bridge::mint(
                &mut pool,
                &mut bridgeState,
                sender,
                amount,
                srcChainId,
                txId,
                &multiSigAdminCap,
                ctx(test)
            );
            test::return_shared(pool);
            test::return_shared(bridgeState);
            test::return_to_address(sender, multiSigAdminCap);
        };
    }

    fun burn_uniport20<P: drop>(_witness: P, sender: address, amount: u64, dstChainId: u128, receiver: vector<u8>, sui: &mut Coin<SUI>, test: &mut Scenario) {
        next_tx(test, sender);
        {
            let pool = test::take_shared<Pool<P>>(test);
            let bridgeState = test::take_shared<BridgeState>(test);
            let uniport20coin = test::take_from_address<Coin<UniPort20<P>>>(test, sender);

            uniport20bridge::burn(
                &mut pool,
                &mut uniport20coin,
                &mut bridgeState,
                amount,
                dstChainId,
                receiver,
                sui,
                ctx(test)
            );
            test::return_shared(pool);
            test::return_shared(bridgeState);
            test::return_to_address(sender, uniport20coin);
        };
    }

    fun withdraw(sender: address, receiver: address, test: &mut Scenario) {
        next_tx(test, sender);
        {
            let bridgeState = test::take_shared<BridgeState>(test);
            let bridgeAdminCap = test::take_from_address<BridgeAdminCap>(test, sender);

            uniport20bridge::withdraw(
                &mut bridgeState,
                receiver,
                &bridgeAdminCap,
                ctx(test)
            );
            test::return_shared(bridgeState);
            test::return_to_address(sender, bridgeAdminCap);
        };
    }

    fun test_init_pool_(test: &mut Scenario) {
        let (owner, feeManager) = people();

        next_tx(test, owner);
        {
            uniport20bridge::init_for_testing(ctx(test));
        };

        set_fee_manager(owner, feeManager, test);

        let btc_chainId = 0;
        let btc_fee = 10000;

        let eth_chainId = 1;
        let eth_fee = 20000;

        let bsc_chainId = 56;
        let bsc_fee = 30000;

        set_support_chains(owner, btc_chainId, true, test);
        set_support_chains(owner, eth_chainId, true, test);
        set_support_chains(owner, bsc_chainId, true, test);

        set_fee(feeManager, btc_chainId, btc_fee, test);
        set_fee(feeManager, eth_chainId, eth_fee, test);
        set_fee(feeManager, bsc_chainId, bsc_fee, test);

        // BTC
        create_uniport20(SATS {}, owner, b"SATS", b"SATS", 8, test);
        create_uniport20(ORDI {}, owner, b"ORDI", b"ORDI", 8, test);
        create_uniport20(RATS {}, owner, b"RATS", b"RATS", 8, test);

        // ETH
        create_uniport20(ETHS {}, owner, b"ETHS", b"ETHS", 8, test);
        create_uniport20(ETHI {}, owner, b"ETHI", b"ETHI", 8, test);
        create_uniport20(ETHR {}, owner, b"ETHR", b"ETHR", 8, test);

        // BSC
        create_uniport20(BNBS {}, owner, b"BNBS", b"BNBS", 8, test);
        create_uniport20(BSCI {}, owner, b"BSCI", b"BSCI", 8, test);
        create_uniport20(BSCR {}, owner, b"BSCR", b"BSCR", 8, test);

        // BTC
        let sats_amount = 1_000_000_000;
        let ordi_amount = 2_000_000_000;
        let rats_amount = 3_000_000_000;

        // ETH
        let eths_amount = 4_000_000_000;
        let ethi_amount = 5_000_000_000;
        let ethr_amount = 6_000_000_000;

        // BSC
        let bnbs_amount = 7_000_000_000;
        let bsci_amount = 8_000_000_000;
        let bscr_amount = 9_000_000_000;

        // BTC
        mint_uniport20<SATS>(SATS {}, owner, sats_amount, btc_chainId, b"sats_txid", test);
        mint_uniport20<ORDI>(ORDI {}, owner, ordi_amount, btc_chainId, b"ordi_txId", test);
        mint_uniport20<RATS>(RATS {}, owner, rats_amount, btc_chainId, b"rats_txId", test);

        // ETH
        mint_uniport20<ETHS>(ETHS {}, owner, eths_amount, eth_chainId, b"eths_txId", test);
        mint_uniport20<ETHI>(ETHI {}, owner, ethi_amount, eth_chainId, b"ethi_txId", test);
        mint_uniport20<ETHR>(ETHR {}, owner, ethr_amount, eth_chainId, b"ethr_txId", test);

        // BSC
        mint_uniport20<BNBS>(BNBS {}, owner, bnbs_amount, bsc_chainId, b"bnbs_txId", test);
        mint_uniport20<BSCI>(BSCI {}, owner, bsci_amount, bsc_chainId, b"bsci_txId", test);
        mint_uniport20<BSCR>(BSCR {}, owner, bscr_amount, bsc_chainId, b"bscr_txId", test);

        next_tx(test, owner);
        {
            let sui = coin::mint_for_testing<SUI>((btc_fee + eth_fee + bsc_fee) * 3, ctx(test));

            burn_uniport20<SATS>(SATS {}, owner, sats_amount, btc_chainId, b"11111111111111111", &mut sui, test);
            burn_uniport20<ORDI>(ORDI {}, owner, ordi_amount, btc_chainId, b"22222222222222222", &mut sui, test);
            burn_uniport20<RATS>(RATS {}, owner, rats_amount, btc_chainId, b"33333333333333333", &mut sui, test);

            burn_uniport20<ETHS>(ETHS {}, owner, eths_amount, eth_chainId, b"44444444444444444", &mut sui, test);
            burn_uniport20<ETHI>(ETHI {}, owner, ethi_amount, eth_chainId, b"55555555555555555", &mut sui, test);
            burn_uniport20<ETHR>(ETHR {}, owner, ethr_amount, eth_chainId, b"66666666666666666", &mut sui, test);

            burn_uniport20<BNBS>(BNBS {}, owner, bnbs_amount, bsc_chainId, b"77777777777777777", &mut sui, test);
            burn_uniport20<BSCI>(BSCI {}, owner, bsci_amount, bsc_chainId, b"88888888888888888", &mut sui, test);
            burn_uniport20<BSCR>(BSCR {}, owner, bscr_amount, bsc_chainId, b"99999999999999999", &mut sui, test);

            coin::burn_for_testing(sui);
        };


        withdraw(owner, receiver(), test);
        next_tx(test, receiver());
        {
            let sui = test::take_from_address<Coin<SUI>>(test, receiver());
            assert!(coin::value(&sui) == (btc_fee + eth_fee + bsc_fee) * 3, 0);
            test::return_to_address(receiver(), sui);
        };
   }

    // utilities
    fun scenario(): Scenario { test::begin(@0x1) }
    fun people(): (address, address) { (@0xBEEF, @0x1337) }
    fun receiver() : address { @0x1234 }
}
