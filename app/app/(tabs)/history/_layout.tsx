import { Stack } from 'expo-router';

/** History keeps its own stack so a batch detail pushes over the list. */
export default function HistoryLayout() {
  return <Stack screenOptions={{ headerShown: false }} />;
}
