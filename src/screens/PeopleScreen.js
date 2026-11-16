import React from 'react';
import { View, Text, ScrollView, TouchableOpacity, StyleSheet } from 'react-native';
import { useTheme } from '../theme/ThemeContext';
import { useAppState } from '../lib/AppState';
import { fmt } from '../lib/format';
import Glass from '../components/Glass';

export default function PeopleScreen({ navigation }) {
  const { colors } = useTheme();
  const { people } = useAppState();

  return (
    <View style={{ flex: 1, backgroundColor: colors.inkDeep }}>
      <ScrollView contentContainerStyle={{ padding: 18, paddingTop: 60, paddingBottom: 120 }}>
        <Text style={[styles.h1, { color: colors.txt }]}>People</Text>

        <TouchableOpacity onPress={() => navigation.navigate('NewSplit')}>
          <Glass radius={18} style={{ marginBottom: 16 }}>
            <Text style={{ color: colors.txt, fontWeight: '600', textAlign: 'center' }}>+ New split</Text>
          </Glass>
        </TouchableOpacity>

        {people.length === 0 && (
          <Text style={{ color: colors.txt3 }}>No splits yet. Start one above.</Text>
        )}

        {people.map((p) => (
          <TouchableOpacity
            key={p.id}
            onPress={() => p.balance < 0 && navigation.navigate('Pay', { personId: p.id })}
            disabled={p.balance >= 0}
          >
            <View style={styles.row}>
              <View style={[styles.av, { backgroundColor: colors.g2 }]}>
                <Text style={{ color: colors.txt, fontWeight: '700' }}>{p.avatarInitial}</Text>
              </View>
              <View style={{ flex: 1 }}>
                <Text style={{ color: colors.txt, fontWeight: '600' }}>{p.name}</Text>
                <Text style={{ color: colors.txt3, fontSize: 12.5 }}>{p.lastActivity}</Text>
              </View>
              <Text style={{ color: p.balance >= 0 ? colors.good : colors.danger, fontWeight: '700' }}>
                {p.balance >= 0 ? `owes you ${fmt(p.balance)}` : `you owe ${fmt(-p.balance)}`}
              </Text>
            </View>
          </TouchableOpacity>
        ))}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  h1: { fontSize: 26, fontWeight: '700', marginBottom: 16 },
  row: { flexDirection: 'row', alignItems: 'center', paddingVertical: 12, gap: 12 },
  av: { width: 42, height: 42, borderRadius: 21, alignItems: 'center', justifyContent: 'center' },
});
