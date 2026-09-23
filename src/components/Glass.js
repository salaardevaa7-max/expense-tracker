import React from 'react';
import { View, StyleSheet } from 'react-native';
import { BlurView } from 'expo-blur';
import { useTheme } from '../theme/ThemeContext';

export default function Glass({ children, style, radius, intensity = 40 }) {
  const { colors, radii, mode } = useTheme();
  const r = radius ?? radii.panel;

  return (
    <View style={[{ borderRadius: r, overflow: 'hidden' }, style]}>
      <BlurView intensity={intensity} tint={mode === 'light' ? 'light' : 'dark'} style={StyleSheet.absoluteFill} />
      <View
        style={[
          StyleSheet.absoluteFill,
          { backgroundColor: colors.g1, borderRadius: r, borderWidth: 0.5, borderColor: colors.hair },
        ]}
      />
      <View style={{ padding: 16 }}>{children}</View>
    </View>
  );
}
