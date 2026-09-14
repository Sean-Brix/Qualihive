import { Stack } from 'expo-router';

/**
 * Everything the More tab leads to is a child of this stack, so a back
 * gesture from Settings lands on More rather than on Home.
 */
export default function MoreLayout() {
  return <Stack screenOptions={{ headerShown: false }} />;
}
