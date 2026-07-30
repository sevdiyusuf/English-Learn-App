import { normalizePublicText, validatePublicText } from './ugc_moderation';

describe('public UGC normalization', () => {
  it('removes zero-width bypasses and folds repeated whitespace', () => {
    expect(normalizePublicText('  Mer\u200Bhaba   Dünya  ')).toBe('Merhaba Dünya');
  });

  it('accepts legitimate Turkish and English educational text', () => {
    expect(validatePublicText('çalışmak', 80)).toBe('çalışmak');
    expect(validatePublicText('present perfect', 80)).toBe('present perfect');
  });

  it('rejects control characters and prohibited whole-word content', () => {
    expect(() => validatePublicText('a\u0000b', 80)).toThrow('invalid-content');
    expect(() => validatePublicText('N\u200bUDE', 80)).toThrow('content-not-allowed');
  });
});
