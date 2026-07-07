import 'dart:async'; // مكتبة المؤقتات
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart'; 
import 'package:nfc_manager/nfc_manager.dart'; // مكتبة المستشعر الداخلي

void main() {
  runApp(const CashierApp());
}

class CashierApp extends StatelessWidget {
  const CashierApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'نظام الكاشير الذكي',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        fontFamily: 'Cairo', 
      ),
      home: const LoginScreen(),
    );
  }
}

// ---------------- الشاشة الأولى: تسجيل دخول الكاشير ----------------
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final String firebaseBaseUrl = "https://test1-fbf48-default-rtdb.firebaseio.com";
  final String apiKey = "AIzaSyDY26fV3J9sQd2Q3m9wIwPl3kMed4Y7gvo";

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoggingIn = false;

  Future<void> _login() async {
    final String username = _usernameController.text.trim();
    final String password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showErrorSnackBar("الرجاء إدخال اسم المستخدم وكلمة المرور");
      return;
    }

    setState(() => _isLoggingIn = true);
    final String url = "$firebaseBaseUrl/cashiers.json?auth=$apiKey";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200 && response.body != 'null') {
        final data = json.decode(response.body) as Map<String, dynamic>;
        String? foundCashierId;
        String? foundCashierName;

        for (var id in data.keys) {
          String dbUsername = (data[id]['username'] ?? data[id]['name'] ?? '').toString().trim(); 
          String dbPassword = (data[id]['password'] ?? '').toString().trim();

          if (dbUsername == username && dbPassword == password) {
            foundCashierId = id;
            foundCashierName = data[id]['name']?.toString();
            break;
          }
        }

        if (foundCashierId != null && foundCashierName != null) {
          if (!mounted) return; 
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CashierHomeScreen(
                cashierId: foundCashierId!,
                cashierName: foundCashierName!,
              ),
            ),
          );
        } else {
          _showErrorSnackBar("اسم المستخدم أو كلمة المرور غير صحيحة!");
        }
      } else {
        _showErrorSnackBar("فشل الاتصال بالسيرفر للتحقق من الحساب");
      }
    } catch (e) {
      _showErrorSnackBar("حدث خطأ أثناء تسجيل الدخول: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoggingIn = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 16)),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_person, size: 80, color: Colors.teal),
                  const SizedBox(height: 16),
                  const Text("تسجيل دخول الكاشير", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: "اسم المستخدم",
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "كلمة المرور",
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                      onPressed: _isLoggingIn ? null : _login,
                      child: _isLoggingIn
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("دخول للنظام", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


// ---------------- الشاشة الثانية: لوحة تحكم الكاشير الرئيسية (الهجينة) ----------------
class CashierHomeScreen extends StatefulWidget {
  final String cashierId;
  final String cashierName;

  const CashierHomeScreen({
    Key? key,
    required this.cashierId,
    required this.cashierName,
  }) : super(key: key);

  @override
  State<CashierHomeScreen> createState() => _CashierHomeScreenState();
}

class _CashierHomeScreenState extends State<CashierHomeScreen> {
  final String firebaseBaseUrl = "https://test1-fbf48-default-rtdb.firebaseio.com";
  final String apiKey = "AIzaSyDY26fV3J9sQd2Q3m9wIwPl3kMed4Y7gvo";

  final FlutterTts _flutterTts = FlutterTts();

  double cashierCurrentBalance = 0.0;
  double cashierAccumulatedBalance = 0.0;

  final TextEditingController _cardController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final FocusNode _cardFocusNode = FocusNode();
  final FocusNode _amountFocusNode = FocusNode();

  Map<String, dynamic>? _scannedUser;
  bool _isLoading = false;
  bool _isLookupMode = false; 
  bool _waitingForCardScan = false; 

  Timer? _countdownTimer; 
  
  // حالة المستشعر الداخلي للهاتف
  bool _isInternalNfcAvailable = false;

  @override
  void initState() {
    super.initState();
    _initTts();
    _fetchCashierData(); 
    _checkAndInitInternalNfc(); // فحص وتشغيل مستشعر الموبايل تلقائياً إن وجد
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _amountFocusNode.requestFocus(); 
    });
  }

  void _initTts() async {
    await _flutterTts.setLanguage("ar");
    await _flutterTts.setSpeechRate(0.5); 
  }

  // دالة فحص وتفعيل مستشعر الـ NFC الداخلي للموبايل
  Future<void> _checkAndInitInternalNfc() async {
    try {
      bool isAvailable = await NfcManager.instance.isAvailable();
      setState(() {
        _isInternalNfcAvailable = isAvailable;
      });

      if (_isInternalNfcAvailable) {
        _startListeningToInternalNfc(); // تفعيل وضع الاستماع اللمسي في الخلفية
      }
    } catch (e) {
      setState(() {
        _isInternalNfcAvailable = false;
      });
    }
  }

  // الاستماع المستمر للمستشعر الداخلي وحقن البيانات مباشرة في الدالة المشتركة
  void _startListeningToInternalNfc() {
    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        String? hexId;
        final nfcData = tag.data;
        
        // استخراج الرقم التعريفي للبطاقة الفريد (UID) بناءً على بروتوكول البطاقة الممسوحة
        final List<int>? identifier = 
            nfcData['nfca']?['identifier'] ?? 
            nfcData['mifareultralight']?['identifier'] ?? 
            nfcData['isodep']?['identifier'];

        if (identifier != null) {
          hexId = identifier.map((e) => e.toRadixString(16).padLeft(2, '0')).join('').toUpperCase();
        }

        if (hexId != null && hexId.isNotEmpty && mounted) {
          setState(() {
            _cardController.text = hexId!;
          });
          // إرسال المعرف المقروء داخلياً إلى دالة المعالجة فوراً
          await _onCardScanned(hexId);
        }
      },
      onError: (error) async {
        // في حال حدوث خطأ أو انتهاء الجلسة، نعيد تشغيل المستشعر ليبقى نشطاً بالخلفية
        if (mounted) _startListeningToInternalNfc();
      }
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel(); 
    if (_isInternalNfcAvailable) {
      NfcManager.instance.stopSession(); // إغلاق الجلسة بأمان لحفظ موارد الهاتف
    }
    _cardController.dispose();
    _amountController.dispose();
    _cardFocusNode.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  Future<void> _fetchCashierData() async {
    final String url = "$firebaseBaseUrl/cashiers/${widget.cashierId}.json?auth=$apiKey";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200 && response.body != 'null') {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            cashierCurrentBalance = double.tryParse(data['current_balance']?.toString() ?? '0.0') ?? 0.0;
            cashierAccumulatedBalance = double.tryParse(data['accumulated_balance']?.toString() ?? '0.0') ?? 0.0;
          });
        }
      }
    } catch (e) {
      _showSnackBar("خطأ في جلب بيانات الكاشير: $e", Colors.red);
    }
  }

  void _startTimeout() {
    _countdownTimer?.cancel(); 
    _countdownTimer = Timer(const Duration(seconds: 15), () async {
      if (_waitingForCardScan && mounted) {
        setState(() {
          _waitingForCardScan = false;
          _cardController.clear();
        });
        _amountFocusNode.requestFocus();
        _showSnackBar("انتهت المهلة (15 ثانية)، تم إلغاء العملية تلقائياً", Colors.red);
        await _speak("تم إلغاء العملية لعدم تمرير البطاقة");
      }
    });
  }

  void _initiatePaymentWorkflow() async {
    final double? amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showSnackBar("الرجاء إدخال مبلغ صحيح أكبر من الصفر", Colors.orange);
      return;
    }

    String speechText = "سيتم خصم $amount نقطة، إذا كنت موافق يرجى تمرير البطاقة";
    await _speak(speechText);

    setState(() {
      _waitingForCardScan = true;
    });
    _cardFocusNode.requestFocus();
    _showSnackBar("النظام جاهز بانتظار قراءة الكارت الآن...", Colors.blue);
    
    _startTimeout(); 
  }

  // الدالة المركزية لاستلام رقم البطاقة (تستقبل من الحقل النصي الخارجي أو من المستشعر الداخلي بالخلفية)
  Future<void> _onCardScanned(String cardNum) async {
    if (cardNum.trim().isEmpty) return;

    if (_isLookupMode) {
      await _checkCardBalanceDirectly(cardNum);
      setState(() => _isLookupMode = false); 
      _cardController.clear();
      _amountFocusNode.requestFocus();
    } else {
      if (!_waitingForCardScan) {
        _showSnackBar("يرجى إدخال المبلغ وضغط زر إتمام العملية أولاً!", Colors.orange);
        _cardController.clear();
        _amountFocusNode.requestFocus();
        return;
      }
      _countdownTimer?.cancel(); // إيقاف التايمر فوراً لاستجابة البطاقة بنجاح
      await _processPaymentWithCard(cardNum);
    }
  }

  Future<void> _processPaymentWithCard(String cardNum) async {
    final double amount = double.parse(_amountController.text);
    setState(() => _isLoading = true);
    
    final String usersUrl = "$firebaseBaseUrl/users.json?auth=$apiKey";

    try {
      final response = await http.get(Uri.parse(usersUrl));
      if (response.statusCode == 200 && response.body != 'null') {
        final data = json.decode(response.body) as Map<String, dynamic>;
        Map<String, dynamic>? foundUser;

        for (var userId in data.keys) {
          if (data[userId]['card_num']?.toString().trim() == cardNum.trim()) {
            foundUser = {
              'id': userId,
              'name': data[userId]['name'],
              'current_balance': double.tryParse(data[userId]['current_balance']?.toString() ?? '0.0') ?? 0.0,
              'accumulated_balance': double.tryParse(data[userId]['accumulated_balance']?.toString() ?? '0.0') ?? 0.0,
            };
            break;
          }
        }

        if (foundUser == null) {
          _showSnackBar("البطاقة الممسوحة غير مسجلة بالنظام!", Colors.red);
          setState(() => _isLoading = false);
          _cardController.clear();
          _startTimeout(); // إعادة تشغيل التايمر للمحاولة مرة أخرى
          return;
        }

        double userCurrentBal = foundUser['current_balance'];
        if (userCurrentBal < amount) {
          _showSnackBar("رصيد المستخدم غير كافٍ! رصيده الحالي: $userCurrentBal", Colors.red);
          await _speak("عذراً، رصيدك الحالي غير كاف لإتمام العملية");
          setState(() => _isLoading = false);
          _cardController.clear();
          return;
        }

        double newUserCurrent = userCurrentBal - amount;
        double newCashierCurrent = cashierCurrentBalance + amount;
        double newCashierAccumulated = cashierAccumulatedBalance + amount;

        final String userPatchUrl = "$firebaseBaseUrl/users/${foundUser['id']}.json?auth=$apiKey";
        final String cashierPatchUrl = "$firebaseBaseUrl/cashiers/${widget.cashierId}.json?auth=$apiKey";
        final String logUrl = "$firebaseBaseUrl/balance_logs.json?auth=$apiKey";

        final userRes = await http.patch(Uri.parse(userPatchUrl), body: json.encode({'current_balance': newUserCurrent.toString()}));
        final cashierRes = await http.patch(Uri.parse(cashierPatchUrl), body: json.encode({
          'current_balance': newCashierCurrent.toString(),
          'accumulated_balance': newCashierAccumulated.toString(),
        }));

        await http.post(
          Uri.parse(logUrl),
          body: json.encode({
            'timestamp': DateTime.now().toString().substring(0, 19),
            'user_id': foundUser['id'],
            'user_name': foundUser['name'],
            'action_type': 'withdraw', 
            'amount': amount.toString(),
            'admin_id': widget.cashierId,
          }),
        );

        if (userRes.statusCode == 200 && cashierRes.statusCode == 200) {
          setState(() {
            _scannedUser = {
              'name': foundUser!['name'],
              'card_num': cardNum,
              'current_balance': newUserCurrent,
              'accumulated_balance': foundUser['accumulated_balance'],
            };
            _waitingForCardScan = false;
          });

          await _speak("لقد تم خصم $amount نقطة من رصيدك");

          _showSnackBar("تمت العملية بنجاح وصدر التوجيه الصوتي", Colors.green);
          _amountController.clear();
          _cardController.clear();
          await _fetchCashierData(); 
        } else {
          _showSnackBar("فشل تحديث البيانات في السحابة", Colors.red);
        }
      }
    } catch (e) {
      _showSnackBar("خطأ في معالجة العملية: $e", Colors.red);
    } finally { 
      if (mounted) {
        setState(() => _isLoading = false);
        _amountFocusNode.requestFocus();
      }
    }
  }

  Future<void> _checkCardBalanceDirectly(String cardNum) async {
    setState(() => _isLoading = true);
    final String url = "$firebaseBaseUrl/users.json?auth=$apiKey";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200 && response.body != 'null') {
        final data = json.decode(response.body) as Map<String, dynamic>;
        Map<String, dynamic>? foundUser;

        for (var userId in data.keys) {
          if (data[userId]['card_num']?.toString().trim() == cardNum.trim()) {
            foundUser = data[userId];
            break;
          }
        }

        if (foundUser != null) {
          double current = double.tryParse(foundUser['current_balance']?.toString() ?? '0.0') ?? 0.0;
          double accumulated = double.tryParse(foundUser['accumulated_balance']?.toString() ?? '0.0') ?? 0.0;

          _showBalanceDialog(
            foundUser['name'] ?? 'غير معروف',
            cardNum,
            current,
            accumulated,
          );
        } else {
          _showSnackBar("فشل الاستعلام: البطاقة غير مسجلة بالنظام!", Colors.orange);
        }
      }
    } catch (e) {
      _showSnackBar("خطأ أثناء الاستعلام: $e", Colors.red);
    } finally { 
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showBalanceDialog(String name, String cardNum, double current, double accumulated) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          icon: const Icon(Icons.account_balance_wallet, size: 48, color: Colors.teal),
          title: const Text("نتيجة استعلام رصيد الكارت", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(leading: const Icon(Icons.person), title: const Text("الاسم"), subtitle: Text(name)),
              ListTile(leading: const Icon(Icons.credit_card), title: const Text("رقم البطاقة"), subtitle: Text(cardNum)),
              ListTile(leading: const Icon(Icons.money), title: const Text("الرصيد المتاح حالياً"), subtitle: Text("$current د.إ", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18))),
              ListTile(leading: const Icon(Icons.history), title: const Text("إجمالي الشحن التراكمي"), subtitle: Text("$accumulated د.إ")),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("إغلاق", style: TextStyle(fontSize: 16)))
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 16)),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('نظام الكاشير الذكي (Hybrid RFID/NFC)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () {
            _countdownTimer?.cancel(); 
            Navigator.pushReplacement(
              context, 
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          },
          tooltip: 'تسجيل الخروج',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchCashierData,
            tooltip: 'تحديث البيانات الماليّة',
          )
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.teal))
            : SingleChildScrollView( 
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildCashierStatusCard(),
                    const SizedBox(height: 12),
                    _buildTransactionCard(),
                    const SizedBox(height: 12),
                    _buildCustomerDetailsCard(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildCashierStatusCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "الموظف الحالي: ${widget.cashierName}", 
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // مؤشر مرئي يوضح للكاشير حالة مستشعر الهاتف الداخلي
                Chip(
                  avatar: Icon(
                    _isInternalNfcAvailable ? Icons.check_circle : Icons.sensors_off,
                    color: _isInternalNfcAvailable ? Colors.green : Colors.grey,
                    size: 18,
                  ),
                  label: Text(
                    _isInternalNfcAvailable ? "المستشعر الداخلي نشط" : "القارئ الخارجي فقط",
                    style: TextStyle(fontSize: 11, color: _isInternalNfcAvailable ? Colors.green.shade900 : Colors.grey.shade800),
                  ),
                  backgroundColor: _isInternalNfcAvailable ? Colors.green.shade50 : Colors.grey.shade200,
                )
              ],
            ),
            const Divider(height: 20),
            Column( 
              children: [
                _buildBalanceTile("صندوق النقدية الحالي بالوردية", "$cashierCurrentBalance د.إ", Colors.blue.shade800),
                const SizedBox(height: 12),
                _buildBalanceTile("إجمالي مبيعات الموظف التراكمية", "$cashierAccumulatedBalance د.إ", Colors.orange.shade800),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text("العملية الماليّة الصوتيّة", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isLookupMode ? Colors.orange : Colors.grey.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: () {
                    _countdownTimer?.cancel(); 
                    setState(() {
                      _isLookupMode = !_isLookupMode;
                      _waitingForCardScan = false;
                    });
                    _cardFocusNode.requestFocus();
                    _showSnackBar(
                      _isLookupMode ? "وضع الاستعلام مفعل: امسح الكارت الآن لعرض الرصيد" : "تم إلغاء وضع الاستعلام",
                      _isLookupMode ? Colors.orange : Colors.black54
                    );
                  },
                  icon: const Icon(Icons.search, color: Colors.white, size: 18),
                  label: Text(
                    _isLookupMode ? "جاري الاستعلام..." : "استعلام عن رصيد كارت",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                )
              ],
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _amountController,
              enabled: !_isLookupMode, 
              focusNode: _amountFocusNode,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: "1. اكتب هنا إجمالي قيمة الفاتورة (نقاط)",
                prefixIcon: Icon(Icons.calculate),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _waitingForCardScan ? Colors.orange : Colors.teal
                ),
                onPressed: _isLookupMode ? null : _initiatePaymentWorkflow,
                icon: const Icon(Icons.volume_up, color: Colors.white),
                label: Text(
                  _waitingForCardScan ? "جاري انتظار تمرير البطاقة..." : "2. نطق القيمة وتفعيل القارئ", 
                  style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold)
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            TextField(
              controller: _cardController,
              focusNode: _cardFocusNode,
              decoration: InputDecoration(
                labelText: _isLookupMode 
                    ? "امسح الكارت الآن للاستعلام الفوري" 
                    : (_waitingForCardScan ? "🔴 امسح بطاقة المستخدم الآن (RFID/NFC)" : "يصبح نشطاً بعد تحديد المبلغ والضغط أعلاه"),
                prefixIcon: const Icon(Icons.credit_card),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _waitingForCardScan ? Colors.orange : Colors.teal, width: 2)),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: _onCardScanned, 
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerDetailsCard() {
    return Card(
      elevation: 4,
      color: _scannedUser == null ? Colors.grey.shade100 : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _scannedUser == null
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.record_voice_over, size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text("بانتظار تحديد المبلغ والضغط أعلاه للتمرير...", style: TextStyle(fontSize: 14, color: Colors.grey), textAlign: centerTxt),
                    ],
                  ),
                ),
              )
            : Column( 
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("آخر عملية خصم ناجحة للعميل", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
                  const Divider(height: 20),
                  _buildDetailRow("اسم العميل المعني:", _scannedUser!['name']),
                  _buildDetailRow("رقم البطاقة:", _scannedUser!['card_num']),
                  const Divider(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                    child: _buildDetailRow("الرصيد المتبقي بعد الخصم:", "${_scannedUser!['current_balance']} نقطة", isBold: true),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                    child: _buildDetailRow("إجمالي الشحن التراكمي:", "${_scannedUser!['accumulated_balance']} نقطة"),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _scannedUser = null;
                          _waitingForCardScan = false;
                        });
                        _amountFocusNode.requestFocus();
                      },
                      child: const Text("تصفية الشاشة لعملية جديدة"),
                    ),
                  )
                ],
              ),
      ),
    );
  }

  Widget _buildBalanceTile(String title, String value, Color color) {
    return Container(
      width: double.infinity, 
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, color: Colors.black54), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label, 
              style: const TextStyle(fontSize: 14, color: Colors.black54),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value, 
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 15, 
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal, 
                color: isBold ? Colors.green.shade900 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const TextAlign centerTxt = TextAlign.center;