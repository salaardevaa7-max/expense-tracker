import React, { createContext, useContext, useState, useMemo } from 'react';
import { useColorScheme } from 'react-native';
import { dark, light, radii } from './tokens';

const ThemeCtx = createContext(null);

export function ThemeProvider({ children }) {
  const system = useColorScheme();
  const [mode, setMode] = useState(system || 'dark');

  const value = useMemo(() => {
    const t = mode === 'light' ? light : dark;
    return {
      mode,
      colors: t,
      radii,
      toggle: () => setMode((m) => (m === 'light' ? 'dark' : 'light')),
    };
  }, [mode]);

  return <ThemeCtx.Provider value={value}>{children}</ThemeCtx.Provider>;
}

export function useTheme() {
  const ctx = useContext(ThemeCtx);
  if (!ctx) throw new Error('useTheme must be used inside ThemeProvider');
  return ctx;
}
