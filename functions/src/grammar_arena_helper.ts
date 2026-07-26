export type WorksheetItem = {
    id: string;
    engine: string;
    question: string;
    answer: any;
    options?: string[];
};

export const normalizeString = (val: unknown): string => {
    if (typeof val !== 'string') return '';
    return val.trim().toLowerCase();
};

export const validateArenaAnswer = (item: WorksheetItem, value: any): boolean => {
    if (value === null || value === undefined) return false;

    const engine = normalizeString(item.engine);
    const correctAnswer = item.answer;

    if (engine === 'mcq' || engine === 'fill' || engine === 'errorspotting') {
        const expected = normalizeString(correctAnswer);
        const actual = normalizeString(value);
        return expected === actual;
    }

    if (engine === 'order' || engine === 'transform') {
        let expectedList: string[] = [];
        if (Array.isArray(correctAnswer)) {
            expectedList = correctAnswer.map(normalizeString);
        } else {
            expectedList = [normalizeString(correctAnswer)];
        }

        let actualList: string[] = [];
        if (Array.isArray(value)) {
            actualList = value.map(normalizeString);
        } else {
            actualList = [normalizeString(value)];
        }

        if (expectedList.length !== actualList.length) return false;
        for (let i = 0; i < expectedList.length; i++) {
            if (expectedList[i] !== actualList[i]) return false;
        }
        return true;
    }

    if (engine === 'matching') {
        if (typeof correctAnswer !== 'object' || correctAnswer === null) return false;
        const expectedMap = new Map<string, string>();
        for (const [k, v] of Object.entries(correctAnswer)) {
            expectedMap.set(String(k), normalizeString(v));
        }

        if (typeof value !== 'object' || value === null) return false;
        const actualMap = new Map<string, string>();
        for (const [k, v] of Object.entries(value)) {
            actualMap.set(String(k), normalizeString(v));
        }

        if (expectedMap.size !== actualMap.size) return false;
        for (const [k, expectedVal] of expectedMap.entries()) {
            if (actualMap.get(k) !== expectedVal) return false;
        }
        return true;
    }

    return normalizeString(correctAnswer) === normalizeString(value);
};

export const getEngineBonus = (engineRaw: string): number => {
    const engine = normalizeString(engineRaw);
    switch (engine) {
        case 'mcq': return 0;
        case 'fill': return 10;
        case 'order': return 15;
        case 'transform': return 20;
        case 'errorspotting': return 25;
        case 'matching': return 10;
        default: return 0;
    }
};

export const calculateArenaPoints = (
    isCorrect: boolean,
    attempt: number,
    engine: string,
    elapsedMs: number,
    timeLimitMs: number,
): number => {
    if (!isCorrect) {
        return attempt === 1 ? -10 : -20;
    }

    const base = attempt === 1 ? 100 : 60;
    const engineBonus = getEngineBonus(engine);
    const remainingMs = Math.max(0, timeLimitMs - elapsedMs);
    const ratio = remainingMs / (timeLimitMs || 45000);
    let speedBonus = Math.round(60 * ratio);
    if (attempt === 2) {
        speedBonus = Math.round(speedBonus * 0.5);
    }

    return base + engineBonus + speedBonus;
};
