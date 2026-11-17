import { readFileSync } from 'node:fs';
import vm from 'node:vm';
import { describe, it, expect } from 'vitest';

function cloud(denied = false) {
  const writes: unknown[] = [];
  const result = { data: { id: 'report-1', status: 'new' }, error: denied ? { message: 'permission denied' } : null };
  const builder = { insert: (value: unknown) => { writes.push(value); return builder; }, update: (value: unknown) => { writes.push(value); return builder; }, select: () => builder, eq: () => builder, single: async () => result };
  const window: Record<string, any> = { __gsSupabase: { from: () => builder } };
  vm.runInNewContext(readFileSync('public/cloud.js', 'utf8'), { window });
  return { api: window['GSCloud'], writes };
}

describe('Feedback rules', () => {
  it('sends suggestions, bugs and other reports without accepting forged ownership or status', async () => {
    const { api, writes } = cloud();
    for (const category of ['suggestion', 'bug', 'other']) {
      await api.sendFeedback({ category, title: 'Relato', message: 'Detalhes', user_id: 'another-user', status: 'resolved' });
    }
    expect(writes).toEqual(['suggestion', 'bug', 'other'].map(category => ({ category, title: 'Relato', message: 'Detalhes' })));
  });
  it('administrator management changes only report status', async () => {
    const { api, writes } = cloud();
    await api.updateFeedback('report-1', 'reviewing');
    await api.updateFeedback('report-1', 'resolved');
    expect(writes).toEqual([{ status: 'reviewing' }, { status: 'resolved' }]);
  });
  it('does not claim success when the database denies report access', async () => {
    const { api } = cloud(true);
    await expect(api.updateFeedback('report-1', 'resolved')).rejects.toEqual({ message: 'permission denied' });
  });
});