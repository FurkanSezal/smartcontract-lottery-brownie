from brownie import Lottery, accounts, network, config
from web3 import Web3


def test_get_enterance_fee():
    account = accounts[0]
    lotteryx = Lottery.deploy(
        config["networks"][network.show_active()]["eth_usd_price_feed"],
        {"from": account},
    )
    a = lotteryx.getEnteranceFee()
    assert a > Web3.toWei(0.015, "ether")
    assert a < Web3.toWei(0.018, "ether")
