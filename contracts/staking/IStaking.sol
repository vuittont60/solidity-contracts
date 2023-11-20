// SPDX-License-Identifier: GPL-3.0-or-later

// ██████████████     ▐████▌     ██████████████
// ██████████████     ▐████▌     ██████████████
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
// ██████████████     ▐████▌     ██████████████
// ██████████████     ▐████▌     ██████████████
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌

pragma solidity ^0.8.9;

/// @title Interface of Threshold Network staking contract
/// @notice The staking contract enables T owners to have their wallets offline
///         and their stake managed by staking providers on their behalf.
///         The staking contract does not define operator role. The operator
///         responsible for running off-chain client software is appointed by
///         the staking provider in the particular application utilizing the
///         staking contract. All off-chain client software should be able
///         to run without exposing operator's or staking provider’s private
///         key and should not require any owner’s keys at all. The stake
///         delegation optimizes the network throughput without compromising the
///         security of the owners’ stake.
interface IStaking {
    enum StakeType {
        NU,
        KEEP,
        T
    }

    //
    //
    // Delegating a stake
    //
    //

    /// @notice Creates a delegation with `msg.sender` owner with the given
    ///         staking provider, beneficiary, and authorizer. Transfers the
    ///         given amount of T to the staking contract.
    /// @dev The owner of the delegation needs to have the amount approved to
    ///      transfer to the staking contract.
    function stake(
        address stakingProvider,
        address payable beneficiary,
        address authorizer,
        uint96 amount
    ) external;

    /// @notice Allows the Governance to set the minimum required stake amount.
    ///         This amount is required to protect against griefing the staking
    ///         contract and individual applications are allowed to require
    ///         higher minimum stakes if necessary.
    function setMinimumStakeAmount(uint96 amount) external;

    //
    //
    // Authorizing an application
    //
    //

    /// @notice Allows the Governance to approve the particular application
    ///         before individual stake authorizers are able to authorize it.
    function approveApplication(address application) external;

    /// @notice Increases the authorization of the given staking provider for
    ///         the given application by the given amount. Can only be called by
    ///         the authorizer for that staking provider.
    /// @dev Calls `authorizationIncreased(address stakingProvider, uint256 amount)`
    ///      on the given application to notify the application about
    ///      authorization change. See `IApplication`.
    function increaseAuthorization(
        address stakingProvider,
        address application,
        uint96 amount
    ) external;

    /// @notice Requests decrease of the authorization for the given staking
    ///         provider on the given application by the provided amount.
    ///         It may not change the authorized amount immediatelly. When
    ///         it happens depends on the application. Can only be called by the
    ///         given staking provider’s authorizer. Overwrites pending
    ///         authorization decrease for the given staking provider and
    ///         application if the application agrees for that. If the
    ///         application does not agree for overwriting, the function
    ///         reverts.
    /// @dev Calls `authorizationDecreaseRequested(address stakingProvider, uint256 amount)`
    ///      on the given application. See `IApplication`.
    function requestAuthorizationDecrease(
        address stakingProvider,
        address application,
        uint96 amount
    ) external;

    /// @notice Requests decrease of all authorizations for the given staking
    ///         provider on all applications by all authorized amount.
    ///         It may not change the authorized amount immediatelly. When
    ///         it happens depends on the application. Can only be called by the
    ///         given staking provider’s authorizer. Overwrites pending
    ///         authorization decrease for the given staking provider and
    ///         application.
    /// @dev Calls `authorizationDecreaseRequested(address stakingProvider, uint256 amount)`
    ///      for each authorized application. See `IApplication`.
    function requestAuthorizationDecrease(address stakingProvider) external;

    /// @notice Called by the application at its discretion to approve the
    ///         previously requested authorization decrease request. Can only be
    ///         called by the application that was previously requested to
    ///         decrease the authorization for that staking provider.
    ///         Returns resulting authorized amount for the application.
    function approveAuthorizationDecrease(address stakingProvider)
        external
        returns (uint96);

