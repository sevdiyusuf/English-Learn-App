import {
    classifyDeliveryResponses,
    invitationDataPayload,
    isInvalidRegistrationError,
    registerNotificationToken,
    selectEligibleDevices,
    tokenDocumentId,
    unregisterNotificationToken,
    validateRegistrationInput,
} from './push_notifications';

describe('Sprint 9B push notification contracts', () => {
    test('registration and unregistration require verified authentication', async () => {
        await expect(registerNotificationToken(undefined, {
            token: 'token_1234567890123456',
            platform: 'android',
            locale: 'en',
        })).rejects.toThrow('authentication-required');
        await expect(unregisterNotificationToken(undefined, {
            token: 'token_1234567890123456',
        })).rejects.toThrow('authentication-required');
    });

    test('validates registration without accepting acting UID or extra fields', () => {
        expect(validateRegistrationInput({
            token: 'token_1234567890123456',
            platform: 'android',
            locale: 'tr',
        })).toEqual({
            token: 'token_1234567890123456',
            platform: 'android',
            locale: 'tr',
        });
        expect(() => validateRegistrationInput({
            token: 'token_1234567890123456',
            platform: 'android',
            locale: 'tr',
            uid: 'other-user',
        })).toThrow('invalid-registration');
    });

    test.each([
        {},
        { token: 'short', platform: 'android', locale: 'en' },
        { token: 'x'.repeat(4097), platform: 'android', locale: 'en' },
        { token: 'token_1234567890123456', platform: 'unknown', locale: 'en' },
        { token: 'token_1234567890123456', platform: 'ios', locale: 'de' },
    ])('rejects malformed registration %#', (input) => {
        expect(() => validateRegistrationInput(input)).toThrow('invalid-registration');
    });

    test('hashes tokens deterministically without exposing raw token as document ID', () => {
        const token = 'token_1234567890123456';
        expect(tokenDocumentId(token)).toHaveLength(64);
        expect(tokenDocumentId(token)).toBe(tokenDocumentId(token));
        expect(tokenDocumentId(token)).not.toContain(token);
    });

    test('creates the exact versioned allowlisted invitation payload', () => {
        expect(invitationDataPayload('invite_ABC-123')).toEqual({
            type: 'multiplayer_invitation',
            version: '1',
            invitationId: 'invite_ABC-123',
        });
        expect(() => invitationDataPayload('../room-secret')).toThrow('invalid-invitation');
    });

    test('recognizes only definitive invalid-token errors for cleanup', () => {
        expect(isInvalidRegistrationError('messaging/invalid-registration-token')).toBe(true);
        expect(isInvalidRegistrationError('messaging/registration-token-not-registered')).toBe(true);
        expect(isInvalidRegistrationError('messaging/internal-error')).toBe(false);
        expect(isInvalidRegistrationError(undefined)).toBe(false);
    });

    test('targets every recipient device except a token also owned by sender', () => {
        const selected = selectEligibleDevices([
            { id: 'recipient-a', token: 'recipient_token_123456', locale: 'en' },
            { id: 'shared-device', token: 'shared_device_token_123', locale: 'tr' },
            { id: 'recipient-b', token: 'recipient_token_654321', locale: 'tr' },
        ], new Set(['shared-device']));
        expect(selected.map((device) => device.id)).toEqual(['recipient-a', 'recipient-b']);
    });

    test('partial failures retain successes and clean only stale tokens', () => {
        expect(classifyDeliveryResponses([
            { success: true },
            { success: false, errorCode: 'messaging/registration-token-not-registered' },
            { success: false, errorCode: 'messaging/internal-error' },
            { success: true },
        ])).toEqual({ successCount: 2, invalidIndexes: [1] });
    });
});
