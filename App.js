import React from 'react';
import { StatusBar } from 'expo-status-bar';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { ThemeProvider } from './src/theme/ThemeContext';
import { AppStateProvider } from './src/lib/AppState';
import Navigation from './src/Navigation';

export default function App() {
  return (
    <SafeAreaProvider>
      <ThemeProvider>
        <AppStateProvider>
          <StatusBar style="light" />
          <Navigation />
        </AppStateProvider>
      </ThemeProvider>
    </SafeAreaProvider>
  );
}
