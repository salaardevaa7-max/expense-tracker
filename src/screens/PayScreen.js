import React, { useState } from 'react';
import { View, Text, TextInput, TouchableOpacity, StyleSheet, Alert } from 'react-native';
import { useTheme } from '../theme/ThemeContext';
import { useAppState } from '../lib/AppState';
import { fmt } from '../lib/format';
import { openUpiPay } from '../lib/upi';

export default function PayScreen({ route, navigation }) {
  const { colors } = useTheme();
  const { people, settlePerson } = useAppState();
  const person = people.find((p) => p.id === route.params.personId);
  const [vpa, setVpa] = useState(person?.vpa || '');

  if (!person) return null;
  const amount = -person.balance;

  const pay = async () => {
    const result = await openUpiPay({
      payeeVpa: vpa,
      payeeName: person.name,
      amount,
      note: `Hisaab settle: ${person.name}`,
    });
    if (!result.ok) {
      Alert.alert(
        'No UPI ID',
        vpa ? 'No UPI app could handle this on your device.' : 'Add a UPI ID for this person first, or mark it settled manually below.'
      );
      return;
    }
    // We can't know for certain the payment succeeded — ask the user.
    Alert.alert('Did the payment go through?', 'Confirm once the UPI app shows it succeeded.', [
      { text: 'Not yet', style: 'cancel' },
      {
        text: 'Yes, mark settled',
        onPress: () => {
          settlePerson(person.id, 'UPI');
          navigation.goBack();
        },
      },
    ]);
  };

  const markManual = () => {
    settlePerson(person.id, null);
    navigation.goBack();
  };

  return (
    <View style={{ flex: 1, backgroundColor: colors.inkDeep, padding: 20, paddingTop: 60 }}>
      <Text style={[styles.h1, { color: colors.txt }]}>Pay {person.name}</Text>
      <Text style={{ color: colors.txt3, marginBottom: 20 }}>You owe</Text>
      <Text style={{ color: colors.txt, fontSize: 40, fontWeight: '700', marginBottom: 24 }}>{fmt(amount)}</Text>

      <TextInput
        placeholder="Their UPI ID (name@bank)"
        placeholderTextColor={colors.txt3}
        value={vpa}
        onChangeText={setVpa}
        autoCapitalize="none"
        style={[styles.input, { color: colors.txt, borderColor: colors.hair }]}
      />

      <TouchableOpacity onPress={pay} style={[styles.btn, { backgroundColor: colors.blu }]}>
        <Text style={{ color: '#fff', fontWeight: '700', textAlign: 'center' }}>Pay via UPI app</Text>
      </TouchableOpacity>

      <TouchableOpacity onPress={markManual} style={[styles.btn, { backgroundColor: colors.g2, marginTop: 12 }]}>
        <Text style={{ color: colors.txt, fontWeight: '600', textAlign: 'center' }}>Mark settled manually</Text>
      </TouchableOpacity>

      <Text style={{ color: colors.txt3, fontSize: 12.5, marginTop: 20 }}>
        Android/iOS don't reliably report back whether a UPI payment succeeded, so Hisaab always asks you to
        confirm before marking it settled.
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  h1: { fontSize: 24, fontWeight: '700', marginBottom: 4 },
  input: { borderWidth: 0.5, borderRadius: 14, padding: 14, marginBottom: 16, fontSize: 16 },
  btn: { borderRadius: 16, padding: 16 },
});
