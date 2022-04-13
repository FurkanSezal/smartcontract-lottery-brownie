from scripts.helpful_scripts import get_account, get_contract, fund_with_link
from brownie import Lottery, network, config
import time


def deploy_lottery():
    account = get_account()
    Lottery.deploy(
        get_contract("eth_usd_price_feed").address,
        get_contract("vrf_coordinator").address,
        get_contract("link_token").address,
        config["networks"][network.show_active()]["key_hash"],
        config["networks"][network.show_active()]["fee"],
        {"from": account},
        publish_source=config["networks"][network.show_active()].get("Verify", False),
    )
    print("Depoloyed Lottery!!")


def start_lottery():
    account = get_account()
    lottery = Lottery[-1]
    x = lottery.start_lottery({"from": account})
    x.wait(1)
    print("Lottery started! ")


def enter_lottery():
    account = get_account()
    lottery = Lottery[-1]
    value = lottery.getEnteranceFee() + 1000000
    tx = lottery.enter({"from": account, "value": value})
    tx.wait(1)
    print("You entered the lottery!")


def end_lottery():
    account = get_account()
    lottery = Lottery[-1]
    # fund contract with link token
    x = fund_with_link(lottery.address)
    x.wait(1)
    ending_transaction = lottery.end_lottery({"from": account})
    time.sleep(60)
    print(f"{lottery.recentWinner()} is the winner!")


def main():
    deploy_lottery()
    start_lottery()
    end_lottery()
