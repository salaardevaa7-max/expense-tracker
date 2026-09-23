import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import Tabs from './Tabs';
import AddExpenseScreen from './screens/AddExpenseScreen';
import NewSplitScreen from './screens/NewSplitScreen';
import PayScreen from './screens/PayScreen';
import { useTheme } from './theme/ThemeContext';

const Stack = createNativeStackNavigator();

export default function Navigation() {
  const { colors, mode } = useTheme();

  return (
    <NavigationContainer
      theme={{
        dark: mode === 'dark',
        colors: {
          primary: colors.blu,
          background: colors.inkDeep,
          card: colors.ink,
          text: colors.txt,
          border: colors.hair,
          notification: colors.amb,
        },
      }}
    >
      <Stack.Navigator screenOptions={{ headerShown: false }}>
        <Stack.Screen name="Root" component={Tabs} />
        <Stack.Screen name="AddExpense" component={AddExpenseScreen} options={{ presentation: 'modal' }} />
        <Stack.Screen name="NewSplit" component={NewSplitScreen} options={{ presentation: 'modal' }} />
        <Stack.Screen name="Pay" component={PayScreen} options={{ presentation: 'modal' }} />
      </Stack.Navigator>
    </NavigationContainer>
  );
}
