// ===========================================================================
//  Reading money out of a bank text message.
//
//  Indian bank SMS has no standard. Every bank, every card network and every
//  UPI app words it differently, and the wording changes without notice. So
//  this parser is written to fail safely: if it is not confident, it returns
//  null and nothing is recorded. Everything it does find is put in front of
//  you to confirm rather than written straight into the ledger.
//
//  Pure Dart — no plugin, no permission, no I/O. It can be reasoned about
//  line by line, which matters, because this is the feature most likely to
//  meet a message format I have never seen.
// ===========================================================================

import 'models.dart';

/// One message as it came off the phone, stripped of any plugin types so
/// that nothing outside sms_source.dart has to know which package read it.
class RawSms {
  final String body;
  final String sender;
  final int? id;
  final int? at;

  const RawSms({required this.body, this.sender = '', this.id, this.at});
}

class SmsHit {
  final int amount; // whole rupees
  final String merchant;
  final String category;
  final String fingerprint;

  const SmsHit({
    required this.amount,
    required this.merchant,
    required this.category,
    required this.fingerprint,
  });
}

// Words that mean money left the account.
const _debitWords = [
  'debited', 'debit', 'spent', 'withdrawn', 'paid', 'sent',
  'purchase', 'txn of', 'transaction of', 'deducted',
];

// Words that mean the opposite, or that this is not a real transaction.
// Any of these and we stop, even if a debit word also appears — a message
// saying "not debited" or "reversal credited" must never book an expense.
//
// Note what is deliberately NOT here: "avl bal", "available balance" and the
// like. Almost every genuine debit SMS in India ends by telling you your
// remaining balance, so treating that as a stop word would reject nearly
// every message the feature exists to catch.
const _stopWords = [
  'credited', 'credit of', 'received', 'refund', 'reversed', 'reversal',
  'failed', 'declined', 'not debited', 'will be debited', 'reminder',
  'is due', 'due on', 'due by', 'payment due', 'overdue',
  'otp', 'one time password', 'collect request', 'payment request',
  'e-statement', 'cashback', 'offer', 'discount', 'congratulations',
];

/// Merchant and keyword hints, in the words people and payment gateways
/// actually use in India.
const _catWords = <String, List<String>>{
  Cat.food: [
    'swiggy', 'zomato', 'blinkit', 'zepto', 'instamart', 'bigbasket', 'dunzo',
    'dominos', 'pizza', 'kfc', 'mcdonald', 'starbucks', 'chaayos', 'cafe',
    'restaurant', 'hotel', 'canteen', 'mess', 'bakery', 'kirana', 'grocer',
    'grocery', 'supermarket', 'dmart', 'more retail', 'reliance fresh',
    'milk', 'dairy', 'tea', 'chai', 'juice', 'sweets', 'foods', 'food',
  ],
  Cat.travel: [
    'uber', 'ola', 'rapido', 'irctc', 'redbus', 'indigo', 'spicejet',
    'air india', 'vistara', 'makemytrip', 'goibibo', 'ixigo', 'yatra',
    'petrol', 'diesel', 'fuel', 'hpcl', 'bpcl', 'iocl', 'indian oil',
    'shell', 'metro', 'dmrc', 'bmtc', 'msrtc', 'toll', 'fastag', 'parking',
    'cab', 'taxi', 'auto', 'travel', 'railway',
  ],
  Cat.shopping: [
    'amazon', 'flipkart', 'myntra', 'ajio', 'meesho', 'nykaa', 'tatacliq',
    'snapdeal', 'croma', 'reliance digital', 'decathlon', 'lifestyle',
    'pantaloons', 'westside', 'shoppers stop', 'ikea', 'store', 'mart',
    'retail', 'shop',
  ],
  Cat.bills: [
    'electricity', 'bescom', 'mseb', 'tneb', 'adani electricity', 'tata power',
    'water board', 'gas', 'indane', 'hp gas', 'bharatgas', 'cylinder',
    'jio', 'airtel', 'vodafone', 'vi ', 'bsnl', 'recharge', 'broadband',
    'act fibernet', 'hathway', 'tikona', 'dth', 'tatasky', 'tata play',
    'insurance', 'lic', 'premium', 'emi', 'loan', 'policy', 'bill payment',
    'billdesk', 'bbps', 'school fee', 'college fee', 'tuition',
  ],
  Cat.rent: [
    'rent', 'nobroker', 'nestaway', 'maintenance', 'society', 'landlord',
    'housing', 'hostel', 'pg ',
  ],
  Cat.fun: [
    'netflix', 'spotify', 'hotstar', 'jiocinema', 'prime video', 'sonyliv',
    'zee5', 'youtube premium', 'bookmyshow', 'pvr', 'inox', 'cinepolis',
    'cinema', 'gym', 'cult.fit', 'cultfit', 'steam', 'playstation', 'xbox',
    'nintendo', 'dream11', 'bar', 'brewery', 'pub',
  ],
};

