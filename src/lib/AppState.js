import React, { createContext, useContext, useEffect, useState, useCallback } from 'react';
import { Storage } from './storage';

const Ctx = createContext(null);

function uid() {
  return Date.now().toString(36) + Math.random().toString(36).slice(2, 7);
}

export function AppStateProvider({ children }) {
  const [loaded, setLoaded] = useState(false);
  const [expenses, setExpensesState] = useState([]); // {id, title, category, amount, note, date}
  const [people, setPeopleState] = useState([]); // {id, name, avatarInitial, balance} balance>0 = owed to you
  const [budget, setBudgetState] = useState({ monthly: 30000 });
  const [cash, setCashState] = useState(0);

  useEffect(() => {
    (async () => {
      const [e, p, b, c] = await Promise.all([
        Storage.getExpenses(),
        Storage.getPeople(),
        Storage.getBudget(),
        Storage.getCash(),
      ]);
      setExpensesState(e);
      setPeopleState(p);
      setBudgetState(b);
      setCashState(c);
      setLoaded(true);
    })();
  }, []);

  const addExpense = useCallback(async (entry) => {
    const row = { id: uid(), date: new Date().toISOString(), ...entry };
    setExpensesState((prev) => {
      const next = [row, ...prev];
      Storage.setExpenses(next);
      return next;
    });
    return row;
  }, []);

  const deleteExpense = useCallback(async (id) => {
    setExpensesState((prev) => {
      const next = prev.filter((r) => r.id !== id);
      Storage.setExpenses(next);
      return next;
    });
  }, []);

  const setBudget = useCallback(async (monthly) => {
    const next = { monthly };
    setBudgetState(next);
    await Storage.setBudget(next);
  }, []);

  const setCash = useCallback(async (value) => {
    setCashState(value);
    await Storage.setCash(value);
  }, []);

  const upsertPersonBalance = useCallback((name, delta, meta = {}) => {
    setPeopleState((prev) => {
      const idx = prev.findIndex((p) => p.name === name);
      let next;
      if (idx === -1) {
        next = [
          ...prev,
          {
            id: uid(),
            name,
            avatarInitial: name.charAt(0).toUpperCase(),
            balance: delta,
            vpa: meta.vpa || '',
            lastActivity: 'Split just now',
          },
        ];
      } else {
        next = prev.slice();
        next[idx] = {
          ...next[idx],
          balance: next[idx].balance + delta,
          lastActivity: 'Split just now',
        };
      }
      Storage.setPeople(next);
      return next;
    });
  }, []);

  const settlePerson = useCallback((id, method) => {
    setPeopleState((prev) => {
      const next = prev.map((p) =>
        p.id === id
          ? { ...p, balance: 0, lastActivity: (method ? `Settled via ${method}` : 'Marked settled') + ' · just now' }
          : p
      );
      Storage.setPeople(next);
      return next;
    });
  }, []);

  // Even split with paise-safe remainder distribution, ported from the
  // prototype's shareOut() logic.
  const commitSplit = useCallback(
    async (total, participantNames, yourName = 'You') => {
      const n = participantNames.length;
      if (!n || !total) return null;
      const base = Math.floor((total / n) * 100) / 100;
      const shares = Array(n).fill(base);
      let remainder = Math.round((total - base * n) * 100) / 100;
      let i = 0;
      while (remainder > 0.001 && i < n) {
        shares[i] = Math.round((shares[i] + 0.01) * 100) / 100;
        remainder = Math.round((remainder - 0.01) * 100) / 100;
        i++;
      }

      let mine = 0;
      const others = [];
      participantNames.forEach((name, idx) => {
        if (name === yourName) mine = shares[idx];
        else others.push({ name, amount: shares[idx] });
      });

      if (mine) {
        await addExpense({
          title: 'Your share of a split',
          category: 'Split',
          amount: mine,
          note: `${n} people · you paid ${total}`,
        });
      }
      others.forEach((o) => upsertPersonBalance(o.name, o.amount));

      return { mine, others, total };
    },
    [addExpense, upsertPersonBalance]
  );

  const spentThisMonth = expenses.reduce((sum, e) => sum + e.amount, 0);
  const spentToday = expenses
    .filter((e) => new Date(e.date).toDateString() === new Date().toDateString())
    .reduce((sum, e) => sum + e.amount, 0);
  const totalOwedToYou = people.reduce((s, p) => s + (p.balance > 0 ? p.balance : 0), 0);
  const totalYouOwe = people.reduce((s, p) => s + (p.balance < 0 ? -p.balance : 0), 0);

  const value = {
    loaded,
    expenses,
    addExpense,
    deleteExpense,
    people,
    upsertPersonBalance,
    settlePerson,
    commitSplit,
    budget,
    setBudget,
    cash,
    setCash,
    spentThisMonth,
    spentToday,
    totalOwedToYou,
    totalYouOwe,
  };

  return <Ctx.Provider value={value}>{children}</Ctx.Provider>;
}

export function useAppState() {
  const ctx = useContext(Ctx);
  if (!ctx) throw new Error('useAppState must be used inside AppStateProvider');
  return ctx;
}
