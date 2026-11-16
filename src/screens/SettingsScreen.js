import React, { useState } from 'react';
import { View, Text, TextInput, TouchableOpacity, StyleSheet, ScrollView, Switch } from 'react-native';
import { useTheme } from '../theme/ThemeContext';
import { useAppState } from '../lib/AppState';
import { fmt } from '../lib/format';

export default function SettingsScreen() {
  const { colors, mode, toggle } = useTheme();
  const { budget, setBudget, cash, setCash } = useAppState();
  const [budgetInput, setBudgetInput] = useState(String(budget.monthly));
  const [cashInput, setCashInput] = useState(String(cash));

  return (
    <ScrollView style={{ flex: 1, backgroundColor: colors.inkDeep }} contentContainerStyle={{ padding: 20, paddingTop: 60 }}>
      <Text style={[styles.h1, { color: colors.txt }]}>Settings</Text>

      <View style={styles.row}>
        <Text style={{ color: colors.txt }}>Dark mode</Text>
        <Switch value={mode === 'dark'} onValueChange={toggle} />
      </View>

      <Text style={[styles.label, { color: colors.txt2 }]}>Monthly budget</Text>
      <TextInput
        value={budgetInput}
        onChangeText={setBudgetInput}
        onEndEditing={() => setBudget(parseFloat(budgetInput) || 0)}
        keyboardType="decimal-pad"
        style={[styles.input, { color: colors.txt, borderColor: colors.hair }]}
      />

      <Text style={[styles.label, { color: colors.txt2 }]}>Cash in hand</Text>
      <Text style={{ color: colors.txt3, fontSize: 12.5, marginBottom: 8 }}>
        Count your wallet and enter what's actually there — the gap gets logged as cash spending no SMS
        could ever report.
      </Text>
      <TextInput
        value={cashInput}
        onChangeText={setCashInput}
        onEndEditing={() => setCash(parseFloat(cashInput) || 0)}
        keyboardType="decimal-pad"
        style={[styles.input, { color: colors.txt, borderColor: colors.hair }]}
      />
      <Text style={{ color: colors.txt3 }}>Currently tracked: {fmt(cash)}</Text>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  h1: { fontSize: 26, fontWeight: '700', marginBottom: 20 },
  row: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 },
  label: { fontSize: 13, fontWeight: '600', marginBottom: 6, textTransform: 'uppercase', letterSpacing: 0.5 },
  input: { borderWidth: 0.5, borderRadius: 14, padding: 14, marginBottom: 8, fontSize: 16 },
});
