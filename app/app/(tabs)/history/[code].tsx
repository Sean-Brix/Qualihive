import { useLocalSearchParams } from 'expo-router';

import { BatchDetailScreen } from '@/features/history/presentation/BatchDetailScreen';

export default function BatchDetailRoute() {
  const { code } = useLocalSearchParams<{ code: string }>();
  return <BatchDetailScreen code={code} />;
}
