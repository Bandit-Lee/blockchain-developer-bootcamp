const Token = artifacts.require('./Token')

require('chai')
	.use(require('chai-as-promised'))
	.should()


contract('Token', (accounts) => {
	const name = 'DApp Token'
	const symbol = 'DApp'
	const decimals = '18'
	const totalSupply = '1000000000000000000000000'
	let token
	beforeEach(async () => {
		// Fetch token from blockchain
		token = await Token.new()
	})

	describe('deployment', () => {
		it('tracks the name', async () => {
			const res = await token.name()
			res.should.equal(name)
			// Check Token name is 'My Name'
		})
		it('tracks the symbol', async () => {
			const res = await token.symbol()
			res.should.equal(symbol)
		})
		it('tracks the decimals', async () => {
			const res = await token.decimals()
			res.toString().should.equal(decimals)
		})
		it('tracks the total supply', async () => {
			const res = await token.totalSupply()
			res.toString().should.equal(totalSupply)
		})
	})
})