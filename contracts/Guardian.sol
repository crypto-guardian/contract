// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import "@chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Guardian is Pausable, ConfirmedOwner, AutomationCompatibleInterface {
    uint256 public ownerLastActiveTimestamp;
    uint256 public maxInactivePeriodSeconds;

    event KeeperRegistryAddressUpdated(address oldAddress, address newAddress);
    event ReceiversAdded(address[] receivers, uint256[] percentages);

    address[] public receivers;
    mapping(address => uint256) public percentages;

    address[] public tokens;

    address private s_keeperRegistryAddress;

    error OnlyKeeperRegistry();

    constructor(
        address[] memory _receivers,
        uint256[] memory _percentages,
        address[] memory _tokens,
        uint256 _maxInactivePeriodSeconds
    ) ConfirmedOwner(msg.sender) {
        ownerLastActiveTimestamp = block.timestamp;
        maxInactivePeriodSeconds = _maxInactivePeriodSeconds;

        _setRecievers(_receivers, _percentages);
        _setTokens(_tokens);
    }

    function setLastActiveTimestamp() external onlyOwner {
        ownerLastActiveTimestamp = block.timestamp;
    }

    function setMaxInactivePeriodSeconds(
        uint256 _maxInactivePeriodSeconds
    ) external onlyOwner {
        require(_maxInactivePeriodSeconds < 86400, "Guardian: min 1 day");

        maxInactivePeriodSeconds = _maxInactivePeriodSeconds;
    }

    function setRecievers(
        address[] memory _receivers,
        uint256[] memory _percentages
    ) external onlyOwner {
        _setRecievers(_receivers, _percentages);
    }

    function setTokens(address[] memory _tokens) external onlyOwner {
        _setTokens(_tokens);
    }

    function _setRecievers(
        address[] memory _receivers,
        uint256[] memory _percentages
    ) internal {
        require(
            _receivers.length == _percentages.length,
            "Guardian: invalid data"
        );

        for (uint256 i = 0; i < _receivers.length; i++) {
            receivers.push(_receivers[i]);
            percentages[_receivers[i]] = _percentages[i];
        }

        emit ReceiversAdded(_receivers, _percentages);
    }

    function _setTokens(address[] memory _tokens) internal {
        for (uint256 i = 0; i < _tokens.length; i++) {
            tokens.push(_tokens[i]);
        }
    }

    function checkUpkeep(
        bytes memory
    )
        external
        view
        override
        whenNotPaused
        returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded =
            block.timestamp - ownerLastActiveTimestamp >
            maxInactivePeriodSeconds;

        return (upkeepNeeded, performData);
    }

    function performUpkeep(
        bytes calldata performData
    ) external override onlyKeeperRegistry whenNotPaused {
        _execTransfer();
    }

    function _execTransfer() internal {
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20 token = IERC20(tokens[i]);
            uint256 ownerBalance = token.balanceOf(owner());
            if (ownerBalance <= 0) {
                continue;
            }

            for (uint256 j = 0; j < receivers.length; j++) {
                if (percentages[receivers[j]] > 0) {
                    token.transfer(
                        receivers[j],
                        (ownerBalance * percentages[receivers[j]]) / 10000
                    );
                }
            }
        }
    }

    /**
     * @notice Sets the Chainlink Automation registry address
     */
    function setKeeperRegistryAddress(
        address keeperRegistryAddress
    ) public onlyOwner {
        require(keeperRegistryAddress != address(0));
        emit KeeperRegistryAddressUpdated(
            s_keeperRegistryAddress,
            keeperRegistryAddress
        );
        s_keeperRegistryAddress = keeperRegistryAddress;
    }

    /**
     * @notice Pauses the contract, which prevents executing performUpkeep
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    modifier onlyKeeperRegistry() {
        if (msg.sender != s_keeperRegistryAddress) {
            revert OnlyKeeperRegistry();
        }
        _;
    }
}
