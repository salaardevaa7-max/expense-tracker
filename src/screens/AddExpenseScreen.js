import React, { useState } from 'react';
import { View, Text, TextInput, TouchableOpacity, StyleSheet, ScrollView } from 'react-native';
import * as Haptics from 'expo-haptics';
import { useTheme } from '../theme/ThemeContext';
import { useAppState } from '../lib/AppState';
import { categoryColor } from '../theme/tokens';

const CATEGORIES = ['Food', 'Travel', 'Bills', 'Shopping', 'Other'];

export default function AddExpenseScreen({ navigation }) {
  const { colors } = useTheme();
  const { addExpense } = useAppState();
  const [title, setTitle] = useState('');
  const [amount, setAmount] = useState('');
  const [category, setCategory] = useState('Food');
  const [note, setNote] = useState('');

  const save = async () => {
    const amt = parseFloat(amount);
    if (!title.trim() || !amt) return;
    await addExpense({ title: title.trim(), amount: amt, category, note: note.trim() });
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    navigation.goBack();
  };

  return (
    <ScrollView style={{ flex: 1, backgroundColor: colors.inkDeep }} contentContainerStyle={{ padding: 20, paddingTop: 60 }}>
      <Text style={[styles.h1, { color: colors.txt }]}>Add expense</Text>

      <TextInput
        placeholder="What was it for?"
        placeholderTextColor={colors.txt3}
        value={title}
        onChangeText={setTitle}
        style={[styles.input, { color: colors.txt, borderColor: colors.hair }]}
      />
      <TextInput
        placeholder="Amount"
        placeholderTextColor={colors.txt3}
        value={amount}
        onChangeText={setAmount}
        keyboardType="decimal-pad"
        style={[styles.input, { color: colors.txt, borderColor: colors.hair, fontSize: 28, fontWeight: '700' }]}
      />

      <View style={styles.chipRow}>
        {CATEGORIES.map((c) => (
          <TouchableOpacity key={c} onPress={() => setCategory(c)}>
            <View
              style={[
                styles.chip,
                {
                  borderColor: category === c ? categoryColor(colors, c) : colors.hair,
                  backgroundColor: category === c ? colors.g2 : 'transparent',
                },
              ]}
            >
              <Text style={{ color: colors.txt }}>{c}</Text>
            </View>
          </TouchableOpacity>
        ))}
      </View>

      <TextInput
        placeholder="Note (optional)"
        placeholderTextColor={colors.txt3}
        value={note}
        onChangeText={setNote}
        style={[styles.input, { color: colors.txt, borderColor: colors.hair }]}
      />

      <TouchableOpacity onPress={save} style={[styles.saveBtn, { backgroundColor: colors.blu }]}>
        <Text style={{ color: '#fff', fontWeight: '700', textAlign: 'center' }}>Save</Text>
      </TouchableOpacity>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  h1: { fontSize: 26, fontWeight: '700', marginBottom: 20 },
  input: { borderWidth: 0.5, borderRadius: 14, padding: 14, marginBottom: 14, fontSize: 16 },
  chipRow: { flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginBottom: 14 },
  chip: { borderWidth: 1, borderRadius: 999, paddingHorizontal: 14, paddingVertical: 8 },
  saveBtn: { borderRadius: 16, padding: 16, marginTop: 8 },
});
