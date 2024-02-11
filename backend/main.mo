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
    //let host : Text = "openapi.bitrue.com";
    //let url = "https://openapi.bitrue.com/api/v1/ticker/price?symbol=" # symbol;
    let host : Text = "api.coinbase.com";
    let url = "https://" # host # "/v2/prices/" # symbol # "/spot";

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
      max_response_bytes = ?Nat64.fromNat(2000);
      headers = request_headers;
      body = null;
      method = #get;
      transform = ?transform_context
    };
    Cycles.add(86_242_400);

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
    let ratePrice = await parseValue(rate, "amount");
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
