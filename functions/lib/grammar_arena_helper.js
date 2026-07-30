"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.calculateArenaPoints = exports.getEngineBonus = exports.validateArenaAnswer = exports.normalizeString = void 0;
const normalizeString = (val) => {
    if (typeof val !== 'string')
        return '';
    return val.trim().toLowerCase();
};
exports.normalizeString = normalizeString;
const validateArenaAnswer = (item, value) => {
    if (value === null || value === undefined)
        return false;
    const engine = (0, exports.normalizeString)(item.engine);
    const correctAnswer = item.answer;
    if (engine === 'mcq' || engine === 'fill' || engine === 'errorspotting') {
        const expected = (0, exports.normalizeString)(correctAnswer);
        const actual = (0, exports.normalizeString)(value);
        return expected === actual;
    }
    if (engine === 'order' || engine === 'transform') {
        let expectedList = [];
        if (Array.isArray(correctAnswer)) {
            expectedList = correctAnswer.map(exports.normalizeString);
        }
        else {
            expectedList = [(0, exports.normalizeString)(correctAnswer)];
        }
        let actualList = [];
        if (Array.isArray(value)) {
            actualList = value.map(exports.normalizeString);
        }
        else {
            actualList = [(0, exports.normalizeString)(value)];
        }
        if (expectedList.length !== actualList.length)
            return false;
        for (let i = 0; i < expectedList.length; i++) {
            if (expectedList[i] !== actualList[i])
                return false;
        }
        return true;
    }
    if (engine === 'matching') {
        if (typeof correctAnswer !== 'object' || correctAnswer === null)
            return false;
        const expectedMap = new Map();
        for (const [k, v] of Object.entries(correctAnswer)) {
            expectedMap.set(String(k), (0, exports.normalizeString)(v));
        }
        if (typeof value !== 'object' || value === null)
            return false;
        const actualMap = new Map();
        for (const [k, v] of Object.entries(value)) {
            actualMap.set(String(k), (0, exports.normalizeString)(v));
        }
        if (expectedMap.size !== actualMap.size)
            return false;
        for (const [k, expectedVal] of expectedMap.entries()) {
            if (actualMap.get(k) !== expectedVal)
                return false;
        }
        return true;
    }
    return (0, exports.normalizeString)(correctAnswer) === (0, exports.normalizeString)(value);
};
exports.validateArenaAnswer = validateArenaAnswer;
const getEngineBonus = (engineRaw) => {
    const engine = (0, exports.normalizeString)(engineRaw);
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
exports.getEngineBonus = getEngineBonus;
const calculateArenaPoints = (isCorrect, attempt, engine, elapsedMs, timeLimitMs) => {
    if (!isCorrect) {
        return attempt === 1 ? -10 : -20;
    }
    const base = attempt === 1 ? 100 : 60;
    const engineBonus = (0, exports.getEngineBonus)(engine);
    const remainingMs = Math.max(0, timeLimitMs - elapsedMs);
    const ratio = remainingMs / (timeLimitMs || 45000);
    let speedBonus = Math.round(60 * ratio);
    if (attempt === 2) {
        speedBonus = Math.round(speedBonus * 0.5);
    }
    return base + engineBonus + speedBonus;
};
exports.calculateArenaPoints = calculateArenaPoints;
