import React, { Component } from 'react'
import './App.css'

import Navbar from './Navbar'
import Content from './Content'

import { contractsLoadedSelector } from '../store/selectors'

import { connect } from 'react-redux'
import {
  loadWeb3,
  loadAccount,
  loadToken,
  loadExchange,
} from '../store/interactions'

class App extends Component {
  componentWillMount() {
    this.loadBlockchainData(this.props.dispatch)
  }

  async loadBlockchainData(dispatch) {
    const web3 = loadWeb3(dispatch)
    console.log('web3 对象: ', web3)
    const networkType = await web3.eth.net.getNetworkType()
    console.log('网络类型: ', networkType)
    const networkId = await web3.eth.net.getId()
    console.log('网络ID: ', networkId)
    const account = await loadAccount(web3, dispatch)
    console.log('当前账户: ', account)
    const token = await loadToken(web3, networkId, dispatch)
    if (!token) {
      window.alert(
        'Token smart contract not detected on the current network. Please select another network with MEtamask. 该网络中不存在 token, 请在 metamask 中切换网络'
      )
    }
    const exchange = await loadExchange(web3, networkId, dispatch)
    if (!exchange) {
      window.alert(
        'Exchange smart contract not detected on the current network. Please select another network with MEtamask. 该网络中不存在 Exchange, 请在 metamask 中切换网络'
      )
    }
    const totalSupply = await token.methods.totalSupply().call()
    console.log('totalSupply: ', totalSupply, 'tokens')
    const totalEth = await web3.eth.getBalance(account)
    console.log('totalEth: ', totalEth, 'ETH')
  }

  render() {
    return (
      <div>
        <Navbar />
        {this.props.contractsLoaded ? (
          <Content />
        ) : (
          <div className="content"></div>
        )}
      </div>
    )
  }
}

function mapStateToProps(state) {
  return {
    contractsLoaded: contractsLoadedSelector(state),
  }
}

export default connect(mapStateToProps)(App)

