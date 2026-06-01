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