    /// @notice Decreases the authorization for the given `stakingProvider` on
    ///         the given disabled `application`, for all authorized amount.
    ///         Can be called by anyone.
    function forceDecreaseAuthorization(
        address stakingProvider,
        address application
    ) external;

    /// @notice Pauses the given application’s eligibility to slash stakes.
    ///         Besides that stakers can't change authorization to the application.
    ///         Can be called only by the Panic Button of the particular
    ///         application. The paused application can not slash stakes until
    ///         it is approved again by the Governance using `approveApplication`
    ///         function. Should be used only in case of an emergency.
    function pauseApplication(address application) external;

    /// @notice Disables the given application. The disabled application can't
    ///         slash stakers. Also stakers can't increase authorization to that
    ///         application but can decrease without waiting by calling
    ///         `requestAuthorizationDecrease` at any moment. Can be called only
    ///         by the governance. The disabled application can't be approved
    ///         again. Should be used only in case of an emergency.
    function disableApplication(address application) external;

    /// @notice Sets the Panic Button role for the given application to the
    ///         provided address. Can only be called by the Governance. If the
    ///         Panic Button for the given application should be disabled, the
    ///         role address should be set to 0x0 address.
    function setPanicButton(address application, address panicButton) external;

    /// @notice Sets the maximum number of applications one staking provider can
    ///         have authorized. Used to protect against DoSing slashing queue.
    ///         Can only be called by the Governance.
    function setAuthorizationCeiling(uint256 ceiling) external;

    //
    //
    // Stake top-up
    //
    //

    /// @notice Increases the amount of the stake for the given staking provider.
    /// @dev The sender of this transaction needs to have the amount approved to
    ///      transfer to the staking contract.
    function topUp(address stakingProvider, uint96 amount) external;

    //
    //
    // Undelegating a stake (unstaking)
    //
    //

    /// @notice Reduces the liquid T stake amount by the provided amount and
    ///         withdraws T to the owner. Reverts if there is at least one
    ///         authorization higher than the sum of the legacy stake and
    ///         remaining liquid T stake or if the unstake amount is higher than
    ///         the liquid T stake amount. Can be called only by the delegation
    ///         owner or the staking provider.
    function unstakeT(address stakingProvider, uint96 amount) external;

    /// @notice Sets the legacy KEEP staking contract active stake amount cached
    ///         in T staking contract to 0. Reverts if the amount of liquid T
    ///         staked in T staking contract is lower than the highest
    ///         application authorization. This function allows to unstake from
    ///         KEEP staking contract and still being able to operate in T
    ///         network and earning rewards based on the liquid T staked. Can be
    ///         called only by the delegation owner or the staking provider.
    function unstakeKeep(address stakingProvider) external;

    /// @notice Sets to 0 the amount of T that is cached from the legacy
    ///         NU staking contract. Reverts if there is at least one
    ///         authorization higher than the sum of remaining legacy NU stake
    ///         and native T stake for that staking provider or if the unstaked
    ///         amount is higher than the cached legacy stake amount. If succeeded,
    ///         the legacy NU stake can be partially or fully undelegated on
    ///         the legacy NU staking contract. This function allows to unstake
    ///         from NU staking contract while still being able to operate in
    ///         T network and earning rewards based on the native T staked.
    ///         Can be called only by the stake owner or the staking provider.
    function unstakeNu(address stakingProvider) external;

    /// @notice Sets cached legacy stake amount to 0, sets the liquid T stake
    ///         amount to 0 and withdraws all liquid T from the stake to the
    ///         owner. Reverts if there is at least one non-zero authorization.
    ///         Can be called only by the delegation owner or the staking
    ///         provider.
    function unstakeAll(address stakingProvider) external;

    //
    //
    // Keeping information in sync
    //
    //

