// ===========================================================================
//  Live Real-Time Currency Exchange Service.
//
//  Fetches the latest conversion rates relative to INR using a free, public
//  API (exchangerate-api.com) so users get exact figures while traveling.
// ===========================================================================

import 'dart:convert';
import 'package:http/http.dart' as http;

class Currency {
  static Map<String, double> _rates = {
    'INR': 1.0,
    'USD': 0.012,
    'EUR': 0.011,
    'AED': 0.044,
    'THB': 0.43,
    'GBP': 0.0095,
  };

  static DateTime? _lastFetched;

  /// Fetches latest rates from the open exchange API.
  static Future<bool> updateRates() async {
    try {
      final res = await http.get(Uri.parse('https://api.exchangerate-api.com/v4/latest/INR'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final Map<String, dynamic> rawRates = data['rates'];
        _rates = rawRates.map((key, value) => MapEntry(key, (value as num).toDouble()));
        _lastFetched = DateTime.now();
        return true;
      }
    } catch (e) {
      print('Failed to update live rates: $e');
    }
    return false;
  }

  /// Converts an amount in [fromCurrency] to INR based on current live rates.
  static int convertToINR(double amount, String fromCurrency) {
    if (fromCurrency == 'INR') return amount.round();
    final rate = _rates[fromCurrency];
    if (rate == null || rate == 0) return amount.round(); // Fallback
    // Since rates are INR -> Foreign, Foreign -> INR is (amount / rate)
    return (amount / rate).round();
  }

  /// Format string nicely
  static String formatForeign(double amount, String currency) {
    return '$currency ${amount.toStringAsFixed(2)}';
  }

  static DateTime? get lastUpdated => _lastFetched;
}
