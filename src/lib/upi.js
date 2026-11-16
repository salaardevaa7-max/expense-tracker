import { Linking } from 'react-native';

// NPCI deprecated UPI Collect on 28 Feb 2026, so Intent is the only
// supported path now. Building a upi://pay deep link and letting the OS
// offer every installed UPI app is the standard approach.
//
// IMPORTANT (unlike the HTML prototype): the OS does NOT reliably tell us
// whether the payment actually succeeded — apps often return control to us
// even on cancel. Treat "opened the UPI app" as a NEUTRAL event, and always
// ask the user to confirm settlement themselves (either manually, or later
// by reading their bank SMS confirmation, which needs SMS permission and
// is Android-only — see README for how to add that when you're ready).
export function buildUpiUri({ payeeVpa, payeeName, amount, note }) {
  const params = new URLSearchParams({
    pa: payeeVpa,
    pn: payeeName,
    am: amount.toFixed(2),
    cu: 'INR',
  });
  if (note) params.set('tn', note);
  return `upi://pay?${params.toString()}`;
}

export async function openUpiPay({ payeeVpa, payeeName, amount, note }) {
  if (!payeeVpa) {
    return { ok: false, reason: 'no-vpa' };
  }
  const uri = buildUpiUri({ payeeVpa, payeeName, amount, note });
  const supported = await Linking.canOpenURL(uri);
  if (!supported) {
    return { ok: false, reason: 'no-upi-app' };
  }
  await Linking.openURL(uri);
  // We deliberately do NOT auto-mark as settled here. The screen that
  // called this should show a "did this go through?" confirmation step.
  return { ok: true };
}
