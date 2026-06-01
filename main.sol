// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title ForgeVV
/// @notice helix braid / cognate float corridor
/// @dev On-chain AI-frame savings lanes; pull withdrawals; lanePaused circuit.

library ForgeMath {
    error FVV_MathOverflow();
    uint256 internal constant BPS = 10_000;
    uint256 internal constant YEAR = 31_536_000;
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }
    function mulDivDown(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        unchecked {
            if (d == 0) revert FVV_MathOverflow();
            z = (x * y) / d;
        }
    }
    function clampBps(uint256 v, uint256 lo, uint256 hi) internal pure returns (uint256) {
        if (v < lo) return lo;
        if (v > hi) return hi;
        return v;
    }
}

contract ForgeVV {
    error FVV_NotGovernor();
    error FVV_LanePaused();
    error FVV_ZeroAddr();
    error FVV_ZeroAmt();
    error FVV_Reentered();
    error FVV_BadHandoff();
    error FVV_NoPending();
    error FVV_BalanceLow();
    error FVV_PodMissing();
    error FVV_PodLocked(uint64 untilTs);
    error FVV_CapHit();
    error FVV_BadEpoch();
    error FVV_BadBps();
    error FVV_BelowMin();
    error FVV_AboveMax();
    error FVV_QueueEmpty();
    error FVV_QueueBusy(bytes32 ticket);
    error FVV_NotReady(uint64 at);
    error FVV_FrameStale();
    error FVV_ScheduleVoid();
    error FVV_TransferFail();
    error FVV_DigestMismatch();
    error FVV_LineRetired();
    error FVV_Fault_0();
    error FVV_Fault_1();
    error FVV_Fault_2();
    error FVV_Fault_3();
    error FVV_Fault_4();
    error FVV_Fault_5();
    error FVV_Fault_6();
    error FVV_Fault_7();
    error FVV_Fault_8();
    error FVV_Fault_9();
    error FVV_Fault_10();
    error FVV_Fault_11();
    error FVV_Fault_12();
    error FVV_Fault_13();
    error FVV_Fault_14();
    error FVV_Fault_15();
    error FVV_Fault_16();
    error FVV_Fault_17();
    error FVV_Fault_18();
    error FVV_Fault_19();
    error FVV_Fault_20();
    error FVV_Fault_21();
    error FVV_Fault_22();
    error FVV_Fault_23();
    error FVV_Fault_24();
    error FVV_Fault_25();
    error FVV_Fault_26();
    error FVV_Fault_27();
    error FVV_Fault_28();
    error FVV_Fault_29();
    error FVV_Fault_30();
    error FVV_Fault_31();
    error FVV_Fault_32();
    error FVV_Fault_33();
    error FVV_Fault_34();
    error FVV_Fault_35();
    error FVV_Fault_36();
    error FVV_Fault_37();
    error FVV_Fault_38();
    error FVV_Fault_39();
    error FVV_Fault_40();
    error FVV_Fault_41();
    error FVV_Fault_42();
    error FVV_Fault_43();

    event Opened(address indexed saver, uint256 indexed podId, uint256 weiAmt);
    event Topped(address indexed saver, uint256 indexed podId, uint256 weiAmt);
    event Moved(address indexed saver, uint256 fromFloat, uint256 toPod);
    event Claimed(address indexed saver, uint256 weiAmt, bytes32 ticket);
    event Queued(address indexed saver, address indexed to, uint256 weiAmt, uint64 readyAt, bytes32 ticket);
    event Cancelled(address indexed saver, bytes32 ticket, uint256 refunded);
    event Scored(address indexed saver, uint256 frameId, int256 score, bytes32 modelTag);
    event Shifted(uint256 indexed epochId, uint64 wall, uint256 pooled);
    event Paused(bool lanePaused);
    event Proposed(address indexed prev, address indexed next);
    event Accepted(address indexed governor);
    event Tuned(uint256 tierId, uint256 accrualBps, uint256 minWei);
    event Tick_0(uint256 indexed lineId, address indexed actor, uint256 weiAmt);
    event Tick_1(uint256 indexed lineId, address indexed actor, uint256 weiAmt);
    event Tick_2(uint256 indexed lineId, address indexed actor, uint256 weiAmt);
    event Tick_3(uint256 indexed lineId, address indexed actor, uint256 weiAmt);
    event Tick_4(uint256 indexed lineId, address indexed actor, uint256 weiAmt);
    event Tick_5(uint256 indexed lineId, address indexed actor, uint256 weiAmt);
    event Tick_6(uint256 indexed lineId, address indexed actor, uint256 weiAmt);
    event Tick_7(uint256 indexed lineId, address indexed actor, uint256 weiAmt);
    event Tick_8(uint256 indexed lineId, address indexed actor, uint256 weiAmt);
    event Tick_9(uint256 indexed lineId, address indexed actor, uint256 weiAmt);
    event Tick_10(uint256 indexed lineId, address indexed actor, uint256 weiAmt);

    enum PodPhase { Void, Live, Sealed }
    enum QueueState { None, Waiting, Done }

    struct SavingsPod {
        uint256 principalWei;
        uint256 rewardAccruedWei;
        uint256 goalWei;
        uint64 unlockAt;
        uint64 openedAt;
        uint32 epochJoined;
        PodPhase phase;
        bytes32 labelHash;
    }

    struct FloatLedger {
        uint256 liquidWei;
        uint256 lifetimeInWei;
        uint256 lifetimeOutWei;
        uint64 lastPulse;
    }

    struct AiFrame {
        bytes32 modelTag;
        int256 lastScore;
        uint64 scoredAt;
        uint256 biasBps;
    }

    struct WithdrawCell {
        address to;
        uint256 amountWei;
        uint64 readyAt;
        QueueState state;
    }

    struct EpochLane {
        uint64 startedAt;
        uint256 weightSum;
        uint256 distributedWei;
        bytes32 mixHA;
        bytes32 mixHB;
    }

    struct TierLine {
        uint256 accrualBps;
        uint256 minDepositWei;
        uint256 maxDepositWei;
        uint256 capWei;
        bool accepting;
    }

    struct AutoSchedule {
        uint256 sliceWei;
        uint64 everySeconds;
        uint64 nextAt;
        uint64 endAt;
        uint256 targetPodId;
        bool live;
    }

    uint256 public constant FVV_BPS = 10_000;
    uint256 public constant FVV_MAX_ACCRUAL_BPS = 1_850;
    uint256 public constant FVV_WITHDRAW_DELAY = 86_400;
    uint256 public constant FVV_MIN_FLOAT = 0.0005 ether;
    uint256 public constant FVV_MAX_POD = 750 ether;

    bytes32 private constant _MIX_0 = 0x1238ca9d7ace64c144f75b9b755d110266261226c783266317125142b27d037b;
    bytes32 private constant _MIX_1 = 0x05f4df635160a2042f98f5d0d7e46824c90d2a038bc43dc359ee4222b1173924;
    bytes32 private constant _MIX_2 = 0xda5714cb1e102683443c8bf203ffc40eb20cc3bbf9c2c847ce0cab1f78f92a7a;
    bytes32 private constant _MIX_3 = 0xe45a4d8f10c2cc230d70d28abaea743f10f123fd4abca6cf716d8307bd333a0b;
    bytes32 private constant _MIX_4 = 0x7474b4e244193e32c476e3d06aea9f15bf4f5e7d983c6a4e600bce956041f204;
    bytes32 private constant _MIX_5 = 0x9dd5e8b1f0e471d39ba902bae98f0f4ffbb1f05d11b7a98d07a0d8cf6a5b6d9b;

    address public immutable ADDRESS_A;
    address public immutable ADDRESS_B;
    address public immutable ADDRESS_C;

    address public governor;
    address public pendingGovernor;
    bool public lanePaused;
    uint256 public globalEpoch;
    uint256 public lineNonce;
    uint256 public totalHeldWei;
    uint256 public totalRewardWei;
    uint256 public rewardPoolWei;

    mapping(address => FloatLedger) public floatOf;
    mapping(address => mapping(uint256 => SavingsPod)) public podsOf;
    mapping(address => uint256) public podCountOf;
    mapping(address => mapping(bytes32 => WithdrawCell)) public withdrawOf;
    mapping(address => AiFrame) public frameOf;
    mapping(address => AutoSchedule) public scheduleOf;
    mapping(uint256 => EpochLane) public epochs;
    mapping(uint256 => TierLine) public tiers;
    mapping(uint256 => uint256) public lineWeight;
    mapping(bytes32 => bool) public digestUsed;
    uint256 private _guard;

    modifier nonReentrant() {
        if (_guard == 2) revert FVV_Reentered();
        _guard = 2;
        _;
        _guard = 1;
    }

    modifier onlyGovernor() {
        if (msg.sender != governor) revert FVV_NotGovernor();
        _;
    }

    modifier whenLanesOpen() {
        if (lanePaused) revert FVV_LanePaused();
        _;
    }

    constructor() {
        ADDRESS_A = 0xD99B8C5D4d4DE1Ca49D9753006Db3Dea50718BF6;
        ADDRESS_B = 0xD37f5630B994Bb186e955A7Da9Cbe7Fe7257AA86;
        ADDRESS_C = 0x7f6bCb0D5a138E0503A55d4C485D779f66981DB5;
        governor = msg.sender;
        _guard = 1;
        globalEpoch = 1;
        _seedEpoch(1);
        _bootstrapTiers();
    }

    function proposeGovernor(address next) external onlyGovernor {
        if (next == address(0)) revert FVV_BadHandoff();
        pendingGovernor = next;
        emit Proposed(governor, next);
    }

    function acceptGovernor() external {
        if (msg.sender != pendingGovernor) revert FVV_BadHandoff();
        governor = pendingGovernor;
        pendingGovernor = address(0);
        emit Accepted(governor);
    }

    function setLanePaused(bool v) external onlyGovernor {
        lanePaused = v;
        emit Paused(v);
    }

    function tuneTier(uint256 tierId, uint256 accrualBps, uint256 minWei) external onlyGovernor {
        TierLine storage t = tiers[tierId];
        if (!t.accepting && accrualBps == 0) revert FVV_PodMissing();
        if (accrualBps > FVV_MAX_ACCRUAL_BPS) revert FVV_BadBps();
        t.accrualBps = accrualBps;
        t.minDepositWei = minWei;
        emit Tuned(tierId, accrualBps, minWei);
    }

    /// @notice Fund on-chain reward pool (payable). Accrual draws only from this pool.
    function seedRewardPool() external payable onlyGovernor {
        if (msg.value == 0) revert FVV_ZeroAmt();
        rewardPoolWei += msg.value;
        totalHeldWei += msg.value;
    }

    function advanceEpoch() external onlyGovernor whenLanesOpen {
        uint256 n = globalEpoch + 1;
        if (n > 40) revert FVV_BadEpoch();
        globalEpoch = n;
        _seedEpoch(n);
        emit Shifted(n, uint64(block.timestamp), totalHeldWei);
    }

    /// @notice Credit liquid float (payable). No anonymous receive path.
    function creditFloat() external payable nonReentrant whenLanesOpen {
        if (msg.value == 0) revert FVV_ZeroAmt();
        _creditFloat(msg.sender, msg.value, true);
    }

    function openPod(uint256 tierId, uint256 goalWei, bytes32 labelHash) external whenLanesOpen {
        TierLine storage t = tiers[tierId];
        if (!t.accepting) revert FVV_PodMissing();
        uint256 id = podCountOf[msg.sender];
        podCountOf[msg.sender] = id + 1;
        podsOf[msg.sender][id] = SavingsPod({
            principalWei: 0,
            rewardAccruedWei: 0,
            goalWei: goalWei,
            unlockAt: 0,
            openedAt: uint64(block.timestamp),
            epochJoined: uint32(globalEpoch),
            phase: PodPhase.Live,
            labelHash: labelHash
        });
        emit Opened(msg.sender, id, 0);
    }

    function fundPod(uint256 podId, uint256 tierId) external nonReentrant whenLanesOpen {
        uint256 amt = floatOf[msg.sender].liquidWei;
        if (amt == 0) revert FVV_ZeroAmt();
        _moveFloatToPod(msg.sender, podId, tierId, amt);
    }

    function fundPodAmount(uint256 podId, uint256 tierId, uint256 amt) external nonReentrant whenLanesOpen {
        if (amt == 0) revert FVV_ZeroAmt();
        _moveFloatToPod(msg.sender, podId, tierId, amt);
    }

    function registerFrame(bytes32 modelTag) external whenLanesOpen {
        frameOf[msg.sender] = AiFrame({
            modelTag: modelTag,
            lastScore: 0,
            scoredAt: 0,
            biasBps: 0
        });
    }

    function pokeFrame() external whenLanesOpen {
        AiFrame storage f = frameOf[msg.sender];
        if (f.modelTag == bytes32(0)) revert FVV_FrameStale();
        int256 score = _syntheticScore(msg.sender, f.modelTag);
        uint256 bias = ForgeMath.clampBps(uint256(int256(500) + score), 50, 350);
        f.lastScore = score;
        f.biasBps = bias;
        f.scoredAt = uint64(block.timestamp);
        uint256 frameId = uint256(keccak256(abi.encode(msg.sender, f.scoredAt)));
        emit Scored(msg.sender, frameId, score, f.modelTag);
        _accruePods(msg.sender);
    }

    function requestWithdraw(uint256 amt, address to) external nonReentrant whenLanesOpen {
        if (to == address(0)) revert FVV_ZeroAddr();
        if (amt == 0) revert FVV_ZeroAmt();
        FloatLedger storage fl = floatOf[msg.sender];
        if (fl.liquidWei < amt) revert FVV_BalanceLow();
        bytes32 ticket = keccak256(abi.encode(msg.sender, amt, block.number, lineNonce++));
        if (withdrawOf[msg.sender][ticket].state != QueueState.None) revert FVV_QueueBusy(ticket);
        uint64 ready = uint64(block.timestamp + FVV_WITHDRAW_DELAY);
        fl.liquidWei -= amt;
        withdrawOf[msg.sender][ticket] = WithdrawCell({to: to, amountWei: amt, readyAt: ready, state: QueueState.Waiting});
        emit Queued(msg.sender, to, amt, ready, ticket);
    }

    function cancelWithdraw(bytes32 ticket) external nonReentrant {
        WithdrawCell storage c = withdrawOf[msg.sender][ticket];
        if (c.state != QueueState.Waiting) revert FVV_QueueEmpty();
        uint256 amt = c.amountWei;
        c.state = QueueState.None;
        floatOf[msg.sender].liquidWei += amt;
        emit Cancelled(msg.sender, ticket, amt);
    }

    function claimWithdraw(bytes32 ticket) external nonReentrant {
        WithdrawCell storage c = withdrawOf[msg.sender][ticket];
        if (c.state != QueueState.Waiting) revert FVV_QueueEmpty();
        if (block.timestamp < c.readyAt) revert FVV_NotReady(c.readyAt);
        uint256 amt = c.amountWei;
        c.state = QueueState.Done;
        if (address(this).balance < amt) revert FVV_BalanceLow();
        totalHeldWei -= amt;
        (bool ok,) = c.to.call{value: amt}("");
        if (!ok) revert FVV_TransferFail();
        emit Claimed(msg.sender, amt, ticket);
    }

    function defineSchedule(uint256 podId, uint256 sliceWei, uint64 everySeconds, uint64 endAt)
        external
        whenLanesOpen
    {
        if (sliceWei < FVV_MIN_FLOAT) revert FVV_BelowMin();
        if (everySeconds < 3_600) revert FVV_BadBps();
        SavingsPod storage p = podsOf[msg.sender][podId];
        if (p.phase != PodPhase.Live) revert FVV_PodMissing();
        scheduleOf[msg.sender] = AutoSchedule({
            sliceWei: sliceWei,
            everySeconds: everySeconds,
            nextAt: uint64(block.timestamp + everySeconds),
            endAt: endAt,
            targetPodId: podId,
            live: true
        });
    }

    function runSchedule(uint256 tierId) external nonReentrant whenLanesOpen {
        AutoSchedule storage s = scheduleOf[msg.sender];
        if (!s.live) revert FVV_ScheduleVoid();
        if (block.timestamp < s.nextAt) revert FVV_NotReady(s.nextAt);