    /// @notice Sets reward in T tokens for notification of misbehaviour
    ///         of one staking provider. Can only be called by the governance.
    function setNotificationReward(uint96 reward) external;

    /// @notice Transfer some amount of T tokens as reward for notifications
    ///         of misbehaviour
    function pushNotificationReward(uint96 reward) external;

    /// @notice Withdraw some amount of T tokens from notifiers treasury.
    ///         Can only be called by the governance.
    function withdrawNotificationReward(address recipient, uint96 amount)
        external;

    /// @notice Adds staking providers to the slashing queue along with the
    ///         amount that should be slashed from each one of them. Can only be
    ///         called by application authorized for all staking providers in
    ///         the array.
    function slash(uint96 amount, address[] memory stakingProviders) external;

    /// @notice Adds staking providers to the slashing queue along with the
    ///         amount. The notifier will receive reward per each staking
    ///         provider from notifiers treasury. Can only be called by
    ///         application authorized for all staking providers in the array.
    function seize(
        uint96 amount,
        uint256 rewardMultipier,
        address notifier,
        address[] memory stakingProviders
    ) external;

    /// @notice Takes the given number of queued slashing operations and
    ///         processes them. Receives 5% of the slashed amount.
    ///         Executes `involuntaryAllocationDecrease` function on each
    ///         affected application.
    function processSlashing(uint256 count) external;

    //
    //
    // Auxiliary functions
    //
    //

    /// @notice Returns the authorized stake amount of the staking provider for
    ///         the application.
    function authorizedStake(address stakingProvider, address application)
        external
        view
        returns (uint96);

    /// @notice Returns staked amount of T, Keep and Nu for the specified
    ///         staking provider.
    /// @dev    All values are in T denomination
    function stakes(address stakingProvider)
        external
        view
        returns (
            uint96 tStake,
            uint96 keepInTStake,
            uint96 nuInTStake
        );

    /// @notice Returns start staking timestamp.
    /// @dev    This value is set at most once.
    function getStartStakingTimestamp(address stakingProvider)
        external
        view
        returns (uint256);

    /// @notice Returns staked amount of NU for the specified staking provider.
    function stakedNu(address stakingProvider) external view returns (uint256);

    /// @notice Gets the stake owner, the beneficiary and the authorizer
    ///         for the specified staking provider address.
    /// @return owner Stake owner address.
    /// @return beneficiary Beneficiary address.
    /// @return authorizer Authorizer address.
    function rolesOf(address stakingProvider)
        external
        view
        returns (
            address owner,
            address payable beneficiary,
            address authorizer
        );

    /// @notice Returns length of application array
    function getApplicationsLength() external view returns (uint256);

    /// @notice Returns length of slashing queue
    function getSlashingQueueLength() external view returns (uint256);

    /// @notice Returns minimum possible stake for T, KEEP or NU in T
    ///         denomination.
    /// @dev For example, suppose the given staking provider has 10 T, 20 T worth
    ///      of KEEP, and 30 T worth of NU all staked, and the maximum
    ///      application authorization is 40 T, then `getMinStaked` for
    ///      that staking provider returns:
    ///          * 0 T if KEEP stake type specified i.e.
    ///            min = 40 T max - (10 T) = 30 T
    ///          * 10 T if NU stake type specified i.e.
    ///            min = 40 T max - (10 T) = 30 T
    ///          * 0 T if T stake type specified i.e.
    ///            min = 40 T max = 40 T
    ///      In other words, the minimum stake amount for the specified
    ///      stake type is the minimum amount of stake of the given type
    ///      needed to satisfy the maximum application authorization given
    ///      the staked amounts of the T stake types for that staking provider.
    function getMinStaked(address stakingProvider, StakeType stakeTypes)
        external
        view
        returns (uint96);

    /// @notice Returns available amount to authorize for the specified application
    function getAvailableToAuthorize(
        address stakingProvider,
        address application
    ) external view returns (uint96);
}
