import AsyncStorage from '@react-native-async-storage/async-storage';

const KEYS = {
  EXPENSES: 'hisaab:expenses',
  PEOPLE: 'hisaab:people',
  BUDGET: 'hisaab:budget',
  CASH: 'hisaab:cash',
  GOALS: 'hisaab:goals',
};

async function get(key, fallback) {
  try {
    const raw = await AsyncStorage.getItem(key);
    return raw ? JSON.parse(raw) : fallback;
  } catch (e) {
    console.warn('storage.get failed', key, e);
    return fallback;
  }
}

async function set(key, value) {
  try {
    await AsyncStorage.setItem(key, JSON.stringify(value));
    return true;
  } catch (e) {
    console.warn('storage.set failed', key, e);
    return false;
  }
}

export const Storage = {
  KEYS,
  get,
  set,
  getExpenses: () => get(KEYS.EXPENSES, []),
  setExpenses: (v) => set(KEYS.EXPENSES, v),
  getPeople: () => get(KEYS.PEOPLE, []),
  setPeople: (v) => set(KEYS.PEOPLE, v),
  getBudget: () => get(KEYS.BUDGET, { monthly: 30000 }),
  setBudget: (v) => set(KEYS.BUDGET, v),
  getCash: () => get(KEYS.CASH, 0),
  setCash: (v) => set(KEYS.CASH, v),
  getGoals: () => get(KEYS.GOALS, []),
  setGoals: (v) => set(KEYS.GOALS, v),
};
