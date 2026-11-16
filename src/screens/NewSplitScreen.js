import React, { useState } from 'react';
import { View, Text, TextInput, TouchableOpacity, StyleSheet, ScrollView } from 'react-native';
import { useTheme } from '../theme/ThemeContext';
import { useAppState } from '../lib/AppState';
import { fmt } from '../lib/format';

export default function NewSplitScreen({ navigation }) {
  const { colors } = useTheme();
  const { commitSplit } = useAppState();
  const [total, setTotal] = useState('');
  const [names, setNames] = useState('');

  const save = async () => {
    const amt = parseFloat(total);
    const participants = ['You', ...names.split(',').map((s) => s.trim()).filter(Boolean)];
    if (!amt || participants.length < 2) return;
    const result = await commitSplit(amt, participants);
    navigation.goBack();
  };

  return (
    <ScrollView style={{ flex: 1, backgroundColor: colors.inkDeep }} contentContainerStyle={{ padding: 20, paddingTop: 60 }}>
      <Text style={[styles.h1, { color: colors.txt }]}>New split</Text>

      <TextInput
        placeholder="Total bill amount"
        placeholderTextColor={colors.txt3}
        value={total}
        onChangeText={setTotal}
        keyboardType="decimal-pad"
        style={[styles.input, { color: colors.txt, borderColor: colors.hair, fontSize: 28, fontWeight: '700' }]}
      />
      <TextInput
        placeholder="Other people, comma separated (e.g. Rahul, Priya)"
        placeholderTextColor={colors.txt3}
        value={names}
        onChangeText={setNames}
        style={[styles.input, { color: colors.txt, borderColor: colors.hair }]}
      />

      <Text style={{ color: colors.txt3, marginBottom: 20 }}>
        Split evenly. You'll owe/be owed the difference — you'll be able to edit individual shares in a
        later version.
      </Text>

      <TouchableOpacity onPress={save} style={[styles.saveBtn, { backgroundColor: colors.lav }]}>
        <Text style={{ color: '#fff', fontWeight: '700', textAlign: 'center' }}>Split it</Text>
      </TouchableOpacity>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  h1: { fontSize: 26, fontWeight: '700', marginBottom: 20 },
  input: { borderWidth: 0.5, borderRadius: 14, padding: 14, marginBottom: 14, fontSize: 16 },
  saveBtn: { borderRadius: 16, padding: 16, marginTop: 8 },
});
