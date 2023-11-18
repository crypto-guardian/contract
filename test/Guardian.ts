import {
    loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("Guardian Contract", function () {
    //   let guardian, token, deployer, receiver, receiver1;


    async function deployGuardian() {
        const ONE_MONETH_IN_SECS = 30 * 24 * 60 * 60;
        const ONE_GWEI = 1_000_000_000;

        const amount = ONE_GWEI;
        const inactiveTime = ONE_MONETH_IN_SECS;

        // Contracts are deployed using the first signer/account by default
        const [owner, receiver, receiver1] = await ethers.getSigners();

        const MockERC20 = await ethers.getContractFactory('MockERC20');
        const token = await MockERC20.deploy('My Token', 'MTK');

        const Guardian = await ethers.getContractFactory("Guardian");
        const guardian = await Guardian.deploy(
            [receiver.address], // Add your receivers here
            [10000], // Add corresponding percentages here
            [await token.getAddress()], // Add your token address here
            inactiveTime // Max inactive period in seconds
        );

        return { guardian, inactiveTime, amount, owner, receiver, receiver1, token };
    }

    describe("Deployment", function () {
        it("Should set the right data", async function () {
            const { guardian, inactiveTime, receiver, token } = await loadFixture(deployGuardian);

            expect(await guardian.maxInactivePeriodSeconds()).to.equal(inactiveTime);
            expect(await guardian.receivers(0)).to.equal(receiver.address);
            expect(await guardian.percentages(receiver.address)).to.equal(10000);
            expect(await guardian.tokens(0)).to.equal(await token.getAddress());
        });
    });
});