module uniport::factory {
    use sui::tx_context::{TxContext};
    use uniport::uniport20bridge::{Self, BridgeState, BridgeAdminCap};

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

    public entry fun create<P: drop>(witness: P, bridgeState: &mut BridgeState, name: vector<u8>, symbol: vector<u8>, decimals: u8, adminCap: &BridgeAdminCap,  ctx: &mut TxContext) {
        uniport20bridge::createUNIPORT20(witness, bridgeState, name, symbol, decimals, adminCap, ctx);
    }

    public entry fun createORDI(bridgeState: &mut BridgeState, name: vector<u8>, symbol: vector<u8>, decimals: u8, adminCap: &BridgeAdminCap,  ctx: &mut TxContext) {
        create<ORDI>(ORDI {}, bridgeState, name, symbol, decimals, adminCap, ctx);
    }

    public entry fun createRATS(bridgeState: &mut BridgeState, name: vector<u8>, symbol: vector<u8>, decimals: u8, adminCap: &BridgeAdminCap,  ctx: &mut TxContext) {
        create<RATS>(RATS {}, bridgeState, name, symbol, decimals, adminCap, ctx);
    }

    public entry fun createSATS(bridgeState: &mut BridgeState, name: vector<u8>, symbol: vector<u8>, decimals: u8, adminCap: &BridgeAdminCap,  ctx: &mut TxContext) {
        create<SATS>(SATS {}, bridgeState, name, symbol, decimals, adminCap, ctx);
    }

    public entry fun createETHS(bridgeState: &mut BridgeState, name: vector<u8>, symbol: vector<u8>, decimals: u8, adminCap: &BridgeAdminCap,  ctx: &mut TxContext) {
        create<ETHS>(ETHS {}, bridgeState, name, symbol, decimals, adminCap, ctx);
    }

    public entry fun createETHI(bridgeState: &mut BridgeState, name: vector<u8>, symbol: vector<u8>, decimals: u8, adminCap: &BridgeAdminCap,  ctx: &mut TxContext) {
        create<ETHI>(ETHI {}, bridgeState, name, symbol, decimals, adminCap, ctx);
    }

    public entry fun createETHR(bridgeState: &mut BridgeState, name: vector<u8>, symbol: vector<u8>, decimals: u8, adminCap: &BridgeAdminCap,  ctx: &mut TxContext) {
        create<ETHR>(ETHR {}, bridgeState, name, symbol, decimals, adminCap, ctx);
    }

    public entry fun createBNBS(bridgeState: &mut BridgeState, name: vector<u8>, symbol: vector<u8>, decimals: u8, adminCap: &BridgeAdminCap,  ctx: &mut TxContext) {
        create<BNBS>(BNBS {}, bridgeState, name, symbol, decimals, adminCap, ctx);
    }

    public entry fun createBSCI(bridgeState: &mut BridgeState, name: vector<u8>, symbol: vector<u8>, decimals: u8, adminCap: &BridgeAdminCap,  ctx: &mut TxContext) {
        create<BSCI>(BSCI {}, bridgeState, name, symbol, decimals, adminCap, ctx);
    }

    public entry fun createBSCR(bridgeState: &mut BridgeState, name: vector<u8>, symbol: vector<u8>, decimals: u8, adminCap: &BridgeAdminCap,  ctx: &mut TxContext) {
        create<BSCR>(BSCR {}, bridgeState, name, symbol, decimals, adminCap, ctx);
    }
}