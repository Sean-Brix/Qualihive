declare module '*.svg' {
  import type React from 'react';
  import type { SvgProps } from 'react-native-svg';
  const content: React.FC<SvgProps>;
  export default content;
}

declare module '*.sql' {
  const content: string;
  export default content;
}

declare module '*.png' {
  const value: number;
  export default value;
}
