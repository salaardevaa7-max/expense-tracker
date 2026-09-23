import React from 'react';
import { View, Text, ScrollView, TouchableOpacity, StyleSheet } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { useTheme } from '../theme/ThemeContext';
import { useAppState } from '../lib/AppState';
import { fmt } from '../lib/format';
import Glass from '../components/Glass';
import { categoryColor } from '../theme/tokens';

export default function HomeScreen({ navigation }) {
  const { colors } = useTheme();
  const { expenses, budget, spentThisMonth, spentToday, totalOwedToYou, totalYouOwe } = useAppState();

  const remaining = budget.monthly - spentThisMonth;
  const pct = Math.min(1, spentThisMonth / (budget.monthly || 1));

  return (
    <View style={{ flex: 1, backgroundColor: colors.inkDeep }}>
      <ScrollView contentContainerStyle={{ padding: 18, paddingTop: 60, paddingBottom: 120 }}>
        <View style={styles.topbar}>
          <Text style={[styles.monthLabel, { color: colors.txt }]}>September</Text>
          <TouchableOpacity onPress={() => navigation.navigate('SettingsTab')}>
            <View style={[styles.iconBtn, { backgroundColor: colors.g1, borderColor: colors.hair }]}>
              <Text style={{ color: colors.txt }}>⚙</Text>
            </View>
          </TouchableOpacity>
        </View>

        {/* the vessel */}
        <View style={[styles.vessel, { borderColor: colors.hair }]}>
          <LinearGradient
            colors={[colors.blu, colors.lav]}
            start={{ x: 0, y: 1 }}
            end={{ x: 1, y: 0 }}
            style={[styles.liquid, { height: `${Math.max(6, pct * 100)}%` }]}
          />
          <View style={styles.vesselContent}>
            <Text style={[styles.vesselLabel, { color: colors.txt2 }]}>Left to spend this month</Text>
            <Text style={[styles.vesselAmount, { color: colors.txt }]}>{fmt(remaining)}</Text>
            <Text style={[styles.vesselSub, { color: colors.txt3 }]}>
              {fmt(spentThisMonth)} spent of {fmt(budget.monthly)}
            </Text>
          </View>
        </View>

        <View style={styles.row}>
          <Glass style={{ flex: 1 }}>
            <Text style={[styles.miniLabel, { color: colors.txt3 }]}>Today</Text>
            <Text style={[styles.miniAmount, { color: colors.txt }]}>{fmt(spentToday)}</Text>
          </Glass>
          <View style={{ width: 12 }} />
          <Glass style={{ flex: 1 }}>
            <Text style={[styles.miniLabel, { color: colors.txt3 }]}>Owed to you</Text>
            <Text style={[styles.miniAmount, { color: colors.good }]}>{fmt(totalOwedToYou)}</Text>
          </Glass>
        </View>

        <View style={{ height: 14 }} />

        <TouchableOpacity onPress={() => navigation.navigate('AddExpense')}>
          <Glass radius={18}>
            <Text style={{ color: colors.txt, fontWeight: '600', textAlign: 'center' }}>+ Add an expense</Text>
          </Glass>
        </TouchableOpacity>

        <View style={{ height: 20 }} />
        <Text style={[styles.sectionTitle, { color: colors.txt2 }]}>Recent</Text>
        {expenses.length === 0 && (
          <Text style={{ color: colors.txt3, marginTop: 8 }}>Nothing logged yet — add your first expense.</Text>
        )}
        {expenses.slice(0, 12).map((e) => (
          <View key={e.id} style={styles.rowItem}>
            <View style={[styles.dot, { backgroundColor: categoryColor(colors, e.category) }]} />
            <View style={{ flex: 1 }}>
              <Text style={{ color: colors.txt, fontWeight: '600' }}>{e.title}</Text>
              {!!e.note && <Text style={{ color: colors.txt3, fontSize: 12.5 }}>{e.note}</Text>}
            </View>
            <Text style={{ color: colors.txt }}>{fmt(e.amount)}</Text>
          </View>
        ))}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  topbar: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 },
  monthLabel: { fontSize: 23, fontWeight: '700' },
  iconBtn: { width: 38, height: 38, borderRadius: 19, alignItems: 'center', justifyContent: 'center', borderWidth: 0.5 },
  vessel: { height: 220, borderRadius: 34, overflow: 'hidden', borderWidth: 0.5, backgroundColor: 'rgba(255,255,255,0.04)' },
  liquid: { position: 'absolute', bottom: 0, left: 0, right: 0 },
  vesselContent: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  vesselLabel: { fontSize: 13 },
  vesselAmount: { fontSize: 40, fontWeight: '700', marginTop: 4 },
  vesselSub: { fontSize: 12.5, marginTop: 4 },
  row: { flexDirection: 'row', marginTop: 14 },
  miniLabel: { fontSize: 12 },
  miniAmount: { fontSize: 20, fontWeight: '700', marginTop: 4 },
  sectionTitle: { fontSize: 13, fontWeight: '600', textTransform: 'uppercase', letterSpacing: 0.5 },
  rowItem: { flexDirection: 'row', alignItems: 'center', paddingVertical: 10, gap: 10 },
  dot: { width: 10, height: 10, borderRadius: 5 },
});
