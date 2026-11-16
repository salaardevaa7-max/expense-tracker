import React from 'react';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { Ionicons } from '@expo/vector-icons';
import HomeScreen from './screens/HomeScreen';
import PeopleScreen from './screens/PeopleScreen';
import SettingsScreen from './screens/SettingsScreen';
import { useTheme } from './theme/ThemeContext';

const Tab = createBottomTabNavigator();

const ICONS = {
  HomeTab: 'home',
  PeopleTab: 'people',
  SettingsTab: 'settings',
};

export default function Tabs() {
  const { colors } = useTheme();

  return (
    <Tab.Navigator
      screenOptions={({ route }) => ({
        headerShown: false,
        tabBarActiveTintColor: colors.blu,
        tabBarInactiveTintColor: colors.txt3,
        tabBarStyle: { backgroundColor: colors.ink, borderTopColor: colors.hair },
        tabBarIcon: ({ color, size }) => <Ionicons name={ICONS[route.name]} size={size} color={color} />,
      })}
    >
      <Tab.Screen name="HomeTab" component={HomeScreen} options={{ title: 'Home' }} />
      <Tab.Screen name="PeopleTab" component={PeopleScreen} options={{ title: 'People' }} />
      <Tab.Screen name="SettingsTab" component={SettingsScreen} options={{ title: 'Settings' }} />
    </Tab.Navigator>
  );
}