/// Best guess at a category from any free text — a merchant name, a UPI
/// handle, or a note the person typed themselves.
///
/// The earliest hint in the string wins, so "auto to the cinema" books
/// travel: the first thing named is usually the thing being paid for.
String guessCategory(String text, {String fallback = Cat.food}) {
  final t = ' ${text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim()} ';
  String? best;
  var bestAt = 1 << 30;
  _catWords.forEach((cat, words) {
    for (final w in words) {
      // The haystack has had its punctuation flattened to spaces, so the
      // needle must be flattened the same way or "cult.fit" could never match.
      final needle =
          w.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
      if (needle.isEmpty) continue;
      final at = t.indexOf(' $needle ');
      if (at > -1 && at < bestAt) {
        bestAt = at;
        best = cat;
      }
    }
  });
  return best ?? fallback;
}

// Rs 1,250.00 / INR 450 / ₹90.50 / Rs.240/-
final _amountRe = RegExp(
  r'(?:rs\.?|inr|₹|rupees)\s*([0-9][0-9,]*(?:\.[0-9]{1,2})?)',
  caseSensitive: false,
);

// The same number written the other way round: "1,250.00 INR"
final _amountReTrailing = RegExp(
  r'([0-9][0-9,]*(?:\.[0-9]{1,2})?)\s*(?:rs\.?|inr|rupees)',
  caseSensitive: false,
);

// Who it went to. Ordered widest-net-last, first match wins.
final _merchantRes = <RegExp>[
  RegExp(r'(?:to\s+vpa|to\s+upi\s*id|vpa)\s*[:\-]?\s*([a-z0-9._-]+@[a-z]+)', caseSensitive: false),
  RegExp(r'\b(?:at|to|towards|favou?ring)\s+([A-Za-z][A-Za-z0-9&.\s*_-]{2,40}?)(?=\s+(?:on|for|ref|upi|txn|dated|thru|via|a/c|info)\b|[.,;]|$)', caseSensitive: false),
  RegExp(r'\b(?:upi|info)[/:\- ]+[a-z0-9]*[/:\- ]*([A-Za-z][A-Za-z0-9&.\s_-]{2,30})', caseSensitive: false),
];

String _tidyMerchant(String raw) {
  var s = raw.trim();
  // A UPI handle: the part before @ is the readable bit.
  if (s.contains('@')) s = s.split('@').first;
  s = s.replaceAll(RegExp(r'[*_.\-]+'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  if (s.isEmpty) return '';
  // Drop trailing noise that regularly rides along.
  s = s.replaceAll(RegExp(r'\b(pvt|ltd|limited|india|in|payu|razorpay|paytm|billdesk)\b',
      caseSensitive: false), '').replaceAll(RegExp(r'\s+'), ' ').trim();
  if (s.isEmpty) return '';
  if (s.length > 28) s = s.substring(0, 28).trim();
  // Title case, because bank messages shout.
  return s
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join(' ');
}

/// Parses one message. Returns null when this is not a debit we understand,
/// which is the common case and must stay cheap and quiet.
SmsHit? parseSms({required String body, String sender = '', int? id, int? at}) {
  if (body.trim().isEmpty) return null;
  final low = body.toLowerCase();

  // A promotional message can contain "spent" and a rupee figure and mean
  // nothing at all, so the stop list is checked first and wins outright.
  for (final s in _stopWords) {
    if (low.contains(s)) return null;
  }
  final isDebit = _debitWords.any(low.contains);
  if (!isDebit) return null;

  var match = _amountRe.firstMatch(body);
  match ??= _amountReTrailing.firstMatch(body);
  if (match == null) return null;

  final raw = (match.group(1) ?? '').replaceAll(',', '');
  final value = double.tryParse(raw);
  if (value == null || value <= 0) return null;
  // Above a crore this is not somebody's chai money; it is a parse gone wrong.
  if (value >= 10000000) return null;
  final amount = value.round();
  if (amount <= 0) return null;

  var merchant = '';
  for (final re in _merchantRes) {
    final m = re.firstMatch(body);
    if (m != null) {
      merchant = _tidyMerchant(m.group(1) ?? '');
      if (merchant.isNotEmpty) break;
    }
  }

  // The sender id carries a hint too — SBIUPI, HDFCBK — and the merchant
  // name is the better signal, so it goes first.
  final category = guessCategory('$merchant $body', fallback: Cat.food);

  return SmsHit(
    amount: amount,
    merchant: merchant,
    category: category,
    fingerprint: fingerprintFor(body: body, sender: sender, id: id, at: at),
  );
}

/// A stable identity for a message, so re-scanning the inbox does not offer
/// the same debit twice.
///
/// Deliberately not String.hashCode: that is only guaranteed stable within a
/// single run of the program, so it would forget everything on restart and
/// duplicate every message.
String fingerprintFor({
  required String body,
  String sender = '',
  int? id,
  int? at,
}) {
  if (id != null) return 'id:$id';
  final squashed = body.toLowerCase().replaceAll(RegExp(r'\s+'), '');
  final head = squashed.length <= 60 ? squashed : squashed.substring(0, 60);
  return 'c:${sender.toLowerCase()}:${at ?? 0}:${squashed.length}:$head';
}
