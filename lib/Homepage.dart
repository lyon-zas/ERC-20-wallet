// ignore: file_names
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Client httpClient;

  late Web3Client ethClient;

  //Polygon address
  final String myAddress = "0x4818569AA9dE13d3cC1D702Cd10a95932799a674";

  //url from alchemy
  final String blockchainUrl = "https://polygon-mumbai.g.alchemy.com/v2/xhOSAQIFW6H_-NjxcSrpa1vJbwckXTUC";

  bool data = false;
  int myAmount = 0;
  int amt = 0;
  var addressTo = "";
  var dec = pow(10, 18);
  var mydata;
  var mybalance;
  late String transHash;
  var balance;
  var name;
  var symbol;

  @override
  void initState() {
    httpClient = Client();
    ethClient = Web3Client(blockchainUrl, httpClient);
    super.initState();
    getName();
    getSymbol();
    getBalance(myAddress);
  }

  Future<DeployedContract> getContract() async {
    String abiFile = await rootBundle.loadString("assets/token.json");
    String contractAddress = "0x50338cAF974F2ec1869020e83eF48E36aCE93caf";
    final contract = DeployedContract(
        ContractAbi.fromJson(abiFile, "FirstToken"),
        EthereumAddress.fromHex(contractAddress));

    return contract;
  }

  Future<List<dynamic>> query(String functionName, List<dynamic> args) async {
    //
    final contract = await getContract();
    final ethFunction = contract.function(functionName);

    // This line below doesn't work.
    final result = await ethClient.call(
        contract: contract, function: ethFunction, params: args);

    // print(result.toString());
    return result;
  }

  Future<void> getBalance(String targetAddress) async {
    EthereumAddress address = EthereumAddress.fromHex(targetAddress);
    // print('In getGreeting');
    List<dynamic> result = await query('balanceOf', [address]);

    print('In getGreeting');
    print(result[0]);

    mybalance = result[0];
    var div = BigInt.from(dec);
    balance = BigInt.from(mybalance / div);

    print("balance: $balance");
    // print("sis ${balance.toInt() / 18 }");
    data = true;
    setState(() {});
  }

  Future<void> getName() async {
    // print('In getGreeting');
    List<dynamic> result = await query('name', []);

    print(result[0]);

    name = result[0];
    data = true;
    print(name);
    setState(() {});
  }

  Future<void> getSymbol() async {
    List<dynamic> result = await query('symbol', []);

    print(result[0]);

    symbol = result[0];
    data = true;
    setState(() {});
  }

  Future<String> submit(String functionName, List<dynamic> args) async {
    DeployedContract contract = await getContract();
    final ethFunction = contract.function(functionName);
    snackBar(label: "Recording tranction");
    EthPrivateKey key = EthPrivateKey.fromHex(
        "52b**************************************************8");
    Transaction transaction = await Transaction.callContract(
        contract: contract,
        function: ethFunction,
        parameters: args,
        maxGas: 100000);
    print(transaction.nonce);
    final result = await ethClient.sendTransaction(key, transaction,
        fetchChainIdFromNetworkId: true, chainId: null);
    print(result);
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    snackBar(label: "verifying transaction");
    //set a 20 seconds delay to allow the transaction to be verified before trying to retrieve the balance
    Future.delayed(const Duration(seconds: 20), () {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      snackBar(label: "retriving balance");
      getBalance(myAddress);
      ScaffoldMessenger.of(context).clearSnackBars();
    });
    return result;
  }

  snackBar({String? label}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label!),
            const CircularProgressIndicator(
              color: Colors.white,
            )
          ],
        ),
        duration: const Duration(days: 1),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<String> reciveCoin() async {
    EthereumAddress addressTo =
        EthereumAddress.fromHex("0x4818569AA9dE13d3cC1D702Cd10a95932799a674");
    var bigAmount = BigInt.from(myAmount);
    var response = await submit('mint', [addressTo, bigAmount]);
    print('Recieved');
    transHash = response;
    setState(() {});
    return response;
  }

  Future<String> transferCoin() async {
    var amount = BigInt.from(amt *dec);
    EthereumAddress to = EthereumAddress.fromHex(addressTo);
    print("amo: $amount");
    var response = await submit('transfer', [to, amount]);
    print('Transfered');
    transHash = response;
    setState(() {});
    return response;
  }

  @override
  Widget build(BuildContext context) {
    FocusNode nodeOne = FocusNode();
    FocusNode nodeTwo = FocusNode();
    return Scaffold(
      body: Stack(children: [
        Positioned(
          left: 0.0,
          right: 0.0,
          child: Container(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 50.0),
                  child: data
                      ? Text(
                          ' $balance $symbol',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 25),
                        )
                      : const CircularProgressIndicator(),
                ),
                const SizedBox(
                  height: 40,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        CircleAvatar(
                          child: IconButton(
                              onPressed: () => showDialog<String>(
                                  context: context,
                                  builder: (BuildContext context) =>
                                      CupertinoAlertDialog(
                                        title: const Text("Send"),
                                        content: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Material(
                                              child: TextField(
                                                  onChanged: (text) {
                                                    addressTo = text;
                                                    print(addressTo);
                                                  },
                                                  focusNode: nodeOne,
                                                  decoration: const InputDecoration(
                                                      hintText: "Address",
                                                      prefixIcon: Icon(Icons
                                                          .account_balance_wallet_outlined),
                                                      border:
                                                          OutlineInputBorder())),
                                            ),
                                            Material(
                                              child: TextField(
                                                  onChanged: (value) {
                                                    amt = int.parse(value)
                                                        .round();
                                                    print('uuu');
                                                    print(amt);
                                                    setState(() {});
                                                  },
                                                  keyboardType:
                                                      TextInputType.number,
                                                  focusNode: nodeTwo,
                                                  decoration: const InputDecoration(
                                                      hintText: "Amount",
                                                      prefixIcon: Icon(Icons
                                                          .currency_bitcoin_outlined),
                                                      border:
                                                          OutlineInputBorder())),
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          CupertinoDialogAction(
                                              child: RaisedButton(
                                            child: const Text(
                                              "Send",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white),
                                            ),
                                            color: Colors.redAccent,
                                            hoverColor: Colors.white,
                                            elevation: 5,
                                            onPressed: () {
                                              transferCoin();
                                              Navigator.pop(context);
                                            },
                                          ))
                                        ],
                                      )),
                              icon: const Icon(Icons.arrow_upward_outlined)),
                        ),
                        const SizedBox(
                          height: 2,
                        ),
                        const Text("send")
                      ],
                    ),
                    Column(
                      children: [
                        CircleAvatar(
                          child: IconButton(
                              onPressed: () => showDialog<String>(
                                  context: context,
                                  builder: (BuildContext context) =>
                                      CupertinoAlertDialog(
                                        title: const Text("Recieve"),
                                        content: Material(
                                          child: TextField(
                                              onChanged: (value) {
                                                myAmount =
                                                    int.parse(value).round();
                                                print('uuu');
                                                print(myAmount);
                                              },
                                              focusNode: nodeOne,
                                              decoration: const InputDecoration(
                                                  hintText: "Amount",
                                                  border:
                                                      OutlineInputBorder())),
                                        ),
                                        actions: [
                                          CupertinoDialogAction(
                                              child: RaisedButton(
                                            child: const Text(
                                              "recieve",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white),
                                            ),
                                            color: Colors.green,
                                            hoverColor: Colors.white,
                                            elevation: 5,
                                            onPressed: () {
                                              reciveCoin();
                                              Navigator.pop(context);
                                            },
                                          ))
                                        ],
                                      )),
                              icon: const Icon(Icons.arrow_downward_outlined)),
                        ),
                        const SizedBox(
                          height: 2,
                        ),
                        const Text("recieve")
                      ],
                    )
                  ],
                )
              ],
            ),
            decoration: const BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(15),
                  bottomRight: Radius.circular(15)),
              boxShadow: [
                BoxShadow(
                  color: Color.fromARGB(255, 160, 152, 253),
                  blurRadius: 4,
                  offset: Offset(4, 8), // Shadow position
                ),
              ],
            ),
            height: 200,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 230.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Column(children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(
                    "$name",
                    style: const TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 17,
                    ),
                  ),
                  Text(
                    "$balance $symbol",
                    style: const TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 17,
                    ),
                  )
                ],
              ),
              const SizedBox(
                height: 5,
              ),
              const Divider(
                color: Colors.grey,
                thickness: 1,
                height: 1,
              ),
            ]),
          ),
        )
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: (() => getBalance(myAddress)),
        child: const Icon(Icons.refresh_outlined),
      ),
    );
  }
}
