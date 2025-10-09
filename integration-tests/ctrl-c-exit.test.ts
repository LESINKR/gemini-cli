/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */

import { describe, it, expect } from 'vitest';

import { TestRig } from './test-helper.js';
import stripAnsi from 'strip-ansi';

describe('Ctrl+C exit', () => {
  it('should exit gracefully on second Ctrl+C', async () => {
    const rig = new TestRig();
    await rig.setup('should exit gracefully on second Ctrl+C');

    const { ptyProcess } = rig.runInteractive();

    let output = '';
    ptyProcess.onData((data) => {
      output += data;
    });

    const isReady = await rig.waitForText('Love of my life', 10000);

    expect(
      isReady,
      `App did not become ready in time. ${stripAnsi(output)}`,
    ).toBe(true);
  });
});
