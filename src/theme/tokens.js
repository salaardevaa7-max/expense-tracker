// Ported from the "Vessel" design in the HTML prototype.
// Banknote hues used as category colours; glass/blur aesthetic
// approximated with expo-blur + semi-transparent panels.

export const dark = {
  ink: '#0B1A2B',
  inkDeep: '#06111D',

  lav: '#9A86D4',
  blu: '#2E8FD6',
  amb: '#F2A93B',
  lime: '#C2D63F',
  choc: '#B07845',
  stone: '#93A2B0',

  txt: '#EDF3F9',
  txt2: '#A7B8C8',
  txt3: '#7C90A4',

  g1: 'rgba(255,255,255,0.06)',
  g2: 'rgba(255,255,255,0.10)',
  g3: 'rgba(255,255,255,0.16)',
  hair: 'rgba(255,255,255,0.10)',

  danger: '#E2664F',
  good: '#5FC28A',
};

export const light = {
  ink: '#DCE4EC',
  inkDeep: '#C6D3DF',

  lav: '#7A66C4',
  blu: '#1E6FB6',
  amb: '#C7841B',
  lime: '#8AA22A',
  choc: '#8A5A32',
  stone: '#5A6E80',

  txt: '#0E1E2E',
  txt2: '#4A5D70',
  txt3: '#4C6072',

  g1: 'rgba(14,30,46,0.05)',
  g2: 'rgba(14,30,46,0.08)',
  g3: 'rgba(14,30,46,0.12)',
  hair: 'rgba(14,30,46,0.10)',

  danger: '#C74B36',
  good: '#2E8F5C',
};

export const radii = {
  vessel: 34,
  panel: 22,
  chip: 13,
  pill: 999,
};

export const categoryColor = (t, cat) => {
  const map = {
    Food: t.amb,
    Travel: t.blu,
    Split: t.lav,
    Cash: t.choc,
    Bills: t.lime,
    Shopping: t.lav,
    Other: t.stone,
  };
  return map[cat] || t.stone;
};
