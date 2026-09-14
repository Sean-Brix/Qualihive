import type { FC } from 'react';

/** Stands in for SVG imports under Jest, where the transformer is not loaded. */
const SvgMock: FC<Record<string, unknown>> = () => null;

export default SvgMock;
