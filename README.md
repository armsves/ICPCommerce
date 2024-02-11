Hello my name is armando medina and i'm a motoko bootcamp graduate from may 2023
since then i've been developing in web3 and participating in a few hackatons
what i want to accomplish with this project is to have a e-commerce CMS 100% on chain that can be used and configured by any kind of users.
the idea is to have a main proyect creation and management canister and within that users will be able to create their own ICPcommerce store

Now i want to present you ICPcommerce, this is the main page with some categories and products, also there is the token price for reference, the token price is fetched in the frontend every 10 seconds so it's kept updated, but all the calculations in checkout are done in the backend with HTTPS Outcalls

first we need to login to our wallet, i used plug wallet for now, but i will expand for other login methods too.

it detects me as an admin because my wallet's principal is hardcoded, it can be changed to the canister controller and will be added a module to add/delete controllers being careful not to leave it without any.

this is the administration area where you can create/delete categories and delete orders, of course this has to be expanded to be able to edit all 3 of them.

the orders area shows the principal id of the order, the price paid, the token and the block height that confirms it was sucessfully paid, also here we can add a verification to check the transaction succeeded before shipping the order.

now we can see the shopping cart where you can see the products that you have added, add/remove quantity or delete it.
after you're happy with your cart you can choose which token to use to pay, i added a few verifications if the transaction is declined or there is no enough balance to pay. i will show how it works with ICP on mainnet because i don't have any ckBTC or ckETH but i welcome the judges to test it =)

now that the order has been placed we can check in the admin area that we have a new order that has been paid
we can also check the transaction in my wallet and in ICscan which will confirm the same block height in the admin area.