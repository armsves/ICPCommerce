import Account "./account";
import Text "mo:base/Text";
import Hash "mo:base/Hash";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import TrieMap "mo:base/TrieMap";
import Result "mo:base/Result";
import Buffer "mo:base/Buffer";
import Blob "mo:base/Blob";
import Array "mo:base/Array";
import Time "mo:base/Time";
import Nat8 "mo:base/Nat8";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Int "mo:base/Int";
import Int64 "mo:base/Int64";
import Error "mo:base/Error";
import Iter "mo:base/Iter";
import Bool "mo:base/Bool";
import Option "mo:base/Option";
import Float "mo:base/Float";
import Char "mo:base/Char";
import Cycles "mo:base/ExperimentalCycles";
import Types "Types";

actor icpcommerce {
  type Time = Int;
  type Account = Account.Account;
  type Video = TrieMap.TrieMap<Text, [Nat8]>;

  public type Subaccount = Blob;
  public type PrincipalArray = [Principal];

  public type Content = {
    #Text : Text;
    #Image : Blob;
    #Video : Nat
  };

  public type Admin = Bool;

  public type Product = {
    id : Nat;
    category : Text;
    name : Text;
    price : Nat;
    quantity : Nat;
    description : Text;
    active : Bool;
    content : Content
  };

  public type ProductCall = {
    category : Text;
    name : Text;
    price : Nat;
    quantity : Nat;
    description : Text;
    active : Bool;
    content : Content
  };

  public type UpdateProfile = {
    name : Text;
    profilePic : Blob
  };

  public type CategoryCall = {
    name : Text
  };

  public type Category = {
    id : Nat;
    name : Text;
    active : Bool
  };

  public type Profile = {
    name : Text;
    profilePic : ?Blob;
    admin : Admin
  };

  let guestProfile : Profile = {
    name = "ICPcommerce";
    profilePic = null;
    admin = false
  };

  public type CartProducts = {
    id : Nat;
    productId : Nat;
    customerId : Text;
    quantity : Nat
  };

  public type CartProductsShow = {
    id : Nat;
    productId : Nat;
    category : Text;
    name : Text;
    price : Nat;
    description : Text;
    active : Bool;
    content : Content;
    customerId : Text;
    quantity : Nat
  };

  public type Orders = {
    id : Nat;
    customerId : Text;
    total : Nat;
    symbol : Text;
    paymentTx : Text;
    status : Nat
  };

  public type OrdersProducts = {
    id : Nat;
    orderId : Nat;
    productId : Nat;
    name : Text;
    price : Nat;
    description : Text;
    quantity : Nat
  };

  public type OrdersProductsCall = {
    id : Nat;
    name : Text;
    description : Text;
    productId : Nat;
    quantity : Nat;
    price : Nat
  };

  var profiles = TrieMap.TrieMap<Account.Account, Profile>(Account.accountsEqual, Account.accountsHash);
  var products = TrieMap.TrieMap<Text, Product>(Text.equal, Text.hash);
  var categories = TrieMap.TrieMap<Text, Category>(Text.equal, Text.hash);
  var shoppingCart = TrieMap.TrieMap<Text, CartProducts>(Text.equal, Text.hash);
  var orders = TrieMap.TrieMap<Text, Orders>(Text.equal, Text.hash);
  var ordersProducts = TrieMap.TrieMap<Text, OrdersProducts>(Text.equal, Text.hash);

  public shared query (msg) func getProfile() : async Profile {
    let account : Account = {
      owner = msg.caller;
      subaccount = null
    };
    switch (profiles.get(account)) {
      case null { return guestProfile };
      case (?found) { return found }
    }
  };

  //function to transform the response
  public query func transform(raw : Types.TransformArgs) : async Types.CanisterHttpResponsePayload {
    let transformed : Types.CanisterHttpResponsePayload = {
      status = raw.response.status;
      body = raw.response.body;
      headers = [
        {
          name = "Content-Security-Policy";
          value = "default-src 'self'"
        },
        { name = "Referrer-Policy"; value = "strict-origin" },
        { name = "Permissions-Policy"; value = "geolocation=(self)" },
        {
          name = "Strict-Transport-Security";
          value = "max-age=63072000"
        },
        { name = "X-Frame-Options"; value = "DENY" },
        { name = "X-Content-Type-Options"; value = "nosniff" },
      ]
    };
    transformed
  };

  public func getPrice(symbol : Text) : async Text {
    let ic : Types.IC = actor ("aaaaa-aa");
    let host : Text = "openapi.bitrue.com";
    let url = "https://openapi.bitrue.com/api/v1/ticker/price?symbol=" # symbol;

    let request_headers = [
      { name = "Host"; value = host # ":443" },
      { name = "User-Agent"; value = "exchange_rate_canister" },
    ];

    let transform_context : Types.TransformContext = {
      function = transform;
      context = Blob.fromArray([])
    };

    let http_request : Types.HttpRequestArgs = {
      url = url;
      max_response_bytes = ?Nat64.fromNat(500);
      headers = request_headers;
      body = null;
      method = #get;
      transform = ?transform_context
    };
    Cycles.add(3_600_000);

    let http_response : Types.HttpResponsePayload = await ic.http_request(http_request);
    let response_body : Blob = Blob.fromArray(http_response.body);
    let decoded_text : Text = switch (Text.decodeUtf8(response_body)) {
      case (null) { "No value returned" };
      case (?y) { y }
    };
    decoded_text
  };

  public func parseValue(json : Text, obj : Text) : async Text {
    var r : Text = "";
    let b : Buffer.Buffer<Text> = Buffer.Buffer(1);
    for (e in Text.split(json, #text "[")) {
      if (Text.contains(e, #text obj)) {
        for (o : Text in Text.split(e, #text "{")) {
          var j : Text = Text.replace(o, #text "}", "");
          j := Text.replace(j, #text "]", "");
          if (Text.endsWith(j, #text ",")) {
            j := Text.trimEnd(j, #text ",")
          };
          for (f : Text in Text.split(j, #text ",")) {
            if (Text.contains(f, #text obj)) {
              for (t : Text in Text.split(f, #text ":")) {
                switch (Text.contains(t, #text obj)) {
                  case (false) {
                    b.add(Text.replace(t, #text "\"", ""))
                  };
                  case (true) {}
                }
              }
            }
          }
        }
      }
    };
    r := b.get(b.size() - 1);
    return r
  };

  public func textToFloat(t : Text) : async Float {
    var i : Float = 1;
    var f : Float = 0;
    var isDecimal : Bool = false;
    for (c in t.chars()) {
      if (Char.isDigit(c)) {
        let charToNat : Nat64 = Nat64.fromNat(Nat32.toNat(Char.toNat32(c) -48));
        let natToFloat : Float = Float.fromInt64(Int64.fromNat64(charToNat));
        if (isDecimal) {
          let n : Float = natToFloat / Float.pow(10, i);
          f := f + n
        } else {
          f := f * 10 + natToFloat
        };
        i := i + 1
      } else {
        if (Char.equal(c, '.') or Char.equal(c, ',')) {
          f := f / Float.pow(10, i); // Force decimal
          f := f * Float.pow(10, i); // Correction
          isDecimal := true;
          i := 1
        } else {
          throw Error.reject("NaN")
        }
      }
    };

    return f
  };

  public func convertUSDto(symbol : Text, price : Nat) : async Float {
    let rate : Text = await getPrice(symbol);
    let ratePrice = await parseValue(rate, "price");
    let rateValue = await textToFloat(ratePrice);
    let priceFloat = Float.fromInt(price);
    let convertedPrice = Float.div(priceFloat, rateValue);
    convertedPrice
  };

  public shared (msg) func updateProfile(profile : UpdateProfile) : async Profile {
    let account : Account = {
      owner = msg.caller;
      subaccount = null
    };
    switch (profiles.get(account)) {
      case null {
        let imgBlob : ?Blob = ?profile.profilePic;
        let newProfile : Profile = {
          name = profile.name;
          profilePic = imgBlob;
          admin = false
        };
        profiles.put(account, newProfile);
        return newProfile
      };
      case (?found) {
        let imgBlob : ?Blob = ?profile.profilePic;
        let newProfile : Profile = {
          name = profile.name;
          profilePic = imgBlob;
          admin = false
        };
        profiles.put(account, newProfile);
        return newProfile
      }
    }
  };

  public shared (msg) func addProposalChunk(productId : Nat, chunks : Blob) : async Result.Result<(), Text> {
    let result = await getProduct(productId);
    if (Result.isOk(result)) {
      switch (Result.toOption(result)) {
        case null { return #err "not found" };
        case (?found) {
          let arrayFromProduct : [Nat8] = await toNat8(found.content);
          let bufferFromProduct : Buffer.Buffer<Nat8> = Buffer.Buffer<Nat8>(0);
          for (natInArray in arrayFromProduct.vals()) {
            bufferFromProduct.add(natInArray)
          };
          for (chunk in chunks.vals()) {
            bufferFromProduct.add(chunk)
          };
          let finalContentAsNat : [Nat8] = Buffer.toArray(bufferFromProduct);
          let finalBlob : Content = #Image(Blob.fromArray(finalContentAsNat));
          let productToUpdateWithChunks : Product = {
            id = found.id;
            category = found.category;
            name = found.name;
            price = found.price;
            quantity = found.quantity;
            description = found.description;
            active = found.active;
            content = finalBlob
          };
          products.put(Nat.toText(productId), productToUpdateWithChunks);
          return #ok()
        }
      }
    } else {
      return #err "not found"
    }
  };

  public func toNat8(x : Content) : async [Nat8] {
    switch (x) {
      case (#Image content) { return Blob.toArray(content) };
      case (#Video content) { return [0] };
      case (#Text content) { return [0] }
    }
  };

  public shared query func getProduct(productId : Nat) : async Result.Result<Product, Text> {
    switch (products.get(Nat.toText(productId))) {
      case null { return #err "not found" };
      case (?productFound) { return #ok(productFound) }
    }
  };

  public shared query func getProductCart(productId : Nat) : async [Product] {
    let ProductBuffer : Buffer.Buffer<Product> = Buffer.Buffer<Product>(0);
    for (value in products.vals()) {
      if (value.id == productId) {
        let activeProducts : Product = {
          id = value.id;
          category = value.category;
          name = value.name;
          price = value.price;
          quantity = value.quantity;
          description = value.description;
          active = value.active;
          content = value.content
        };
        ProductBuffer.add(activeProducts)
      }
    };
    Buffer.toArray(ProductBuffer)
  };

  public shared (msg) func addNewProduct(product : ProductCall) : async Result.Result<Nat, Text> {
    let newid = products.size();
    let newProduct : Product = {
      id = newid;
      category = product.category;
      name = product.name;
      price = product.price;
      quantity = product.quantity;
      description = product.description;
      active = product.active;
      content = product.content
    };
    switch (products.put(Nat.toText(newid), newProduct)) {
      case (added) {
        return #ok(newid)
      }
    };
    return #err("Couldn't add the product")
  };

  public shared query func getContent(productId : Nat) : async Content {
    switch (products.get(Nat.toText(productId))) {
      case null { return #Text("") };
      case (?productFound) { return productFound.content }
    }
  };

  public shared func createOrder(customerId : Text, cartProducts : [OrdersProductsCall], symbol : Text, hash : Text) : async Bool {
    let newOrdersId = orders.size();
    var total : Nat = 0;
    for (value in cartProducts.vals()) {
      let newId = ordersProducts.size();
      let newOrdersProducts : OrdersProducts = {
        id = newId;
        orderId = newOrdersId;
        productId = value.productId;
        name = value.name;
        price = value.price;
        description = value.description;
        quantity = value.quantity
      };
      total := total + value.price * value.quantity;
      ordersProducts.put(Nat.toText(newId), newOrdersProducts);
      shoppingCart.delete(Nat.toText(value.id))
    };
    let newOrder : Orders = {
      id = newOrdersId;
      customerId = customerId;
      total = total;
      symbol = symbol;
      paymentTx = hash;
      status = 1; //0 Payment Pending - 1 Payment Complete - 2 Order Processing - 3 Order Shipped - 4 order not processed
    };
    orders.put(Nat.toText(newOrdersId), newOrder);
    return true
  };

  public shared func deleteOrder(orderId : Nat) : async Bool {
    switch (orders.get(Nat.toText(orderId))) {
      case null { return false };
      case (?found) {
        orders.delete(Nat.toText(orderId));
        //TODO remove order products from this order
        return true
      }
    };
    return false
  };

  public shared query func getCartItemsNumber(customerId : Text) : async Nat {
    var total : Nat = 0;
    for (value in shoppingCart.vals()) { total := total + value.quantity };
    return total
  };

  public shared query func getOrder(customerId : Text) : async [Orders] {
    let OrderssBuffer : Buffer.Buffer<Orders> = Buffer.Buffer<Orders>(0);
    for (value in orders.vals()) {
      if (customerId == value.customerId) {
        let activeOrders : Orders = {
          id = value.id;
          customerId = value.customerId;
          total = value.total;
          symbol = value.symbol;
          paymentTx = value.paymentTx;
          status = value.status
        };
        OrderssBuffer.add(activeOrders)
      }
    };
    return Buffer.toArray(OrderssBuffer)
  };

  public shared query func getAllOrders() : async [Orders] {
    let OrdersBuffer : Buffer.Buffer<Orders> = Buffer.Buffer<Orders>(0);
    for (value in orders.vals()) {
      let activeOrders : Orders = {
        id = value.id;
        customerId = value.customerId;
        total = value.total;
        symbol = value.symbol;
        paymentTx = value.paymentTx;
        status = value.status
      };
      OrdersBuffer.add(activeOrders)
    };
    return Buffer.toArray(OrdersBuffer)
  };

  public shared func deleteCategory(categoryId : Nat) : async Bool {
    switch (categories.get(Nat.toText(categoryId))) {
      case null { return false };
      case (?found) {
        categories.delete(Nat.toText(categoryId));
        return true
      }
    };
    return false
  };

  public shared func deleteProduct(productId : Nat) : async Bool {
    switch (products.get(Nat.toText(productId))) {
      case null { return false };
      case (?found) {
        products.delete(Nat.toText(productId));
        return true
      }
    };
    return false
  };

  public shared func deleteCartProduct(productId : Nat, customerId : Text) : async Bool {
    for (value in shoppingCart.vals()) {
      if ((value.productId == productId) and (value.customerId == customerId)) {
        shoppingCart.delete(Nat.toText(productId));
        return true
      } else {
        return false
      }
    };
    return false
  };

  public shared func addQuantityCartProduct(productId : Nat, customerId : Text) : async Bool {
    for (value in shoppingCart.vals()) {
      if ((value.productId == productId) and (value.customerId == customerId)) {
        let newProduct : CartProducts = {
          id = value.productId;
          productId = productId;
          customerId = customerId;
          quantity = value.quantity + 1
        };
        shoppingCart.put(Nat.toText(value.productId), newProduct);
        return true
      }
    };
    return false
  };

  public shared func removeQuantityCartProduct(productId : Nat, customerId : Text) : async Bool {
    for (value in shoppingCart.vals()) {
      if ((value.productId == productId) and (value.customerId == customerId)) {
        if (value.quantity > 1) {
          let newProduct : CartProducts = {
            id = value.productId;
            productId = productId;
            customerId = customerId;
            quantity = value.quantity - 1
          };
          shoppingCart.put(Nat.toText(value.productId), newProduct);
          return true
        } else {
          shoppingCart.delete(Nat.toText(productId))
        }
      }
    };
    return false
  };

  public shared query func getAllShoppingCart() : async [CartProducts] {
    let CartProductsBuffer : Buffer.Buffer<CartProducts> = Buffer.Buffer<CartProducts>(0);
    for (value in shoppingCart.vals()) {
      let activeShoppingCartProducts : CartProducts = {
        id = value.id;
        productId = value.productId;
        customerId = value.customerId;
        quantity = value.quantity
      };
      CartProductsBuffer.add(activeShoppingCartProducts)
    };
    return Buffer.toArray(CartProductsBuffer)
  };

  public shared query func getShoppingCart(customerId : Text) : async [CartProductsShow] {
    let CartProductsBuffer : Buffer.Buffer<CartProductsShow> = Buffer.Buffer<CartProductsShow>(0);
    for (value in shoppingCart.vals()) {
      if (customerId == value.customerId) {
        switch (products.get(Nat.toText(value.productId))) {
          case null { return Buffer.toArray(CartProductsBuffer) };
          case (?found) {
            let activeShoppingCartProducts : CartProductsShow = {
              id = value.id;
              productId = value.productId;
              category = found.category;
              name = found.name;
              price = found.price;
              description = found.description;
              active = found.active;
              content = found.content;
              customerId = value.customerId;
              quantity = value.quantity
            };
            CartProductsBuffer.add(activeShoppingCartProducts)
          }
        }
      }
    };
    return Buffer.toArray(CartProductsBuffer)
  };

  public shared query func getCategories() : async [Category] {
    let CategoryBuffer : Buffer.Buffer<Category> = Buffer.Buffer<Category>(0);
    for (value in categories.vals()) {
      if (value.active == true) {
        let activeCategories : Category = {
          id = value.id;
          name = value.name;
          active = value.active
        };
        CategoryBuffer.add(activeCategories)
      }
    };
    Buffer.toArray(CategoryBuffer)
  };

  public shared query func getAllActiveProducts() : async [Product] {
    let ProductsBuffer : Buffer.Buffer<Product> = Buffer.Buffer<Product>(0);
    for (value in products.vals()) {
      if (value.active == true) {
        let activeProducts : Product = {
          id = value.id;
          category = value.category;
          name = value.name;
          price = value.price;
          quantity = value.quantity;
          description = value.description;
          active = value.active;
          content = value.content
        };
        ProductsBuffer.add(activeProducts)
      }
    };
    return Buffer.toArray(ProductsBuffer)
  };

  public shared func addToCart(productId : Nat, customerId : Text) : async Bool {
    var newid = shoppingCart.size();
    var newQuantity = 1;
    for (value in shoppingCart.vals()) {
      if ((value.productId == productId) and (value.customerId == customerId)) {
        newQuantity := value.quantity + 1;
        newid := value.id
      }
    };
    let newProduct : CartProducts = {
      id = newid;
      productId = productId;
      customerId = customerId;
      quantity = newQuantity
    };
    //Debug.print(debug_show (newProduct));
    shoppingCart.put(Nat.toText(newid), newProduct);
    return true
  };

  public shared func createCategory(category : CategoryCall) : async Bool {
    let newid = categories.size();
    let newCategory : Category = {
      id = newid;
      name = category.name;
      active = true
    };
    categories.put(Nat.toText(newid), newCategory);
    return true
  };

}

/*
  public shared (msg) func getActiveContest() : async Result.Result<Contest, Text> {
    for (value in categories.vals()) {
      //let now : Time = Time.now();
      //if (value.active == true) {
      if (value.active == true) {
        return #ok(value)
      }
      //}
    };
    return #err "no active contest"
  };

  private func restartVotes() {
    for (value in contestants.vals()) {
      switch (contestants.get(Nat.toText(value.id))) {
        case null {};
        case (?found) {
          let newContestant : Contestant = {
            id = value.id;
            votes = 0;
            description = found.description;
            content = found.content;
            votesWallet = found.votesWallet;
            completed = false;
            owner = found.owner;
            contest = found.contest
          };
          ignore contestants.replace(Nat.toText(value.id), newContestant)
        }
      }
    }
  };

  public shared (msg) func stopActiveContest(contestid : Nat) : async Bool {
    switch (categories.get(Nat.toText(contestid))) {
      case null { return false };
      case (?found) {
        let activating : Contest = {
          id = found.id;
          active = false;
          name = found.name;
          //winners = found.winners;
          //end = found.end;
          //completed = true
        };
        restartVotes();
        categories.put(Nat.toText(contestid), activating);
        return true
      }
    };
    return false
  };

  public shared (msg) func startActiveContest(contestid : Nat) : async Bool {
    switch (categories.get(Nat.toText(contestid))) {
      case null { return false };
      case (?found) {
        let activating : Contest = {
          id = found.id;
          active = true;
          name = found.name;
          //winners = found.winners;
          //end = found.end;
          //completed = false
        };
        categories.put(Nat.toText(contestid), activating);
        return true
      }
    };
    return false
  };

  public shared (msg) func getUpcomingContest() : async Result.Result<Contest, Text> {
    for (value in categories.vals()) {
      let now : Time = Time.now();
      if (value.active == false) {
        //if (value.completed == false) {
        //if (value.end > now) {
        return #ok(value)
        //}
        //}
      }
    };
    return #err "no upcoming contest"
  };

  public shared (msg) func getAllUnactiveContests() : async Result.Result<[Contest], Text> {
    let upcomingContests : Buffer.Buffer<Contest> = Buffer.Buffer<Contest>(0);
    for (value in categories.vals()) {
      let now : Time = Time.now();
      Debug.print(debug_show (now));
      //Debug.print(debug_show (value.end));
      if (value.active == false) {
        //if (value.completed == false) {
        //if ((value.end * 1_000_000) > now) {
        upcomingContests.add(value)
        //}
        //}
      }
    };
    return #ok(Buffer.toArray(upcomingContests))
  };

  public shared (msg) func history() : async [Contest] {
    let pastContests : Buffer.Buffer<Contest> = Buffer.Buffer<Contest>(0);
    for (value in categories.vals()) {
      //if (value.completed == true) {
      pastContests.add(value)
      //}
    };
    return Buffer.toArray(pastContests)
  };

  public shared (msg) func updateSocialProfile(profile : SocialProfile) : async Result.Result<SocialProfile, Text> {
    let account : Account = {
      owner = msg.caller;
      subaccount = null
    };
    switch (socialProfiles.get(account)) {
      case null {
        socialProfiles.put(account, profile);
        return #ok(profile)
      };
      case (?found) {
        socialProfiles.put(account, profile);
        return #ok(profile)
      }
    }
  };

  public shared (msg) func getSocialProfile() : async Result.Result<SocialProfile, Text> {
    let account : Account = {
      owner = msg.caller;
      subaccount = null
    };
    switch (socialProfiles.get(account)) {
      case null {
        return #err("no found")
      };
      case (?found) {
        return #ok(found)
      }
    }
  };

  private func compareVotes(m1 : ContestantResponse, m2 : ContestantResponse) : Order.Order {
    switch (Int.compare(m1.votes, m2.votes)) {
      case (#greater) return #less;
      case (#less) return #greater;
      case (_) return #equal
    }
  };

  public shared query func getAllContestantsByVotes() : async [ContestantResponse] {
    let ContestantBuffer : Buffer.Buffer<ContestantResponse> = Buffer.Buffer<ContestantResponse>(0);
    for (value in contestants.vals()) {
      let contestantToResponse : ContestantResponse = {
        id = value.id;
        votes = value.votes;
        description = value.description;
        votesWallet = value.votesWallet;
        completed = value.completed
      };
      ContestantBuffer.add(contestantToResponse)
    };
    ContestantBuffer.sort(compareVotes);
    return Buffer.toArray(ContestantBuffer)
  };

  public shared query func getWinner() : async ContestantResponse {
    let ContestantBuffer : Buffer.Buffer<ContestantResponse> = Buffer.Buffer<ContestantResponse>(0);
    for (value in contestants.vals()) {
      let contestantToResponse : ContestantResponse = {
        id = value.id;
        votes = value.votes;
        description = value.description;
        votesWallet = value.votesWallet;
        completed = value.completed
      };
      ContestantBuffer.add(contestantToResponse)
    };
    ContestantBuffer.sort(compareVotes);
    return Buffer.first(ContestantBuffer)
  };

  public shared (msg) func createCategory(category : CategoryCall) : async Bool {
    //let account : Account = {
    //  owner = msg.caller;
    //  subaccount = null
    //};
    let newid = categories.size();

    let CartProductsBuffer : Buffer.Buffer<CartProductsShow> = Buffer.Buffer<CartProductsShow>(0);
    for (value in shoppingCart.vals()) {
      if (customerId == value.customerId) {
        let found = await getProductCart(value.productId);
        Debug.print(debug_show (found));
        let activeShoppingCartProducts : CartProductsShow = {
          id = value.id;
          productId = value.productId;
          category = found[0].category;
          name = found[0].name;
          price = found[0].price;
          description = found[0].description;
          active = found[0].active;
          content = found[0].content;
          customerId = value.customerId;
          quantity = value.quantity
        };
        CartProductsBuffer.add(activeShoppingCartProducts)
      }

  public shared (msg) func addKisses() {
    let newAccount : Account.Account = {
      owner = msg.caller;
      subaccount = null
    };
    //_airDrop(newAccount)
  };

  public shared (msg) func addVote(contestantId : Nat) : async Result.Result<(), Text> {
    switch (contestants.get(Nat.toText(contestantId))) {
      case null { #err "" };
      case (?found) {
        let newContestant : Contestant = {
          id = contestantId;
          votes = found.votes + 1;
          description = found.description;
          content = found.content;
          votesWallet = msg.caller;
          completed = false;
          owner = msg.caller;
          contest = found.contest
        };
        ignore contestants.replace(Nat.toText(contestantId), newContestant);
        return #ok()
      }
    }
  };

  public shared (msg) func addNewContestant(contestant : ProposalCall) : async Result.Result<Nat, Text> {
    let defaultSub : Account.Subaccount = _defaultSub();
    let account : Account = {
      owner = msg.caller;
      subaccount = ?defaultSub
    };
    let newid = contestants.size();
    let newContestant : Contestant = {
      id = newid;
      votes = contestant.votes;
      description = contestant.description;
      content = contestant.content;
      votesWallet = msg.caller;
      completed = false;
      owner = msg.caller;
      contest = contestant.contest
    };
    switch (contestants.put(Nat.toText(newid), newContestant)) {
      case (added) {
        return #ok(newid)
      }
    };
    return #err("Couldn't add the contestant")
  };

  public shared query func getContent(contestantId : Nat) : async Content {
    switch (contestants.get(Nat.toText(contestantId))) {
      case null { return #Text("") };
      case (?contestantFound) { return contestantFound.content }
    }
  };

  public shared query func getContestant(contestantId : Nat) : async Result.Result<Contestant, Text> {
    switch (contestants.get(Nat.toText(contestantId))) {
      case null { return #err "not found" };
      case (?contestantFound) { return #ok(contestantFound) }
    }
  };

  public shared query func getAllContestants() : async [Product] {
    let ContestantBuffer : Buffer.Buffer<Product> = Buffer.Buffer<Product>(0);
    for (value in contestants.vals()) {
      let contestantToResponse : ContestantResponse = {
        id = value.id;
        votes = value.votes;
        description = value.description;
        votesWallet = value.votesWallet;
        completed = value.completed
      };
      ContestantBuffer.add(contestantToResponse)
    };
    return Buffer.toArray(ContestantBuffer)
  };
  */

/*
  private func getBalance(account : Account.Account) : Nat {
    switch (ledger.get(account)) {
      case null { return 0 };
      case (?kisses) { return kisses }
    }
  };
*/
/*
  public shared query (msg) func getKisses() : async Nat {
    let account : Account = {
      owner = msg.caller;
      subaccount = null
    };
    switch (ledger.get(account)) {
      case null { return 0 };
      case (?kisses) { return kisses }
    }
  };
  */
/*
  public shared func getCkBTCBalance(principal : Principal) : async Text {
    let icrc_canister = actor ("r7inp-6aaaa-aaaaa-aaabq-cai") : ICRCTypes.TokenInterface;
    let token_symbol = await icrc_canister.icrc1_symbol();
    return token_symbol
  };
  */

//let icrc_canister = actor ("r7inp-6aaaa-aaaaa-aaabq-cai") : ICRCTypes.TokenInterface;
//let token_symbol = await icrc_canister.icrc1_symbol();
//import ckBTC "canister:mxzaz-hqaaa-aaaar-qaada-cai";
//import ckETH "canister:ss2fx-dyaaa-aaaar-qacoq-cai";

/*
  public shared (msg) func makeAdmin(password : Text, principal : Text) : async Text {
    let setPassword : Text = "fhdsauf023a0sdf891-3457hfsad";
    let toMakeAdmin = Text.equal(password, setPassword);
    if (toMakeAdmin == true) {
      let account : Account = {
        owner = Principal.fromText(principal);
        subaccount = null
      };
      switch (profiles.get(account)) {
        case null {
          return "no found"
        };
        case (?found) {
          let newProfile : Profile = {
            name = found.name;
            profilePic = found.profilePic;
            admin = true
          };
          profiles.put(account, newProfile);
          return "found"
        }
      }
    };
    return "breaking switch"
  };
  */

/*
  public shared query func getProposalProfilePic(contestantId : Nat) : async ?ProposalProfile {
    switch (contestants.get(Nat.toText(contestantId))) {
      case null { return null };

      case (?found) {
        let account : Account = {
          owner = found.owner;
          subaccount = null
        };

        switch (profiles.get(account)) {
          case null { return null };
          case (?foundOwner) {
            let profile : ProposalProfile = {
              name = foundOwner.name;
              profilePic = foundOwner.profilePic
            };
            return ?profile
          }
        }
      }
    }
  };
  */

/*
  public type ProposalProfile = {
    profilePic : ?Blob;
    name : Text
  };

  public type Proof = {
    description : Text;
    content : Content
  };


  public type ProofMap = TrieMap.TrieMap<Text, Proof>;

  public type Contestant = {
    id : Nat;
    votes : Nat;
    description : Text;
    content : Content;
    votesWallet : Principal;
    completed : Bool;
    owner : Principal;
    contest : Nat
  };


  public type ContestantResponse = {
    id : Nat;
    votes : Nat;
    description : Text;
    votesWallet : Principal;
    completed : Bool
  };

  public type ProposalCall = {
    votes : Nat;
    description : Text;
    content : Content;
    contest : Nat
  };
  */

//import AccountTransfer "./ic";
//import Prelude "mo:base/Prelude";
//import NNS "./nns";
//import ManagementCanister "./ica";
//import Order "mo:base/Order";
//import Debug "mo:base/Debug";
//import ICRCTypes "mo:icrc1/ICRC1/Types";

/*
  public shared query (msg) func caller() : async Text {
    return Principal.toText(msg.caller)
  };
  */
/*

  public shared query (msg) func session() : async Profile {
    let defaultSub : Account.Subaccount = _defaultSub();
    let account : Account = {
      owner = msg.caller;
      subaccount = ?defaultSub
    };
    switch (profiles.get(account)) {
      case null { return guestProfile };
      case (?found) { return found }
    }
  };

  private func _defaultSub() : Subaccount {
    return Blob.fromArrayMut(Array.init(32, 0 : Nat8))
  };
  */
